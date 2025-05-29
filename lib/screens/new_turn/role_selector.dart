import 'package:flutter/material.dart';
import '../../utils/form_validator.dart';

class RoleSelector extends StatelessWidget {
  final List<String> roles;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const RoleSelector({
    super.key,
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(labelText: 'Ruolo'),
      items: roles
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      validator: FormValidators.requiredField,
      onChanged: onChanged,
    );
  }
}
