import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _auth = AuthService();
  final _email = TextEditingController();
  bool _sending = false;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar acesso')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Informe seu e-mail. Vamos enviar um link para você redefinir a sua senha.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                if (_err != null) Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_err!, style: const TextStyle(color: Colors.red)),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.mail_outline),
                    label: Text(_sending ? 'Enviando...' : 'Enviar link'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty) { setState(() => _err = 'Informe seu e-mail.'); return; }
    setState(() { _sending = true; _err = null; });
    try {
      await _auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifique seu e-mail para redefinir a senha.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _err = 'Não foi possível enviar o e-mail: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
