// lib/screens/splash.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:PoolApp/screens/auth.dart';
import 'package:PoolApp/screens/main_screen.dart';
import '../services/update_services.dart'; // ← Assicurati che sia il percorso corretto

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _alreadyChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_alreadyChecked) {
      _alreadyChecked = true;
      _initAndCheck();
    }
  }

  Future<void> _initAndCheck() async {
    // 1) Inizializza e scarica i parametri di Remote Config
    await UpdateService.instance.initRemoteConfig();

    // 2) Controlla se c’è un aggiornamento (force = false → l’utente può scegliere "Più tardi")
    if (!mounted) return;
    await UpdateService.instance.checkForUpdate(
      context: context,
      force: false,
    );

    // 3) Aspetta un secondo (effetto splash)
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // 4) Dopo il delay e il check, naviga a seconda dello stato di login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, snapshot) {
            // Se stiamo aspettando Auth, mostriamo un loader
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Se l’utente è loggato, vai a MainScreen
            if (snapshot.hasData) {
              return const MainScreen();
            }
            // Altrimenti, vai a AuthScreen
            return const AuthScreen();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}