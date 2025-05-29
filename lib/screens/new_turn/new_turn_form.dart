import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../screens//new_turn/role_selector.dart';
import '../../screens/new_turn/date_field.dart';
import '../../screens/new_turn/time_range_picker.dart';
import '../../screens/new_turn/pool_selector.dart';
import '../../screens/new_turn/certificates_selector.dart';
import '../../screens/new_turn/pay_summary_card.dart';
import '../../functions/add_turn.dart';
import '../../functions/fetch_user_data.dart';
import '../../functions/get_roles.dart';
import '../../functions/get_piscine.dart';
import '../../models/turn.dart';

class NewTurnForm extends StatefulWidget {
  final Turn? turnToEdit;
  const NewTurnForm({super.key, this.turnToEdit});

  @override
  State<NewTurnForm> createState() => _NewTurnFormState();
}


class _NewTurnFormState extends State<NewTurnForm> {
  final _formKey = GlobalKey<FormState>();
  @override
  void didUpdateWidget(covariant NewTurnForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // È cambiato il turno in editing?
    if (widget.turnToEdit != oldWidget.turnToEdit) {
      if (widget.turnToEdit == null) {
        // Siamo passati da "modifica" a "nuovo": svuota tutto
        setState(() {
          _role         = null;
          _date         = null;
          _start        = null;
          _end          = null;
          _poolId       = null;
          _certificates = [];
        });
      } else {
        // Siamo passati da un turno a un altro turno: refilla
        _prefillFromTurn(widget.turnToEdit!);
      }
    }
  }

  // Stato del form
  String? _role;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  String? _poolId;
  List<String> _certificates = [];

  bool _isLoading = false;
  bool get _isEditing => widget.turnToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _prefillFromTurn(widget.turnToEdit!);
  }

  void _prefillFromTurn(Turn t) {
    _role = t.role;
    _date = t.date;
    _start = TimeOfDay.fromDateTime(t.start);
    _end   = TimeOfDay.fromDateTime(t.end);
    _poolId = t.poolId;
    _certificates = List<String>.from(t.certificates);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AddTurn.add(
        context: context,
        selectedRole: _role,
        selectedDate: _date,
        selectedStartTime: _start,
        selectedEndTime: _end,
        selectedCertificates: _certificates,
        selectedPiscina: _poolId,
        setLoading: (v) => setState(() => _isLoading = v),
        resetForm: () {},       // nel tuo caso non ti serve
      );

      if (!mounted) return;
      Navigator.pop(context, true); // torna alla lista con esito OK
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Errore')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([getRoles(), getPiscine(), fetchUserData()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Errore di rete: ${snapshot.error}'));
        }

        final (roles, pools, user) = (
        snapshot.data![0] as List<String>,
        snapshot.data![1] as List<String>,
        snapshot.data![2] as Map<String, dynamic>,
        );

        // Aggiorna certificati disponibili per l’utente
        final brevettiUtente = List<String>.from(user['brevetti'] ?? []);

        return Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            Opacity(
              opacity: _isLoading ? 0.3 : 1,
              child: IgnorePointer(
                ignoring: _isLoading,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      RoleSelector(
                        roles: roles,
                        selected: _role,
                        onChanged: (v) => setState(() => _role = v),
                      ),
                      const SizedBox(height: 8),
                      DateField(
                        selected: _date,
                        onChanged: (v) => setState(() => _date = v),
                      ),
                      const SizedBox(height: 8),
                      TimeRangePicker(
                        start: _start,
                        end: _end,
                        onChanged: (s, e) => setState(() {
                          _start = s;
                          _end   = e;
                        }),
                      ),
                      const SizedBox(height: 8),
                      PoolSelector(
                        pools: pools,
                        selected: _poolId,
                        onChanged: (v) => setState(() => _poolId = v),
                      ),
                      const SizedBox(height: 8),
                      CertificatesSelector(
                        available: brevettiUtente,
                        selected: _certificates,
                        onChanged: (v) =>
                            setState(() => _certificates = v),
                      ),
                      const SizedBox(height: 16),
                      PaySummaryCard(
                        role: _role,
                        start: _start,
                        end: _end,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(_isEditing ? 'Aggiorna' : 'Salva'),
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
