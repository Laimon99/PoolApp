import 'package:flutter/material.dart';
import '../../utils/form_validator.dart';

class TimeRangePicker extends StatelessWidget {
  final TimeOfDay? start;
  final TimeOfDay? end;
  final void Function(TimeOfDay, TimeOfDay) onChanged;

  const TimeRangePicker({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
  });

  Future<TimeOfDay?> _pickTime(BuildContext ctx, TimeOfDay initial) =>
      showTimePicker(context: ctx, initialTime: initial);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeField(
            label: 'Inizio',
            value: start,
            onTap: () async {
              final t = await _pickTime(
                  context, start ?? const TimeOfDay(hour: 9, minute: 0));
              if (t != null && end != null) onChanged(t, end!);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimeField(
            label: 'Fine',
            value: end,
            onTap: () async {
              final t = await _pickTime(
                  context, end ?? const TimeOfDay(hour: 10, minute: 0));
              if (t != null && start != null) onChanged(start!, t);
            },
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text =
    value == null ? '' : value!.format(context);
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: text),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.access_time),
      ),
      validator: FormValidators.requiredField,
      onTap: onTap,
    );
  }
}
