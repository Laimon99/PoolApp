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
  String get date => '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
  double get totalPay => duration.inMinutes / 60.0 * hourlyRate;

  factory Turn.fromJson(String id, Map<String, dynamic> json) {
    return Turn(
      id: id,
      start: DateTime.parse(json['start_time']),  // o usa .toDate() se Timestamp
      end: DateTime.parse(json['end_time']),
      role: json['role'] ?? '',
      poolId: json['piscina'] ?? '',
      hourlyRate: (json['pay'] as num).toDouble(),
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'role': role,
      'poolId': poolId,
      'hourlyRate': hourlyRate,
    };
  }

  factory Turn.fromMap(Map<String, dynamic> map) {
    return Turn(
      id: map['turni_id'] ?? '',
      start: DateTime.parse(map['start_time']),
      end: DateTime.parse(map['end_time']),
      role: map['role'] ?? '',
      poolId: map['piscina'] ?? '',
      hourlyRate: (map['pay'] as num).toDouble(),
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
