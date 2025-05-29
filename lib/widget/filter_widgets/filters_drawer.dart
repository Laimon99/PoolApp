import 'package:flutter/material.dart';
import '../../functions/get_piscine.dart';
import '../../functions/get_roles.dart';
import 'filter_option.dart';

class FiltersDrawer extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedPiscina;
  final String selectedRole;
  final Function(DateTime) onDateSelected;
  final Function(String) onPiscinaSelected;
  final Function(String) onRoleSelected;

  const FiltersDrawer({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.selectedPiscina,
    required this.selectedRole,
    required this.onPiscinaSelected,
    required this.onRoleSelected,
  });

  @override
  _FiltersDrawerState createState() => _FiltersDrawerState();
}

class _FiltersDrawerState extends State<FiltersDrawer> {
  bool _isMonthSelectorVisible = false;
  bool _isYearSelectorVisible = false;
  bool _isPoolSelectorVisible = false;
  bool _isRoleSelectorVisible = false;

  List<String> piscine = ['Tutte'];
  List<String> roles = ['Tutti'];

  final List<String> months = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre'
  ];

  final List<String> years = ['2021', '2022', '2023', '2024', '2025', '2026'];
  Future<void> fetchData() async {
    List<String> fetchedPiscine = await getPiscine();
    List<String> fetchedRoles = await getRoles();

    setState(() {
      piscine.addAll(fetchedPiscine);  // Aggiungi i dati alla lista esistente
      roles.addAll(fetchedRoles);      // Aggiungi i dati alla lista esistente
    });
  }


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'Filtri',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            FilterOption(
              label: "Seleziona mese",
              value: months[widget.selectedDate.month - 1],
              isVisible: _isMonthSelectorVisible,
              onToggle: () {
                setState(() {
                  _isMonthSelectorVisible = !_isMonthSelectorVisible;
                });
              },
              itemCount: months.length,
              itemBuilder: (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    widget.onDateSelected(
                      DateTime(widget.selectedDate.year, index + 1),
                    );
                    _isMonthSelectorVisible = false;
                  });
                },
                child: Center(
                  child: Text(
                    months[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            FilterOption(
              label: "Seleziona anno",
              value: widget.selectedDate.year.toString(),
              isVisible: _isYearSelectorVisible,
              onToggle: () {
                setState(() {
                  _isYearSelectorVisible = !_isYearSelectorVisible;
                });
              },
              itemCount: years.length,
              itemBuilder: (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    widget.onDateSelected(
                      DateTime(
                          int.parse(years[index]), widget.selectedDate.month),
                    );
                    _isYearSelectorVisible = false;
                  });
                },
                child: Center(
                  child: Text(
                    years[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            FilterOption(
              label: 'Seleziona piscina',
              value: widget.selectedPiscina, // Sostituisci con il valore attuale selezionato
              isVisible: _isPoolSelectorVisible,
              onToggle: () {
                setState(() {
                  _isPoolSelectorVisible = !_isPoolSelectorVisible;
                });
              },
              itemCount: piscine.length,
              itemBuilder: (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    widget.onPiscinaSelected(piscine[index]);
                    _isPoolSelectorVisible = false;
                  });
                },
                child: Center(
                  child: Text(
                    piscine[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            FilterOption(
              label: 'Seleziona Ruolo',
              value: widget.selectedRole, // Sostituisci con il valore attuale selezionato
              isVisible: _isRoleSelectorVisible,
              onToggle: () {
                setState(() {
                  _isRoleSelectorVisible = !_isRoleSelectorVisible;
                });
              },
              itemCount: roles.length,
              itemBuilder: (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    widget.onRoleSelected(roles[index]);
                    _isRoleSelectorVisible = false;
                  });
                },
                child: Center(
                  child: Text(
                    roles[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
