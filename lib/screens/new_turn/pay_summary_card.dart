import 'package:flutter/material.dart';
import '../../../functions/add_turn.dart';
import '../../functions/pay.dart';   // ⬅️ importa la tua funzione già esistente

class PaySummaryCard extends StatelessWidget {
  final String? role;
  final TimeOfDay? start;
  final TimeOfDay? end;

  const PaySummaryCard({
    super.key,
    required this.role,
    required this.start,
    required this.end,
  });

  Future<double> _compute() async {
    if (role == null || start == null || end == null) return 0;

    // Usa direttamente il calcolatore centrale
    return await calculateTotalPay(
      selectedRole        : role!,
      selectedCertificates: const [],   // se i brevetti non servono qui
      selectedStartTime   : AddTurn.timeOfDayToDateTime(start!),
      selectedEndTime     : AddTurn.timeOfDayToDateTime(end!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder<double>(
        future: _compute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            );
          }
          final pay = snapshot.data ?? 0.0;
          return ListTile(
            title: const Text('Compenso stimato'),
            trailing: Text(
              '€ ${pay.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        },
      ),
    );
  }
}
