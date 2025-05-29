import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Turn {
  final String id;
  final DateTime start;
  final DateTime end;
  final String role;           // es.: istruttore, assistente
  final String poolId;         // piscina
  final double hourlyRate;     // ► tariffa oraria, **non** il totale!

  Turn({
    required this.id,
    required this.start,
    required this.end,
    required this.role,
    required this.poolId,
    required this.hourlyRate,
  });

  // --- getter utili ----------------------------------------------------------
  Duration get duration  => end.difference(start);
  double   get totalPay  => duration.inMinutes / 60.0 * hourlyRate;

  // --- factory  ↙  dai dati Firebase  ----------------------------------------
  factory Turn.fromJson(String id, Map<String, dynamic> json) {
    return Turn(
      id        : id,
      start     : DateTime.parse(json['start_time']),
      end       : DateTime.parse(json['end_time']),
      role      : json['role']     ?? '',
      poolId    : json['piscina']  ?? '',
      hourlyRate: (json['pay'] as num).toDouble(),    // pay = € / ora
    );
  }

  // ► usato da filteredTotalPay()
  Map<String, dynamic> toMap() {
    return {
      'start_time': start.toIso8601String(),
      'end_time'  : end.toIso8601String(),
      'role'      : role,
      'piscina'   : poolId,
      'pay'       : hourlyRate,          // <-- tariffa oraria (non totale)
    };
  }

  factory Turn.fromMap(Map<String, dynamic> map) {
    return Turn(
      id        : map['turno_id'] ?? '',
      start     : DateTime.parse(map['start_time']),
      end       : DateTime.parse(map['end_time']),
      role      : map['role']     ?? '',
      poolId    : map['piscina']  ?? '',
      hourlyRate: (map['pay'] as num).toDouble(),
    );
  }

  // ► per salvare / aggiornare su Firestore
  Map<String, dynamic> toJson() {
    return {
      'start_time' : start.toIso8601String(),
      'end_time'   : end.toIso8601String(),
      'role'       : role,
      'piscina'    : poolId,
      'pay'        : hourlyRate,
      'user_id'    : FirebaseAuth.instance.currentUser!.uid,
    };
  }
}
