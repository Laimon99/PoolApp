import 'package:cloud_firestore/cloud_firestore.dart';
import 'fetch_user_id.dart';

Future<List<Map<String, dynamic>>> fetchTurni() async {
  try {
    final userData = await fetchUserId();

    // Verifica che userData contenga una chiave 'id' non nulla
    final userId = userData;
    if (userId.isEmpty) {
      throw Exception('ID utente non valido');
    }

    // Recupera i documenti dalla raccolta "turni" filtrando per user_id
    final querySnapshot = await FirebaseFirestore.instance
        .collection('turni')
        .where('user_id', isEqualTo: userId)
        .get();

    // Trasforma i documenti in una lista di Map aggiungendo l'ID del turno
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      // Aggiungi l'ID del documento alla mappa
      data['turno_id'] = doc.id;
      return data;
    }).toList();
  } catch (e) {
    print('Errore durante il recupero dei turni: $e');
    throw Exception('Errore durante il recupero dei turni: $e');
  }
}
