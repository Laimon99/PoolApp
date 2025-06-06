// lib/services/update_service.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UpdateService {
  UpdateService._();
  static final instance = UpdateService._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Inizializza Remote Config e scarica i valori dal server
  Future<void> initRemoteConfig() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    // Valori di default, in caso non si riesca a fetchare
    await _remoteConfig.setDefaults(<String, dynamic>{
      'latest_version_code': 1,
      'latest_download_url': '',
    });
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Errore fetch Remote Config: $e');
    }
  }

  /// Confronta la versione locale con quella remota. Se remota > locale, mostra dialogo.
  Future<void> checkForUpdate({required BuildContext context, bool force = false}) async {
    // 1) Recupera versione locale
    final info = await PackageInfo.fromPlatform();
    final currentCode = int.tryParse(info.buildNumber) ?? 0;

    // 2) Prendi i valori da Remote Config
    final remoteCode = _remoteConfig.getInt('latest_version_code');
    final remoteUrl = _remoteConfig.getString('latest_download_url');

    debugPrint('CurrentVersionCode: $currentCode, RemoteVersionCode: $remoteCode');

    // 3) Se c'è versione più recente
    if (remoteCode > currentCode && remoteUrl.isNotEmpty) {
      // Se è “force”, blocca l’utente finché non aggiorna (non c’è “Più tardi”)
      await _showUpdateDialog(context, remoteUrl, force);
    } else if (force) {
      // Se sei in un contesto “force” ma remoteCode <= current, non fare nulla
    }
  }

  /// Mostra un dialog per l’aggiornamento. Se force=true, non permette di chiudere senza aggiornare.
  Future<void> _showUpdateDialog(BuildContext context, String downloadUrl, bool force) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !force, // se force=true, non si chiude col tap fuori dal dialog
      builder: (ctx) {
        return WillPopScope(
          // se force=true, blocca il back button
          onWillPop: () async => !force,
          child: AlertDialog(
            title: const Text('Aggiornamento disponibile'),
            content: const Text(
                'È stata rilevata una nuova versione dell’app. Vuoi scaricarla e installarla ora?'),
            actions: <Widget>[
              if (!force)
                TextButton(
                  child: const Text('Più tardi'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              TextButton(
                child: const Text('Aggiorna'),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _downloadAndInstallApk(context, downloadUrl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Scarica l’APK e avvia l’installer
  Future<void> _downloadAndInstallApk(BuildContext context, String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/new_build.apk';
      final dio = Dio();

      // Mostra dialog con il progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => DownloadProgressDialog(
            dio: dio, url: url, savePath: savePath),
      );
    } catch (e) {
      debugPrint('Errore nel download: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossibile avviare il download.')),
      );
    }
  }
}

class DownloadProgressDialog extends StatefulWidget {
  final Dio dio;
  final String url;
  final String savePath;
  const DownloadProgressDialog(
      {super.key, required this.dio, required this.url, required this.savePath});
  @override
  State<DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await widget.dio.download(
        widget.url,
        widget.savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
          }
        },
      );
      if (mounted) Navigator.of(context).pop(); // chiudi il dialog
      await OpenFile.open(widget.savePath);
    } catch (e) {
      debugPrint('Errore download APK: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('Download fallito. Riprova più tardi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toStringAsFixed(0);
    return AlertDialog(
      title: const Text('Scaricamento aggiornamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 10),
          Text('$percent %'),
        ],
      ),
    );
  }
}
