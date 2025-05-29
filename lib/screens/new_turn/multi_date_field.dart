import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class MultiDateField extends StatelessWidget {
  final List<DateTime?> selected;
  final ValueChanged<List<DateTime?>> onChanged;

  const MultiDateField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _pickDates(BuildContext context) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.multi,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      ),
      value: selected,
      dialogSize: const Size(325, 400),
    );
    if (results != null) onChanged(results);
  }

  @override
  Widget build(BuildContext context) {
    final label = selected.isEmpty
        ? ''
        : '${selected.whereType<DateTime>().length} date selezionate';

    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: label),
      decoration: const InputDecoration(
        labelText: 'Date',
        suffixIcon: Icon(Icons.calendar_month),
      ),
      validator: (_) =>
      selected.isEmpty ? 'Seleziona almeno una data' : null,
      onTap: () => _pickDates(context),
    );
  }
}