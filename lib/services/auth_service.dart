import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> reauthenticate(String email, String password) async {
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await _auth.currentUser!.reauthenticateWithCredential(cred);
  }

  Future<void> updateUserProfileFields({
    required String nome,
    required String whatsapp,
    required String cidadeUf,
    required String pixChave,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).set({
      'nome': nome.trim(),
      'whatsapp': whatsapp.trim(),
      'cidadeUf': cidadeUf.trim(),
      'pixChave': pixChave.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Troca o e-mail **enviando um link de confirmação** (API v6).
  /// - Reautentica com a senha atual;
  /// - Envia e-mail de verificação para o NOVO endereço;
  /// - O e-mail só será trocado após o usuário clicar no link.
  Future<void> updateEmailWithPassword({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser!;
    final oldEmail = user.email!;

    // Reautenticar primeiro
    await reauthenticate(oldEmail, currentPassword);
    // Envia o link para o novo e-mail (não altera imediatamente)
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  Future<void> changePasswordWithPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser!;
    final email = user.email!;
    await reauthenticate(email, currentPassword);
    await user.updatePassword(newPassword);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
