import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String> fetchUserId() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('Nessun utente autenticato');
  }

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!userDoc.exists) {
    throw Exception('Dati utente non trovati');
  }

  return userDoc.id.toString();
}