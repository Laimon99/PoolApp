import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/turn_provider.dart';
import '../widgets/turn_tile.dart';
import 'new_turn_screen.dart';

class TurnListScreen extends ConsumerWidget {
  const TurnListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnsAsync = ref.watch(turnsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei turni'),
      ),
      body: turnsAsync.when(
        data: (turns) {
          if (turns.isEmpty) {
            return const Center(child: Text('Nessun turno registrato.'));
          }
          return ListView.separated(
            itemCount: turns.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) => TurnTile(turn: turns[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewTurnScreen()),
          );
        },
        label: const Text('Nuovo turno'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
