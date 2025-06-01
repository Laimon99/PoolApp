import 'package:flutter/material.dart';
import '../../functions/pay.dart'; // ⬅️ Assicurati che calculateTotalPay sia qui

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

  /// Converte un TimeOfDay su “data di oggi” per poter calcolare una duration.
  DateTime _timeOfDayToTodayDate(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  Future<double> _compute() async {
    if (role == null || start == null || end == null) return 0;

    // Converto start/end usando _timeOfDayToTodayDate(...)
    final startDT = _timeOfDayToTodayDate(start!);
    final endDT   = _timeOfDayToTodayDate(end!);

    // Se l’orario di inizio non è prima di quello di fine, restituisco 0
    if (!startDT.isBefore(endDT)) return 0;

    return await calculateTotalPay(
      selectedRole: role!,
      selectedCertificates: const [],
      selectedStartTime: startDT,
      selectedEndTime: endDT,
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
