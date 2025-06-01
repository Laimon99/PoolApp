import 'package:PoolApp/functions/pay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTurn {
  // Controlla se due intervalli [startA,endA] e [startB,endB] si sovrappongono
  static bool overlaps(DateTime startA, DateTime endA, DateTime startB, DateTime endB) {
    return startA.isBefore(endB) && endA.isAfter(startB);
  }

  /// Aggiunge o aggiorna un turno su Firestore, verificando:
  /// 1) che tutti i campi obbligatori non siano nulli;
  /// 2) che l’orario di inizio sia precedente a quello di fine;
  /// 3) che non ci siano altri turni salvati nella stessa data (campo "date")
  ///    con orari che si sovrappongono.
  /// Se si sta modificando un turno esistente, va passato [editingTurnId] per
  /// escludere il documento corrente dal controllo di sovrapposizione.
  static Future<void> add({
    required BuildContext context,
    required String? selectedRole,
    required DateTime? selectedStartDateTime,  // DateTime completo (data+ora inizio)
    required DateTime? selectedEndDateTime,    // DateTime completo (data+ora fine)
    required List<String> selectedCertificates,
    required String? selectedPiscina,
    String? editingTurnId,  // opzionale: ID del documento da escludere (in modifica)
  }) async {
    // 1) Validazione di base
    if (selectedRole == null ||
        selectedStartDateTime == null ||
        selectedEndDateTime == null ||
        selectedPiscina == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa tutti i campi!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2) Verifica orario
    if (!selectedStartDateTime.isBefore(selectedEndDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L’orario di inizio deve essere precedente a quello di fine!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // 3) Recupera utente loggato
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Utente non loggato!';

      // 4) Costruisco la “chiave data” (solo anno-mese-giorno, ora=00:00)
      final dateKey = DateTime(
        selectedStartDateTime.year,
        selectedStartDateTime.month,
        selectedStartDateTime.day,
      ).toIso8601String();
      // es. "2025-06-15T00:00:00.000Z"

      // 5) Recupero tutti i turni di QUESTO utente per quella data
      final querySnapshot = await FirebaseFirestore.instance
          .collection('turni')
          .where('user_id', isEqualTo: user.uid)
          .where('date', isEqualTo: dateKey)
          .get();

      // 6) Controllo sovrapposizione
      for (var doc in querySnapshot.docs) {
        // Se sto in fase di modifica, escludo il documento corrente
        if (editingTurnId != null && doc.id == editingTurnId) {
          continue;
        }

        final storedStart = doc.data()['start_time'];
        final storedEnd   = doc.data()['end_time'];

        // Se in Firestore mancano questi campi, salto il doc
        if (storedStart == null || storedEnd == null) {
          continue;
        }

        DateTime shiftStartTime;
        DateTime shiftEndTime;
        try {
          shiftStartTime = DateTime.parse(storedStart as String);
          shiftEndTime   = DateTime.parse(storedEnd as String);
        } catch (_) {
          // Se il parsing fallisce, salto quel documento
          continue;
        }

        if (overlaps(
            selectedStartDateTime, selectedEndDateTime, shiftStartTime, shiftEndTime)) {
          throw 'Il turno si sovrappone con un altro turno esistente!';
        }
      }

      // 7) Calcolo paga
      final totalPay = await calculateTotalPay(
        selectedRole: selectedRole,
        selectedCertificates: selectedCertificates,
        selectedStartTime: selectedStartDateTime,
        selectedEndTime: selectedEndDateTime,
      );

      // 8) Preparo i dati da salvare
      final shiftData = {
        'role': selectedRole,
        'date': dateKey,                                 // solo anno-mese-giorno
        'start_time': selectedStartDateTime.toIso8601String(),
        'end_time': selectedEndDateTime.toIso8601String(),
        'certificates': selectedCertificates,
        'user_id': user.uid,
        'piscina': selectedPiscina,
        'pay': totalPay,
      };

      // 9) Se sto modificando, aggiorno; altrimenti aggiungo un nuovo documento
      if (editingTurnId != null) {
        await FirebaseFirestore.instance
            .collection('turni')
            .doc(editingTurnId)
            .update(shiftData);
      } else {
        await FirebaseFirestore.instance.collection('turni').add(shiftData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il salvataggio: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
