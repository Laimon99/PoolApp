import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteTurno(Map<String, dynamic> turno) async {
  print(turno);
  final turnoRef = FirebaseFirestore.instance
      .collection('turni')
      .doc(turno['turno_id'].toString());
  print(turnoRef);
  await turnoRef.delete();
}
