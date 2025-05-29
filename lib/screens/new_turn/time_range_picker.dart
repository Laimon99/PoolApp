import 'package:flutter/material.dart';

class TimeRangePicker extends StatelessWidget {
  final TimeOfDay? start;
  final TimeOfDay? end;
  final void Function(TimeOfDay?, TimeOfDay?) onChanged;

  const TimeRangePicker({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
  });

  Future<void> _selectStart(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      onChanged(picked, end);
    }
  }

  Future<void> _selectEnd(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: end ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      onChanged(start, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            start == null
                ? 'Ora inizio'
                : 'Inizio: ${start!.format(context)}',
          ),
          trailing: const Icon(Icons.access_time),
          onTap: () => _selectStart(context),
        ),
        ListTile(
          title: Text(
            end == null
                ? 'Ora fine'
                : 'Fine: ${end!.format(context)}',
          ),
          trailing: const Icon(Icons.access_time),
          onTap: () => _selectEnd(context),
        ),
      ],
    );
  }
}
