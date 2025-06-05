import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/turn.dart';

/// Genera un PDF con l’elenco dei turni (già filtrati e ordinati),
/// aggiunge in fondo la riga con totali, lo salva in /storage/emulated/0/Download/turni_<timestamp>.pdf e
/// restituisce il percorso completo del file salvato.
Future<String> exportTurnsToPdf(List<Turn> turni) async {
  final pdf = pw.Document();

  // 1) Stili base
  final headerStyle = pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
  );
  const contentStyle = pw.TextStyle(fontSize: 12);

  // 2) Calcolo del totale ore e del totale compenso
  double totaleOre = 0.0;
  double totaleCompenso = 0.0;
  for (var turn in turni) {
    final durata = turn.end.difference(turn.start);
    final ore = durata.inMinutes / 60.0;
    totaleOre += ore;
    totaleCompenso += turn.totalPay;
  }
  // Formattazioni
  final totaleOreFormattato = totaleOre.toStringAsFixed(2);
  final totaleCompensoFormattato = totaleCompenso.toStringAsFixed(2);

  // 3) Costruzione dei dati per la tabella:
  //    - prima tutte le righe dei turni
  //    - poi, come ultima riga, il riepilogo.
  //    Nota: lasciamo vuote le prime 5 colonne per allineare i totali sotto "Ore Totali" e "Compenso".
  final List<List<String>> rows = turni.map((turn) {
    // Mappa weekday → nome italiano
    const giorniSettimana = {
      DateTime.monday: 'Lunedì',
      DateTime.tuesday: 'Martedì',
      DateTime.wednesday: 'Mercoledì',
      DateTime.thursday: 'Giovedì',
      DateTime.friday: 'Venerdì',
      DateTime.saturday: 'Sabato',
      DateTime.sunday: 'Domenica',
    };
    final giorno = giorniSettimana[turn.date.weekday]!;
    final dataFormattata = '$giorno ${turn.date.day}/${turn.date.month}/${turn.date.year}';

    String formatTime(DateTime dt) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

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
  }).toList();

  // Riga di riepilogo (ultima riga).
  // Le prime 5 celle sono stringhe vuote (per mantenere la struttura a 7 colonne),
  // quindi nelle colonne “Ore Totali” e “Compenso” vengono inseriti i valori aggregati.
  rows.add([
    '', // Data
    '', // Piscina
    '', // Ruolo
    '', // Inizio
    'Totale:', // Fine (usiamo questa colonna solo per l’etichetta, ma è opzionale)
    totaleOreFormattato, // Ore Totali
    totaleCompensoFormattato, // Compenso (€)
  ]);

  // 4) Creazione della pagina PDF
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
            data: rows,
            headerStyle: headerStyle,
            cellStyle: contentStyle,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
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
            // Possiamo applicare uno stile differente solo all’ultima riga (il riepilogo)
            cellDecoration: (row, column, cell) {
              if (row == rows.length - 1) {
                return const pw.BoxDecoration(color: PdfColors.grey200);
              }
              return pw.BoxDecoration();
            },

            cellAlignments: {
              // Per la riga di riepilogo vogliamo che "Totale:" venga centrato nella colonna 4
              // e i due numeri (colonne 5 e 6) allineati come gli altri.
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.center,
              6: pw.Alignment.centerRight,
            },
          ),
        ];
      },
    ),
  );

  // 5) Salvataggio e restituzione del percorso
  const String downloadPath = '/storage/emulated/0/Download';
  final directory = Directory(downloadPath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  final fileName = 'turni_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File('$downloadPath/$fileName');
  await file.writeAsBytes(await pdf.save());
  return file.path;
}
