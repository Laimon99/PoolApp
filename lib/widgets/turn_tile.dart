import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/turn.dart';

class TurnTile extends StatelessWidget {
  final Turn turn;
  const TurnTile({super.key, required this.turn});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat.Hm();

    return ListTile(
      leading: const Icon(Icons.pool),
      title: Text('${dateFmt.format(turn.start)} • ${turn.role.toUpperCase()}'),
      subtitle: Text(
          '${timeFmt.format(turn.start)} - ${timeFmt.format(turn.end)} • ${turn.duration.inHours}h ${turn.duration.inMinutes.remainder(60)}m'),
      trailing: Text('€ ${turn.totalPay.toStringAsFixed(2)}'),
    );
  }
}
