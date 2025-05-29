// pay_calculator.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<double> calculateTotalPay({
  required String selectedRole,
  required List<String> selectedCertificates,
  required DateTime selectedStartTime,
  required DateTime selectedEndTime,
}) async {
  // Recupera il documento del ruolo selezionato per ottenere la paga
  DocumentSnapshot roleDoc = await FirebaseFirestore.instance
      .collection('roles')
      .doc(selectedRole)
      .get();

  if (!roleDoc.exists) {
    throw 'Ruolo non trovato!';
  }

  final roleData = roleDoc.data() as Map<String, dynamic>;
  double finalPay;

  // Recupera la paga di base e converte in double se necessario
  if (roleData['basepay'] is int) {
    finalPay = (roleData['basepay'] as int).toDouble();
  } else {
    finalPay = roleData['basepay'] as double;
  }

  // Controlla se l'utente ha uno dei certificati richiesti per ottenere un aumento della paga
  List<dynamic> conditions = roleData['conditions'];
  for (var condition in conditions) {
    String requiredCertificate = condition['requiredCertificate'];
    double pay;

    // Recupera la paga della condizione e converte in double se necessario
    if (condition['pay'] is int) {
      pay = (condition['pay'] as int).toDouble();
    } else {
      pay = condition['pay'] as double;
    }

    // Se il certificato è incluso nei certificati selezionati, aggiorna la paga
    if (selectedCertificates.contains(requiredCertificate)) {
      finalPay = pay;
      break;
    }
  }

  // Calcola la durata del turno in ore
  final duration = selectedEndTime.difference(selectedStartTime).inMinutes / 60.0;

  // Moltiplica la paga finale per la durata del turno
  final totalPay = finalPay * duration;
  return totalPay;
}
