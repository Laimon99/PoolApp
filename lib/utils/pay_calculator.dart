import '../models/turn.dart';

class PayBreakdown {
  final Duration duration;
  final double total;

  const PayBreakdown({required this.duration, required this.total});
}

class PayCalculator {
  PayBreakdown compute(Turn turn) {
    final d = turn.duration;
    final total = d.inMinutes / 60.0 * turn.hourlyRate;
    return PayBreakdown(duration: d, total: total);
  }
}
