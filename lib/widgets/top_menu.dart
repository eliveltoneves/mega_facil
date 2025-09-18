import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class TopMenu extends StatelessWidget {
  final bool showProfile;
  const TopMenu({super.key, this.showProfile = true});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) async {
        switch (v) {
          case 'perfil':
            context.push('/perfil');
            break;
          case 'logout':
            await FirebaseAuth.instance.signOut();
            // força saída para login
            if (context.mounted) context.go('/login');
            break;
        }
      },
      itemBuilder: (ctx) => [
        if (showProfile)
          const PopupMenuItem(
            value: 'perfil',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.person_outline),
              title: Text('Perfil'),
            ),
          ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.logout),
            title: Text('Sair'),
          ),
        ),
      ],
    );
  }
}
