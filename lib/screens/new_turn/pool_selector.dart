import 'package:flutter/material.dart';
import '../../utils/form_validator.dart';

class PoolSelector extends StatelessWidget {
  final List<String> pools;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const PoolSelector({
    super.key,
    required this.pools,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(labelText: 'Piscina'),
      items: pools
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      validator: FormValidators.requiredField,
      onChanged: onChanged,
    );
  }
}
