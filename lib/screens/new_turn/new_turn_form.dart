import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../screens/new_turn/role_selector.dart';
import '../../screens/new_turn/date_field.dart';
import '../../screens/new_turn/weekly_range_picker.dart';
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

  String? _role;
  DateTime? _singleDate;
  DateTime? _weeklyStart;
  DateTime? _weeklyEnd;
  List<int> _selectedWeekdays = [];
  TimeOfDay? _start;
  TimeOfDay? _end;
  String? _poolId;
  List<String> _certificates = [];
  bool _isLoading = false;
  bool _isWeekly = false;

  bool get _isEditing => widget.turnToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _prefill(widget.turnToEdit!);
  }

  void _prefill(Turn t) {
    _role = t.role;
    _singleDate = t.date;
    _start = TimeOfDay.fromDateTime(t.start);
    _end = TimeOfDay.fromDateTime(t.end);
    _poolId = t.poolId;
    _certificates = List<String>.from(t.certificates);
  }

  List<DateTime> _generateDates() {
    if (_isWeekly) {
      final dates = <DateTime>[];
      var current = _weeklyStart!;
      while (!current.isAfter(_weeklyEnd!)) {
        if (_selectedWeekdays.contains(current.weekday - 1)) {
          dates.add(current);
        }
        current = current.add(const Duration(days: 1));
      }
      return dates;
    } else {
      return [_singleDate!];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isWeekly) {
      if (_weeklyStart == null || _weeklyEnd == null || _selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona range date e giorni della settimana')),
        );
        return;
      }
    } else if (_singleDate == null) {
      return;
    }

    setState(() => _isLoading = true);
    final dates = _generateDates();
    try {
      for (final d in dates) {
        await AddTurn.add(
          context: context,
          selectedRole: _role,
          selectedDate: d,
          selectedStartTime: _start,
          selectedEndTime: _end,
          selectedCertificates: _certificates,
          selectedPiscina: _poolId,
          // → non passiamo più resetForm qui
        );
      }

      // **RESET FORM UNA VOLTA SOLA**
      _formKey.currentState!.reset();
      setState(() {
        _role = null;
        _singleDate = null;
        _weeklyStart = null;
        _weeklyEnd = null;
        _selectedWeekdays = [];
        _start = null;
        _end = null;
        _poolId = null;
        _certificates = [];
        _isWeekly = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([getRoles(), getPiscine(), fetchUserData()]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Errore: ${snap.error}'));
        }

        final roles = snap.data![0] as List<String>;
        final pools = snap.data![1] as List<String>;
        final user = snap.data![2] as Map<String, dynamic>;
        final brevetti = List<String>.from(user['brevetti'] ?? []);

        return Stack(
          children: [
            if (_isLoading) const Center(child: CircularProgressIndicator()),
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
                      CheckboxListTile(
                        title: const Text('Turno settimanale'),
                        value: _isWeekly,
                        onChanged: (v) => setState(() => _isWeekly = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 8),
                      if (!_isWeekly) ...[
                        DateField(
                          selected: _singleDate,
                          onChanged: (v) => setState(() => _singleDate = v),
                        ),
                      ] else ...[
                        WeeklyRangePicker(
                          start: _weeklyStart,
                          end: _weeklyEnd,
                          selectedWeekdays: _selectedWeekdays,
                          onStartChanged: (d) => setState(() => _weeklyStart = d),
                          onEndChanged: (d) => setState(() => _weeklyEnd = d),
                          onWeekdaysChanged: (list) => setState(() => _selectedWeekdays = list),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TimeRangePicker(
                        start: _start,
                        end: _end,
                        onChanged: (s, e) => setState(() {
                          _start = s;
                          _end = e;
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
                        available: brevetti,
                        selected: _certificates,
                        onChanged: (v) => setState(() => _certificates = v),
                      ),
                      const SizedBox(height: 16),
                      PaySummaryCard(
                        role: _role,
                        start: _start,
                        end: _end,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.save,
                          color: Colors.black,
                        ),
                        label: Text(
                          _isEditing
                              ? 'Aggiorna'
                              : (_isWeekly ? 'Salva turni' : 'Salva'),
                          style: const TextStyle(color: Colors.black),
                        ),
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
