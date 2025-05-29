import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/turn.dart';
import '../providers/turn_provider.dart';
import 'package:uuid/uuid.dart';

class NewTurnScreen extends ConsumerStatefulWidget {
  const NewTurnScreen({super.key});

  @override
  ConsumerState<NewTurnScreen> createState() => _NewTurnScreenState();
}

class _NewTurnScreenState extends ConsumerState<NewTurnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  DateTime? _start;
  DateTime? _end;
  String? _role;
  double? _hourlyRate;
  String? _poolId;

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickEnd() async {
    if (_start == null) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _start!,
      firstDate: _start!,
      lastDate: DateTime(_start!.year, _start!.month, _start!.day + 1),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start!.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    setState(() {
      _end = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo turno')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: const Text('Inizio'),
                subtitle: Text(_start != null ? dateFmt.format(_start!) : 'Seleziona'),
                onTap: _pickStart,
              ),
              ListTile(
                title: const Text('Fine'),
                subtitle: Text(_end != null ? dateFmt.format(_end!) : 'Seleziona'),
                onTap: _pickEnd,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Ruolo'),
                items: const [
                  DropdownMenuItem(value: 'istruttore', child: Text('Istruttore')),
                  DropdownMenuItem(value: 'assistente', child: Text('Assistente bagnanti')),
                ],
                validator: (value) => value == null ? 'Seleziona il ruolo' : null,
                onChanged: (value) => _role = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tariffa oraria (€)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = double.tryParse(value ?? '');
                  if (v == null || v <= 0) {
                    return 'Inserisci un valore valido';
                  }
                  return null;
                },
                onSaved: (value) => _hourlyRate = double.parse(value!),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salva'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (_start == null ||
                        _end == null ||
                        _role == null ||
                        _hourlyRate == null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Completa tutti i campi')));
                      return;
                    }
                    if (_end!.isBefore(_start!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('L\'orario di fine deve essere successivo all\'inizio')));
                      return;
                    }
                    final turn = Turn(
                      id: _uuid.v4(),
                      start: _start!,
                      end: _end!,
                      role: _role!,
                      poolId: _poolId ?? 'default',
                      hourlyRate: _hourlyRate!,
                    );
                    await ref.read(turnServiceProvider).addTurn(turn);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
