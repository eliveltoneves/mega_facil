import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import Papa from 'papaparse';

admin.initializeApp();
const db = admin.firestore();
const bucket = admin.storage().bucket();

// Forçar região SP (ajuste se preferir us-central1)
const fx = functions.region('southamerica-east1');

function cents(n: number) { return Math.round(n); }
function uniq<T>(a: T[]) { return Array.from(new Set(a)); }

// --- Enforce: janela, limite, números válidos e unicidade (hash25) por user/concurso
export const onBetCreateEnforceLimit = fx.firestore
  .document('contests/{contestId}/bets/{betId}')
  .onCreate(async (snap, ctx) => {
    const bet = snap.data() as any;
    const { contestId } = ctx.params;
    const uid = bet.userId as string;

    // valida concurso
    const contestRef = db.collection('contests').doc(contestId);
    const contestSnap = await contestRef.get();
    const contest = contestSnap.data() as any;
    if (!contest) { await snap.ref.delete(); return; }

    const fechamento = (contest.fechamento as admin.firestore.Timestamp).toDate();
    if (new Date() >= fechamento || contest.status !== 'open') {
      await snap.ref.delete(); return;
    }

    // limite 5 por user
    const q = await contestRef.collection('bets')
      .where('userId', '==', uid).get();
    if (q.size > 5) { await snap.ref.delete(); return; }

    // validação 25 números
    const nums: number[] = (bet.numeros || []).map((x: any) => Number(x));
    const valid = nums.length === 25
      && uniq(nums).length === 25
      && nums.every(n => n >= 1 && n <= 60);
    if (!valid) { await snap.ref.delete(); return; }

    // unicidade por user/concurso: hash25 = números ordenados e join(',')
    const sorted = [...nums].sort((a, b) => a - b);
    const hash25 = sorted.join(',');

    // se já existe outra aposta desse usuário com o mesmo hash25, apaga a nova
    const dupe = await contestRef.collection('bets')
      .where('userId', '==', uid)
      .where('hash25', '==', hash25)
      .limit(1)
      .get();
    if (!dupe.empty) { await snap.ref.delete(); return; }

    // grava o hash na aposta (caso o cliente não tenha enviado)
    if (!bet.hash25) {
      await snap.ref.set({ hash25 }, { merge: true });
    }
  });

// agrega quantidade paid/validated em contests/{id}.meta.totalBetsPaid
export const onBetWriteAggregate = fx.firestore
  .document('contests/{contestId}/bets/{betId}')
  .onWrite(async (_change, ctx) => {
    const { contestId } = ctx.params;
    const contestRef = db.collection('contests').doc(contestId);
    const paidSnap = await contestRef.collection('bets')
      .where('statusPagamento', 'in', ['paid', 'validated']).get();
    await contestRef.set({ meta: { totalBetsPaid: paidSnap.size } }, { merge: true });
  });

// callable de apuração (mantida como estava)
export const settleContest = fx.https.onCall(async (data, context) => {
  if (!(context.auth?.token?.admin === true)) {
    throw new functions.https.HttpsError('permission-denied', 'Somente admin.');
  }

  const contestId = String(data.contestId);
  const nums = [data.n1, data.n2, data.n3, data.n4, data.n5, data.n6]
    .map((x: any) => Number(x))
    .sort((a, b) => a - b);

  if (nums.some(n => !(n >= 1 && n <= 60))) {
    throw new functions.https.HttpsError('invalid-argument', 'Números inválidos.');
  }

  const contestRef = db.collection('contests').doc(contestId);
  const contestSnap = await contestRef.get();
  const contest = contestSnap.data() as any;
  if (!contest) throw new functions.https.HttpsError('not-found', 'Concurso não encontrado');
  if (contest.status !== 'closed') {
    throw new functions.https.HttpsError('failed-precondition', 'Feche o concurso antes de apurar.');
  }

  await contestRef.set({
    resultado: {
      n1: nums[0], n2: nums[1], n3: nums[2], n4: nums[3], n5: nums[4], n6: nums[5],
      data: admin.firestore.FieldValue.serverTimestamp()
    }
  }, { merge: true });

  const betCol = contestRef.collection('bets');
  const paid = await betCol.where('statusPagamento', 'in', ['paid', 'validated']).get();

  const preco = Number(contest.precoApostaCentavos ?? 2000);
  const arrec = paid.size * preco;

  // Mantém taxa 20% fora (80% para prêmios), depois reparte 70/5/5 como você definiu
  const pool80 = cents(arrec * 0.80);
  const rateios = { principal: 0.70, peFrio: 0.05, especial: 0.05, taxa: 0.20 };

  const principalPool = cents(pool80 * rateios.principal) + Number(contest.acumuladoPrincipalCentavos ?? 0);
  const peFrioPool    = cents(pool80 * rateios.peFrio);
  const especialPool  = cents(pool80 * rateios.especial) + Number(contest.acumuladoEspecialCentavos ?? 0);

  const winners6: FirebaseFirestore.QueryDocumentSnapshot[] = [];
  const winners0: FirebaseFirestore.QueryDocumentSnapshot[] = [];

  const resultNums = new Set(nums);
  const updates: Promise<any>[] = [];
  paid.forEach(doc => {
    const d = doc.data() as any;
    const arr: number[] = (d.numeros || []).map((x: any) => Number(x));
    const acertos = arr.filter(n => resultNums.has(n)).length;
    const faixa = (acertos === 6) ? 'principal' : (acertos === 0 ? 'peFrio' : 'nenhuma');
    if (acertos === 6) winners6.push(doc);
    if (acertos === 0) winners0.push(doc);
    updates.push(doc.ref.set({ acertos, faixa }, { merge: true }));
  });
  await Promise.all(updates);

  const n6 = winners6.length;
  const n0 = winners0.length;

  let carryPrincipalOut = 0;
  let payoutPrincipal = 0;
  if (n6 > 0) {
    payoutPrincipal = Math.floor(principalPool / n6);
  } else {
    carryPrincipalOut = principalPool;
  }
  const payoutPeFrio = (n0 > 0) ? Math.floor(peFrioPool / n0) : 0;

  const payUpdates: Promise<any>[] = [];
  winners6.forEach(w => payUpdates.push(w.ref.set({ premioCentavos: payoutPrincipal }, { merge: true })));
  winners0.forEach(w => payUpdates.push(w.ref.set({ premioCentavos: payoutPeFrio }, { merge: true })));
  await Promise.all(payUpdates);

  function moeda(cents: number) { return (cents / 100).toFixed(2).replace('.', ','); }

  const betsRows: any[] = [];
  paid.forEach(doc => {
    const b = doc.data() as any;
    betsRows.push({
      apostaId: doc.id,
      userId: b.userId,
      numeros: (b.numeros || []).join('-'),
      statusPagamento: b.statusPagamento,
      origem: b.origem,
      createdAt: b.createdAt?.toDate()?.toISOString() ?? '',
    });
  });
  const betsCsv = Papa.unparse(betsRows);

  const resultRows: any[] = [];
  const all = await betCol.get();
  all.forEach(doc => {
    const b = doc.data() as any;
    resultRows.push({
      apostaId: doc.id,
      userId: b.userId,
      acertos: b.acertos ?? '',
      faixa: b.faixa ?? '',
      premio: b.premioCentavos ? moeda(b.premioCentavos) : '',
    });
  });
  const resultCsv = Papa.unparse(resultRows);

  const betsFile = `exports/contests/${contestId}/apostas.csv`;
  const resultFile = `exports/contests/${contestId}/resultado.csv`;
  await bucket.file(betsFile).save(betsCsv, { contentType: 'text/csv' });
  await bucket.file(resultFile).save(resultCsv, { contentType: 'text/csv' });

  const betsUrl = (await bucket.file(betsFile).getSignedUrl({ action: 'read', expires: Date.now() + 1000 * 60 * 60 * 24 * 7 }))[0];
  const resultUrl = (await bucket.file(resultFile).getSignedUrl({ action: 'read', expires: Date.now() + 1000 * 60 * 60 * 24 * 7 }))[0];

  await contestRef.set({
    status: 'settled',
    payouts: {
      principalPool, peFrioPool, especialPool,
      payoutPrincipal, payoutPeFrio,
      winners6: n6, winners0: n0,
      numeros: nums,
    },
    exports: { betsCsv: betsUrl, resultCsv: resultUrl },
    carryOver: {
      principalOut: carryPrincipalOut,
      especialOut: especialPool,
    }
  }, { merge: true });

  return { ok: true, exports: { betsCsv: betsUrl, resultCsv: resultUrl } };
});

// --- ADMIN: tornar usuário admin (ad-hoc) ---
// Preencha seu UID abaixo (quem pode conceder admin)
const ALLOWED_GRANTERS = new Set<string>([
  // 'XGJbtD5FDeNUwzg4m2q4rgSXddO2',
]);

export const makeAdmin = fx.https.onCall(async (data, context) => {
  const requester = context.auth?.uid;
  if (!requester || !ALLOWED_GRANTERS.has(requester)) {
    throw new functions.https.HttpsError('permission-denied', 'Acesso negado.');
  }
  const uid = String(data?.uid ?? '');
  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'Informe uid.');
  }
  await admin.auth().setCustomUserClaims(uid, { admin: true });
  return { ok: true };
});
