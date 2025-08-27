import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/mf_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MFLogo(height: 70),
                  const SizedBox(height: 16),
                  Text('Bem-vindo ao Mega Fácil', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('18+ | Aposte com responsabilidade.', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  if (_error != null) Text(_error!, style: TextStyle(color: cs.error)),
                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'E-mail'),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pass,
                          decoration: const InputDecoration(labelText: 'Senha'),
                          obscureText: true,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => context.push('/termos'),
                                child: const Text('Termos e Política'),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (Validators.email(_email.text) == null) {
                                  await _auth.sendPasswordReset(_email.text);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('E-mail de recuperação enviado.')),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Informe um e-mail válido para recuperar a senha.')),
                                    );
                                  }
                                }
                              },
                              child: const Text('Esqueci minha senha'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () async {
                              if (!_form.currentState!.validate()) return;
                              setState(() { _loading = true; _error = null; });
                              try {
                                await _auth.signIn(_email.text, _pass.text);
                              } on FirebaseAuthException catch (e) {
                                setState(() => _error = e.message ?? 'Falha ao entrar');
                              } finally {
                                if (mounted) setState(() => _loading = false);
                              }
                            },
                            child: Text(_loading ? 'Entrando...' : 'Entrar'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Não tem conta? Cadastre-se'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
