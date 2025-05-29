import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/turn.dart';
import '../screens/new_turn.dart';
import '../providers/turn_provider.dart';

class TurnTile extends ConsumerWidget {
  final Turn turn;
  final VoidCallback onDeleted;

  const TurnTile({
    super.key,
    required this.turn,
    required this.onDeleted,
  });

  String _formatDay(DateTime date) {
    final days = {
      DateTime.monday: 'Lunedì',
      DateTime.tuesday: 'Martedì',
      DateTime.wednesday: 'Mercoledì',
      DateTime.thursday: 'Giovedì',
      DateTime.friday: 'Venerdì',
      DateTime.saturday: 'Sabato',
      DateTime.sunday: 'Domenica',
    };
    return '${days[date.weekday]} ${date.day}';
  }

  String _formatTime(DateTime time) => DateFormat.Hm().format(time);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnService = ref.read(turnServiceProvider);

    Future<void> editTurn() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NewTurn(turnToEdit: turn),
        ),
      );
    }

    return Dismissible(
      key: Key(turn.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        print('🧨 Tentativo di eliminare turno con ID: ${turn.id}');
        if (direction == DismissDirection.startToEnd) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Conferma eliminazione"),
              content: const Text("Sei sicuro di voler eliminare questo turno?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Annulla"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Elimina"),
                ),
              ],
            ),
          );
          if (confirm ?? false) {
            await turnService.deleteTurn(turn.id);
            onDeleted();
            return true;
          }
          return false;
        } else {
          await editTurn();
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0563EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Parte sinistra: giorno, orari, ruolo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDay(turn.start),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ore: ${_formatTime(turn.start)} - ${_formatTime(turn.end)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ruolo: ${turn.role[0].toUpperCase()}${turn.role.substring(1)}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            // Parte destra: piscina e compenso
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  turn.poolId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Compenso: ${turn.totalPay.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
