import 'package:flutter/material.dart';
import 'new_turn_form.dart';

/// Schermata “Nuovo turno” ― si limita a mostrare il [NewTurnForm].
class NewTurnScreen extends StatelessWidget {
  const NewTurnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: NewTurnForm()),
    );
  }
}
