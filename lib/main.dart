import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'package:PoolApp/screens/auth.dart';
import 'package:PoolApp/screens/main_screen.dart';
import 'package:PoolApp/screens/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Questo gestore è chiamato quando la notifica arriva a app in background o chiusa
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Puoi loggare qui se vuoi o gestire logicamente il messaggio
  print('Background message ricevuto: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Imposta il gestore per i messaggi in background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(ProviderScope(child: const App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    // Chiedi i permessi per le notifiche (Android 13+ e iOS)
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Iscrivi il device al topic "updates"
      await FirebaseMessaging.instance.subscribeToTopic('updates');
      await FirebaseMessaging.instance.subscribeToTopic('comunicazioni');
      print('Iscritto al topic "updates"');
    } else {
      print('Permessi notifiche non concessi');
    }

    // Listener per NOTIFICHE IN FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message ricevuto: ${message.notification?.title}');
      _showUpdateDialog(
        message.notification?.title ?? 'Aggiornamento disponibile',
        message.notification?.body ?? 'Tocca per aggiornare',
        message.data['download_url'],
      );
    });

    // Listener per NOTIFICHE APRITE DA BACKGROUND/CHIUSA
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notifica aperta da background: ${message.notification?.title}');
      final String? url = message.data['download_url'];
      if (url != null) {
        _openUrl(url);
      }
    });
  }

  void _showUpdateDialog(String title, String body, String? downloadUrl) {
    if (downloadUrl == null) return;
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
              child: const Text('Più tardi'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(navigatorKey.currentContext!).pop();
                _openUrl(downloadUrl);
              },
              child: const Text('Aggiorna'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    // Usa url_launcher per aprire il link nel browser/installatore
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire il link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoolSchedule',
      navigatorKey: navigatorKey,
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
      ],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

// Per gestire la navigazione dai callback FCM
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
