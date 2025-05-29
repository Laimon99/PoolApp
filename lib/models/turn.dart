import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Turn {
  final String id;
  final DateTime start;
  final DateTime end;
  final String role; // istruttore, assistente
  final String poolId;
  final double hourlyRate;

  Turn({
    required this.id,
    required this.start,
    required this.end,
    required this.role,
    required this.poolId,
    required this.hourlyRate,
  });

  Duration get duration => end.difference(start);

  double get totalPay => duration.inMinutes / 60.0 * hourlyRate;

  factory Turn.fromJson(String id, Map<String, dynamic> json) {
    return Turn(
      id: id,
      start: (json['start'] as Timestamp).toDate(),
      end: (json['end'] as Timestamp).toDate(),
      role: json['role'] as String,
      poolId: json['pool_id'] as String,
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'role': role,
      'pool_id': poolId,
      'hourly_rate': hourlyRate,
      'user_id': FirebaseAuth.instance.currentUser!.uid,
    };
  }
}
