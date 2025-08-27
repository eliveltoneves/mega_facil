import 'package:intl/intl.dart';

class Validators {
  static String? notEmpty(String? v, {String label = 'Campo'}) {
    if (v == null || v.trim().isEmpty) return '$label é obrigatório';
    return null;
  }

  static String? email(String? v) {
    if (notEmpty(v, label: 'E-mail') != null) return 'E-mail é obrigatório';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v!.trim());
    return ok ? null : 'E-mail inválido';
  }

  static String? cpf(String? v) {
    if (notEmpty(v, label: 'CPF') != null) return 'CPF é obrigatório';
    final digits = v!.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 ? null : 'CPF inválido';
  }

  static String? whatsapp(String? v) {
    if (notEmpty(v, label: 'WhatsApp') != null) return 'WhatsApp é obrigatório';
    final digits = v!.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? null : 'WhatsApp inválido';
  }

  static String? pix(String? v) {
    if (notEmpty(v, label: 'Chave Pix') != null) return 'Chave Pix é obrigatória';
    // Aceita e-mail, telefone, CPF/CNPJ ou EVP (básico)
    return null;
  }

  static String? cityUf(String? v) {
    if (notEmpty(v, label: 'Cidade/UF') != null) return 'Cidade/UF é obrigatório';
    return null;
  }

  static String? password(String? v) {
    if (notEmpty(v, label: 'Senha') != null) return 'Senha é obrigatória';
    return v!.length >= 6 ? null : 'Mínimo 6 caracteres';
  }

  static bool isAdult(DateTime birth) {
    final now = DateTime.now();
    final eighteen = DateTime(now.year - 18, now.month, now.day);
    return !birth.isAfter(eighteen);
  }

  static String formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
}
