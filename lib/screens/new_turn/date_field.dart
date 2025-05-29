import 'package:flutter/material.dart';
import '../../../utils/date_utils.dart';
import '../../../utils/form_validator.dart';

class DateField extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;

  const DateField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _pickDate(BuildContext context) async {
    final today = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: selected ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
      locale: const Locale('it', 'IT'),
    );
    onChanged(res);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: selected == null ? '' : formatItalianDate(selected!),
      ),
      decoration: const InputDecoration(
        labelText: 'Data',
        suffixIcon: Icon(Icons.calendar_today),
      ),
      validator: FormValidators.requiredField,
      onTap: () => _pickDate(context),
    );
  }
}
