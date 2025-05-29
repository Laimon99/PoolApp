import 'package:flutter/material.dart';

class CertificatesSelector extends StatelessWidget {
  final List<String> available;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const CertificatesSelector({
    super.key,
    required this.available,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ...available.map(
              (c) => FilterChip(
            label: Text(c),
            selected: selected.contains(c),
            onSelected: (_) {
              final newSel = List<String>.from(selected);
              newSel.contains(c) ? newSel.remove(c) : newSel.add(c);
              onChanged(newSel);
            },
          ),
        ),
      ],
    );
  }
}
