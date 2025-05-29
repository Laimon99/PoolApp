import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/turn.dart';

class TurnService {
  final _turnCollection = FirebaseFirestore.instance.collection('turni');

  Future<void> addTurn(Turn turn) async {
    await _turnCollection.doc(turn.id).set(turn.toMap());
  }

  Future<void> deleteTurn(String id) async {
    await _turnCollection.doc(id).delete();
  }

  Future<void> updateTurn(Turn turn) async {
    await _turnCollection.doc(turn.id).update(turn.toMap());
  }

  Stream<List<Turn>> watchTurns() {
    return _turnCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Turn.fromMap(doc.data())).toList();
    });
  }

  Future<List<Turn>> fetchAllTurns() async {
    final snapshot = await _turnCollection.get();
    return snapshot.docs.map((doc) => Turn.fromMap(doc.data())).toList();
  }
}
