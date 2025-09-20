import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authSvc = AuthService();
  final _db = FirebaseFirestore.instance;

  final _formDados = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _whats = TextEditingController();
  final _cidadeUf = TextEditingController();
  final _pix = TextEditingController();

  // e-mail e senha
  final _newEmail = TextEditingController();
  final _currentPwdForEmail = TextEditingController();

  // trocar senha
  final _currentPwd = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirmPwd = TextEditingController();

  bool _loadingDados = false;
  bool _loadingEmail = false;
  bool _loadingPwd = false;

  String? _msgDados;
  String? _msgEmail;
  String? _msgPwd;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    final d = doc.data() ?? {};
    _nome.text = (d['nome'] ?? '').toString();
    _whats.text = (d['whatsapp'] ?? '').toString();
    _cidadeUf.text = (d['cidadeUf'] ?? '').toString();
    _pix.text = (d['pixChave'] ?? '').toString();
    setState(() {});
  }

  @override
  void dispose() {
    _nome.dispose();
    _whats.dispose();
    _cidadeUf.dispose();
    _pix.dispose();
    _newEmail.dispose();
    _currentPwdForEmail.dispose();
    _currentPwd.dispose();
    _newPwd.dispose();
    _confirmPwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final emailAtual = user.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _secao(
                title: 'Dados pessoais',
                child: Form(
                  key: _formDados,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nome,
                        decoration: const InputDecoration(labelText: 'Nome completo'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _whats,
                        decoration: const InputDecoration(labelText: 'WhatsApp (DDD+Número)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cidadeUf,
                        decoration: const InputDecoration(labelText: 'Cidade/UF'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pix,
                        decoration: const InputDecoration(labelText: 'Chave Pix'),
                      ),
                      const SizedBox(height: 16),
                      if (_msgDados != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_msgDados!, style: const TextStyle(color: Colors.red)),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadingDados ? null : _salvarDados,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(_loadingDados ? 'Salvando...' : 'Salvar alterações'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _secao(
                title: 'Alterar e-mail',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('E-mail atual: $emailAtual'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Novo e-mail'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _currentPwdForEmail,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha atual (para confirmar)'),
                    ),
                    const SizedBox(height: 12),
                    if (_msgEmail != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_msgEmail!, style: const TextStyle(color: Colors.red)),
                      ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadingEmail ? null : _alterarEmail,
                          icon: const Icon(Icons.mark_email_read_outlined),
                          label: Text(_loadingEmail ? 'Alterando...' : 'Confirmar novo e-mail'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _secao(
                title: 'Alterar senha',
                child: Column(
                  children: [
                    TextField(
                      controller: _currentPwd,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha atual'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPwd,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Nova senha'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPwd,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
                    ),
                    const SizedBox(height: 12),
                    if (_msgPwd != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_msgPwd!, style: const TextStyle(color: Colors.red)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loadingPwd ? null : _trocarSenha,
                        icon: const Icon(Icons.lock_reset),
                        label: Text(_loadingPwd ? 'Atualizando...' : 'Atualizar senha'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secao({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _salvarDados() async {
    if (!_formDados.currentState!.validate()) return;
    setState(() { _loadingDados = true; _msgDados = null; });
    try {
      await _authSvc.updateUserProfileFields(
        nome: _nome.text,
        whatsapp: _whats.text,
        cidadeUf: _cidadeUf.text,
        pixChave: _pix.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso.')),
      );
    } catch (e) {
      setState(() => _msgDados = 'Falha ao salvar dados: $e');
    } finally {
      if (mounted) setState(() => _loadingDados = false);
    }
  }

  Future<void> _alterarEmail() async {
    final newEmail = _newEmail.text.trim();
    final pwd = _currentPwdForEmail.text;
    if (newEmail.isEmpty || pwd.isEmpty) {
      setState(() => _msgEmail = 'Informe novo e-mail e sua senha atual.');
      return;
    }
    setState(() { _loadingEmail = true; _msgEmail = null; });
    try {
      await _authSvc.updateEmailWithPassword(
        currentPassword: pwd,
        newEmail: newEmail,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail alterado com sucesso.')),
      );
      _newEmail.clear();
      _currentPwdForEmail.clear();
    } on FirebaseAuthException catch (e) {
      setState(() => _msgEmail = e.message ?? 'Não foi possível alterar o e-mail.');
    } catch (e) {
      setState(() => _msgEmail = 'Erro ao alterar e-mail: $e');
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _trocarSenha() async {
    final oldPwd = _currentPwd.text;
    final np = _newPwd.text;
    final cp = _confirmPwd.text;
    if (oldPwd.isEmpty || np.isEmpty || cp.isEmpty) {
      setState(() => _msgPwd = 'Preencha todos os campos de senha.');
      return;
    }
    if (np != cp) {
      setState(() => _msgPwd = 'A confirmação da nova senha não confere.');
      return;
    }
    if (np.length < 6) {
      setState(() => _msgPwd = 'A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }
    setState(() { _loadingPwd = true; _msgPwd = null; });
    try {
      await _authSvc.changePasswordWithPassword(
        currentPassword: oldPwd,
        newPassword: np,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada com sucesso.')),
      );
      _currentPwd.clear();
      _newPwd.clear();
      _confirmPwd.clear();
    } on FirebaseAuthException catch (e) {
      setState(() => _msgPwd = e.message ?? 'Não foi possível atualizar a senha.');
    } catch (e) {
      setState(() => _msgPwd = 'Erro ao atualizar senha: $e');
    } finally {
      if (mounted) setState(() => _loadingPwd = false);
    }
  }
}
