import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<String>> getPiscine() async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('piscine').get();
    return snapshot.docs.map((doc) => doc['nome'] as String).toList();
  } catch (e) {
    print('Errore durante il recupero delle piscine: $e');
    return [];
  }
}
