import 'package:PoolApp/functions/pay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTurn {
  // Funzione per convertire un TimeOfDay in un oggetto DateTime
  static DateTime timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  // Funzione per controllare sovrapposizioni tra due intervalli temporali
  static bool overlaps(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    return startA.isBefore(endB) && endA.isAfter(startB);
  }

  // Funzione per aggiungere un turno
  static Future<void> add({
    required BuildContext context,
    required String? selectedRole,
    required DateTime? selectedDate,
    required TimeOfDay? selectedStartTime,
    required TimeOfDay? selectedEndTime,
    required List<String> selectedCertificates,
    required String? selectedPiscina,
  }) async {
    if (selectedRole == null ||
        selectedDate == null ||
        selectedStartTime == null ||
        selectedEndTime == null ||
        selectedPiscina == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa tutti i campi!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    try {
      // Recupera l'utente loggato
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Utente non loggato!';

      // Recupera i turni esistenti per l'utente nella stessa data
      final query = await FirebaseFirestore.instance
          .collection('turni')
          .where('user_id', isEqualTo: user.uid)
          .where('date', isEqualTo: selectedDate.toIso8601String())
          .get();

      final newStartTime = timeOfDayToDateTime(selectedStartTime);
      final newEndTime = timeOfDayToDateTime(selectedEndTime);

      if (newStartTime.isAfter(newEndTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'L\'orario di inizio deve essere prima dell\'orario di fine!',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Controllo sovrapposizione turni
      for (var doc in query.docs) {
        final shiftStartTime = DateTime.parse(doc['start_time']);
        final shiftEndTime = DateTime.parse(doc['end_time']);
        if (overlaps(newStartTime, newEndTime, shiftStartTime, shiftEndTime)) {
          throw 'Il turno si sovrappone con un altro turno esistente!';
        }
      }

      // Calcola la paga totale
      final totalPay = await calculateTotalPay(
        selectedRole: selectedRole,
        selectedCertificates: selectedCertificates,
        selectedStartTime: newStartTime,
        selectedEndTime: newEndTime,
      );

      // Crea i dati del turno con la paga finale
      final shiftData = {
        'role': selectedRole,
        'date': selectedDate.toIso8601String(),
        'start_time': newStartTime.toIso8601String(),
        'end_time': newEndTime.toIso8601String(),
        'certificates': selectedCertificates,
        'user_id': user.uid,
        'piscina': selectedPiscina,
        'pay': totalPay,
      };

      // Salva il turno su Firestore
      await FirebaseFirestore.instance.collection('turni').add(shiftData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turno salvato con successo!'), backgroundColor: Colors.green,),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red,));
    }
    // → RIMUOVIAMO il finally con setLoading(false)
  }
}
