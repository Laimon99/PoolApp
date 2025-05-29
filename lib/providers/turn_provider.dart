import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/turn_service.dart';
import '../models/turn.dart';

final turnServiceProvider = Provider<TurnService>((ref) => TurnService());

final turnsStreamProvider = StreamProvider<List<Turn>>((ref) {
  return ref.watch(turnServiceProvider).watchTurns();
});
