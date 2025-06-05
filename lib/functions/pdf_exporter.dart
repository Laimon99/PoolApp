import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/turn.dart';

/// Genera un PDF con l’elenco dei turni (già filtrati e ordinati),
/// lo salva in /storage/emulated/0/Download/turni_<timestamp>.pdf e
/// restituisce il percorso completo del file salvato.
Future<String> exportTurnsToPdf(List<Turn> turni) async {
  final pdf = pw.Document();

  // Stili base
  pw.TextStyle headerStyle = pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
  );
  const pw.TextStyle contentStyle = pw.TextStyle(fontSize: 12);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (context) {
        return [
          pw.Text(
            'Elenco Turni',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              'Data',
              'Piscina',
              'Ruolo',
              'Inizio',
              'Fine',
              'Ore Totali',
              'Compenso (€)'
            ],
            data: turni.map((turn) {
              // Mappa weekday → nome italiano
              final giorniSettimana = {
                DateTime.monday: 'Lunedì',
                DateTime.tuesday: 'Martedì',
                DateTime.wednesday: 'Mercoledì',
                DateTime.thursday: 'Giovedì',
                DateTime.friday: 'Venerdì',
                DateTime.saturday: 'Sabato',
                DateTime.sunday: 'Domenica',
              };
              final String dataFormattata =
                  '${giorniSettimana[turn.date.weekday]} ${turn.date.day}';

              String formatTime(DateTime dt) {
                final h = dt.hour.toString().padLeft(2, '0');
                final m = dt.minute.toString().padLeft(2, '0');
                return '$h:$m';
              }

              // Calcolo ore totali in decimali
              final durata = turn.end.difference(turn.start);
              final oreTotali = durata.inMinutes / 60.0;
              final oreFormattate = oreTotali.toStringAsFixed(2);

              return [
                dataFormattata,
                turn.poolId,
                turn.role,
                formatTime(turn.start),
                formatTime(turn.end),
                oreFormattate,
                turn.totalPay.toStringAsFixed(2),
              ];
            }).toList(),
            headerStyle: headerStyle,
            cellStyle: contentStyle,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.grey300),
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(1),
              6: pw.FlexColumnWidth(1),
            },
          ),
        ];
      },
    ),
  );

  // **Forziamo il path esplicito alla cartella pubblica “Download”**
  const String downloadPath = '/storage/emulated/0/Download';
  final directory = Directory(downloadPath);

  // Se la cartella Download non esiste, la creiamo
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final fileName = 'turni_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File('$downloadPath/$fileName');

  await file.writeAsBytes(await pdf.save());
  return file.path;
}
