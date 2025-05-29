import 'package:firebase_auth/firebase_auth.dart';

class Turn {
  final String id;
  final DateTime start;
  final DateTime end;
  final DateTime date;                 // giorno “ufficiale”
  final String role;
  final String poolId;
  final double totalPay;
  final List<String> certificates;     // ← NEW

  Turn({
    required this.id,
    required this.start,
    required this.end,
    required this.date,
    required this.role,
    required this.poolId,
    required this.totalPay,
    required this.certificates,        // ← NEW
  });

  // ───────── factory & mapping ─────────

  /// Lettura da Firestore quando hai già l’id del documento
  factory Turn.fromJson(String id, Map<String, dynamic> json) {
    return Turn(
      id          : id,
      start       : DateTime.parse(json['start_time']),
      end         : DateTime.parse(json['end_time']),
      date        : DateTime.parse(json['date']),
      role        : json['role']    ?? '',
      poolId      : json['piscina'] ?? '',
      totalPay    : (json['pay'] as num).toDouble(),
      certificates: List<String>.from(json['certificates'] ?? []), // ← NEW
    );
  }

  /// Conversione pronta per `.set()` o `.add()`
  Map<String, dynamic> toJson() {
    return {
      'start_time' : start.toIso8601String(),
      'end_time'   : end.toIso8601String(),
      'date'       : date.toIso8601String(),
      'role'       : role,
      'piscina'    : poolId,
      'pay'        : totalPay,
      'certificates': certificates,                         // ← NEW
      'user_id'    : FirebaseAuth.instance.currentUser!.uid,
    };
  }

  /// Factory usata quando leggi un documento *senza* conoscere l’id
  factory Turn.fromMap(Map<String, dynamic> map) {
    return Turn(
      id          : map['turno_id'] ?? '',
      start       : DateTime.parse(map['start_time']),
      end         : DateTime.parse(map['end_time']),
      date        : DateTime.parse(map['date']),
      role        : map['role']    ?? '',
      poolId      : map['piscina'] ?? '',
      totalPay    : (map['pay'] as num).toDouble(),
      certificates: List<String>.from(map['certificates'] ?? []), // ← NEW
    );
  }

  /// Mappa “leggera” se ti serve salvare solo alcuni campi
  Map<String, dynamic> toMap() {
    return {
      'start_time' : start.toIso8601String(),
      'end_time'   : end.toIso8601String(),
      'date'       : date.toIso8601String(),
      'role'       : role,
      'piscina'    : poolId,
      'pay'        : totalPay,
      'certificates': certificates,                         // ← NEW
    };
  }

  // ───────── getters di utilità ─────────

  Duration get duration => end.difference(start);
}
