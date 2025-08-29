import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- add
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MegaFacilApp());
}

class MegaFacilApp extends StatelessWidget {
  const MegaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mega Fácil',
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,

      // Localização
      locale: const Locale('pt', 'BR'), // opcional, força pt-BR
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
