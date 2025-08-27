import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService();
  final _db = FirebaseFirestore.instance;
  final _form = GlobalKey<FormState>();

  final _nome = TextEditingController();
  final _whatsapp = TextEditingController();
  final _cidadeUf = TextEditingController();
  final _pix = TextEditingController();
  final _emailNovo = TextEditingController();

  bool _loading = true;
  String? _error;
  DocumentReference<Map<String, dynamic>>? _userRef;
  Map<String, dynamic>? _data;
  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _load() async {
    final uid = _user!.uid;
    _userRef = _db.collection('users').doc(uid);
    final doc = await _userRef!.get();
    _data = doc.data();
    _nome.text = _data?['nome'] ?? '';
    _whatsapp.text = _data?['whatsapp'] ?? '';
    _cidadeUf.text = _data?['cidadeUf'] ?? '';
    _pix.text = _data?['pixChave'] ?? '';
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final emailVerificado = u?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () async { await _auth.signOut(); if (mounted) context.go('/login'); },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      Text('Conta', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Text('E-mail: ${u?.email ?? '-'}')),
                          const SizedBox(width: 8),
                          Icon(emailVerificado ? Icons.verified : Icons.error_outline,
                              color: emailVerificado ? Colors.green : Colors.orange),
                          const SizedBox(width: 16),
                          if (!emailVerificado)
                            TextButton(
                              onPressed: () async {
                                await u?.sendEmailVerification();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('E-mail de verificação enviado.')),
                                  );
                                }
                              },
                              child: const Text('Verificar e-mail'),
                            ),
                        ],
                      ),
                      const Divider(height: 28),

                      Text('Dados do Apostador', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome'), validator: (v) => Validators.notEmpty(v, label: 'Nome'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _whatsapp, decoration: const InputDecoration(labelText: 'WhatsApp'), validator: Validators.whatsapp)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _cidadeUf, decoration: const InputDecoration(labelText: 'Cidade/UF'), validator: Validators.cityUf)),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _pix, decoration: const InputDecoration(labelText: 'Chave Pix (prêmio)'), validator: Validators.pix)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (!_form.currentState!.validate()) return;
                              try {
                                await _userRef!.update({
                                  'nome': _nome.text.trim(),
                                  'whatsapp': _whatsapp.text.trim(),
                                  'cidadeUf': _cidadeUf.text.trim(),
                                  'pixChave': _pix.text.trim(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
                                }
                              } catch (e) {
                                setState(() => _error = 'Erro ao atualizar perfil');
                              }
                            },
                            child: const Text('Salvar alterações'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: _user!.email!);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link de redefinição enviado por e-mail.')));
                              }
                            },
                            child: const Text('Redefinir senha'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Alterar e-mail', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _emailNovo, decoration: const InputDecoration(labelText: 'Novo e-mail'), validator: Validators.email)),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (Validators.email(_emailNovo.text) != null) return;
                              try {
                                await _auth.updateEmail(_emailNovo.text);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verifique seu novo e-mail para confirmar a alteração.')));
                                }
                              } on FirebaseAuthException catch (e) {
                                setState(() => _error = e.message ?? 'Falha ao alterar e-mail');
                              }
                            },
                            child: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
