import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos e Política')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            Text('18+ • Aposte com responsabilidade.\n\n'
                '1. O Mega Fácil utiliza resultado oficial da Mega-Sena de sábado.\n'
                '2. Cadastro permitido apenas para maiores de 18 anos.\n'
                '3. Dados pessoais tratados para fins de operação do concurso e pagamento de prêmios.\n'
                '4. Pagamentos de prêmios via chave Pix cadastrada no perfil.\n'
                '5. Leia a Política de Privacidade completa (em breve).'),
          ],
        ),
      ),
    );
  }
}
