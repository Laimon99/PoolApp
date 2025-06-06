import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<String>> getRoles() async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('roles').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  } catch (e) {
    return [];
  }
}
