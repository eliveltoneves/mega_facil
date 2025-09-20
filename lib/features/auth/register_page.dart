import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/mf_logo.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _auth = AuthService();
  final _db = FirebaseFirestore.instance;

  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _whatsapp = TextEditingController();
  final _cidadeUf = TextEditingController();
  final _pix = TextEditingController();
  DateTime? _nascimento;
  bool _aceite = false;
  bool _loading = false;
  String? _error;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDate: DateTime(now.year - 25),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _nascimento = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const MFLogo(height: 60),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!, style: TextStyle(color: cs.error)),
                    Form(
                      key: _form,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _email,
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail',
                                  ),
                                  validator: Validators.email,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _pass,
                                  decoration: const InputDecoration(
                                    labelText: 'Senha',
                                  ),
                                  obscureText: true,
                                  validator: Validators.password,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nome,
                            decoration: const InputDecoration(
                              labelText: 'Nome completo',
                            ),
                            validator: (v) =>
                                Validators.notEmpty(v, label: 'Nome completo'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickBirthDate,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Data de nascimento',
                                    ),
                                    child: Text(
                                      _nascimento == null
                                          ? 'Selecionar'
                                          : Validators.formatDate(_nascimento!),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cpf,
                                  decoration: const InputDecoration(
                                    labelText: 'CPF',
                                  ),
                                  validator: Validators.cpf,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _whatsapp,
                                  decoration: const InputDecoration(
                                    labelText: 'WhatsApp (DDD+Número)',
                                  ),
                                  validator: Validators.whatsapp,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cidadeUf,
                                  decoration: const InputDecoration(
                                    labelText: 'Cidade/UF',
                                  ),
                                  validator: Validators.cityUf,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pix,
                            decoration: const InputDecoration(
                              labelText: 'Chave Pix (pagamento de prêmio)',
                            ),
                            validator: Validators.pix,
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _aceite,
                            onChanged: (v) =>
                                setState(() => _aceite = v ?? false),
                            title: Row(
                              children: [
                                const Text('Li e aceito os '),
                                InkWell(
                                  onTap: () => context.push('/termos'),
                                  child: const Text(
                                    'Termos e Política',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      if (!_form.currentState!.validate()) {
                                        return;
                                      }
                                      if (_nascimento == null) {
                                        setState(
                                          () => _error =
                                              'Informe sua data de nascimento',
                                        );
                                        return;
                                      }
                                      if (!Validators.isAdult(_nascimento!)) {
                                        setState(
                                          () => _error =
                                              'Cadastro permitido apenas para maiores de 18 anos',
                                        );
                                        return;
                                      }
                                      if (!_aceite) {
                                        setState(
                                          () => _error =
                                              'É necessário aceitar os Termos e Política',
                                        );
                                        return;
                                      }
                                      setState(() {
                                        _loading = true;
                                        _error = null;
                                      });
                                      try {
                                        final cred = await _auth.register(
                                          _email.text,
                                          _pass.text,
                                        );
                                        final uid = cred.user!.uid;
                                        await _db
                                            .collection('users')
                                            .doc(uid)
                                            .set({
                                              'nome': _nome.text.trim(),
                                              'email': _email.text.trim(),
                                              'nascimento': _nascimento!
                                                  .toIso8601String(),
                                              'cpf': _cpf.text.trim(),
                                              'whatsapp': _whatsapp.text.trim(),
                                              'cidadeUf': _cidadeUf.text.trim(),
                                              'pixChave': _pix.text.trim(),
                                              'role': 'apostador',
                                              'emailVerificado': false,
                                              'telefoneVerificado': false,
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                            });
                                        if (!mounted) return;
                                        context.go('/perfil');
                                      } on FirebaseAuthException catch (e) {
                                        setState(
                                          () => _error =
                                              e.message ?? 'Falha no cadastro',
                                        );
                                      } finally {
                                        if (!mounted) return;
                                        setState(() => _loading = false);
                                      }
                                    },
                              child: Text(
                                _loading ? 'Cadastrando...' : 'Criar conta',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Já tenho conta'),
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
      ),
    );
  }
}
