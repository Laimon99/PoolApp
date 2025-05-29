import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget per selezionare un intervallo di date e i giorni della settimana.
class WeeklyRangePicker extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;
  final List<int> selectedWeekdays;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;
  final ValueChanged<List<int>> onWeekdaysChanged;

  const WeeklyRangePicker({
    super.key,
    required this.start,
    required this.end,
    required this.selectedWeekdays,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onWeekdaysChanged,
  });

  static const _days = [
    'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'
  ];

  Future<void> _pickDate(
      BuildContext context,
      DateTime? initial,
      ValueChanged<DateTime?> callback,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) callback(picked);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data inizio
        ListTile(
          title: Text(
            start == null
                ? 'Data inizio'
                : 'Inizio: ${fmt.format(start!)}',
          ),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(context, start, onStartChanged),
        ),
        // Data fine
        ListTile(
          title: Text(
            end == null
                ? 'Data fine'
                : 'Fine: ${fmt.format(end!)}',
          ),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(context, end, onEndChanged),
        ),
        const SizedBox(height: 8),
        const Text('Giorni della settimana'),
        Wrap(
          spacing: 4,
          children: List.generate(7, (i) {
            final selected = selectedWeekdays.contains(i);
            return FilterChip(
              label: Text(_days[i]),
              selected: selected,
              onSelected: (on) {
                final newList = List<int>.from(selectedWeekdays);
                if (on) {
                  newList.add(i);
                } else {
                  newList.remove(i);
                }
                onWeekdaysChanged(newList);
              },
            );
          }),
        ),
      ],
    );
  }
}