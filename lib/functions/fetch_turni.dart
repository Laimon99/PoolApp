import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/turn.dart';
import 'fetch_user_id.dart';

Future<List<Turn>> fetchTurni() async {
  try {
    final userId = await fetchUserId();
    if (userId.isEmpty) throw Exception('ID utente non valido');

    final querySnapshot = await FirebaseFirestore.instance
        .collection('turni')
        .where('user_id', isEqualTo: userId)
        .get();

    final turni = querySnapshot.docs.map((doc) {
      print('📄 TURNO da Firebase (ID: ${doc.id}):');
      doc.data().forEach((key, value) => print('   $key: $value'));

      return Turn.fromJson(doc.id, doc.data()); // 🔥 usa il costruttore con ID
    }).toList();

    return turni;
  } catch (e) {
    print('❌ Errore durante il recupero dei turni: $e');
    rethrow;
  }
}
