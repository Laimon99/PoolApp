import 'package:flutter/material.dart';
import 'package:pool_app/screens/new_turn/new_turn_screen.dart';
import 'package:pool_app/screens/turn_list.dart';
import '../models/turn.dart';
import 'account_data.dart';
import 'new_turn/new_turn_form.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String title = 'Elenco turni';

  Turn? _turnToEdit;

  List<Widget> get _sections => [
    TurnList(onEditRequested: _handleEditTurn),
    NewTurnForm(turnToEdit: _turnToEdit),
    const AccountData(),
  ];

  void _handleEditTurn(Turn turn) {
    setState(() {
      _turnToEdit = turn;
      _selectedIndex = 1;
      title = 'Modifica turno';
    });
  }


  void _onItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          title = 'Elenco turni';
          break;
        case 1:
          title = 'Aggiungi turni';
          _turnToEdit = null;          // 👈 svuota lo stato di editing
          break;
        case 2:
          title = 'Account';
          break;
      }
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0563EC),
        foregroundColor: Colors.white,
        elevation: 10,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0563EC), Color(0xFF0277BD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _sections[_selectedIndex], // Non usare IndexedStack, usa direttamente l'elemento
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0563EC),
        selectedItemColor: Colors.black54,
        unselectedItemColor: Colors.white,
        elevation: 20,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list_rounded),
            label: 'Elenco Turni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Aggiungi Turni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}

