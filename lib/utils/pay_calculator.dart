import '../models/turn.dart';

class PayBreakdown {
  final Duration duration;     // durata effettiva del turno
  final double total;          // compenso totale del turno
  final num hourlyRate;     // (facoltativo) € / ora ricavato

  const PayBreakdown({
    required this.duration,
    required this.total,
    required this.hourlyRate,
  });
}

class PayCalculator {
  /// Restituisce durata, totale (già presente) e tariffa oraria ricavata
  PayBreakdown compute(Turn turn) {
    final d = turn.duration;

    // totale già calcolato in NewTurn e letto da Firestore
    final total = turn.totalPay;

    // tariffa oraria ricavata (proteggi da divisione per zero)
    final hours = d.inMinutes / 60.0;
    final hourlyRate = hours == 0 ? 0 : total / hours;

    return PayBreakdown(
      duration: d,
      total: total,
      hourlyRate: hourlyRate,
    );
  }
}
