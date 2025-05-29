import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/turn.dart';

class TurnService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Turn>> watchTurns() {
    return _db
        .collection('turni')
        .where('user_id', isEqualTo: _auth.currentUser!.uid)
        .orderBy('start', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Turn.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> addTurn(Turn turn) async {
    await _db.collection('turni').add(turn.toJson());
  }

  Future<void> deleteTurn(String id) async {
    await _db.collection('turni').doc(id).delete();
  }
}
