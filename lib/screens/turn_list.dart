import 'package:flutter/material.dart';
import '../functions/fetch_turni.dart';
import '../models/turn.dart';
import '../widget/filter_widgets/filters_drawer.dart';
import '../widgets/turn_tile.dart';

class TurnList extends StatefulWidget {
  const TurnList({super.key, required this.onEditRequested});
  final void Function(Turn turn) onEditRequested;

  @override
  _TurnListState createState() => _TurnListState();
}

class _TurnListState extends State<TurnList> {
  late Future<List<Turn>> _turniFuture;
  DateTime _selectedDate = DateTime.now();
  String _selectedPiscina = 'Tutte';
  String _selectedRole = 'Tutti';
  double compensoTotale = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _turniFuture = fetchTurni();
  }

  List<Turn> _filterTurni(List<Turn> turni) {
    return turni.where((turno) {
      final shiftDate = turno.date;
      final stessaData = (shiftDate.year == _selectedDate.year) &&
          (shiftDate.month == _selectedDate.month);
      final stessaPiscina =
          _selectedPiscina == 'Tutte' || turno.poolId == _selectedPiscina;
      final stessoRuolo =
          _selectedRole == 'Tutti' || turno.role == _selectedRole;
      return stessaData && stessaPiscina && stessoRuolo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: FutureBuilder<List<Turn>>(
          future: _turniFuture,
          builder: (context, snapshot) {
            String label;
            if (snapshot.connectionState == ConnectionState.waiting) {
              label = 'Totale:  …';
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final filtered = _filterTurni(snapshot.data!);
              compensoTotale = filtered.fold(0.0, (sum, t) => sum + t.totalPay);
              label = 'Totale: ${compensoTotale.toStringAsFixed(2)}€';
            } else {
              label = 'Totale: 0.00€';
            }

            return Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(label),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // Pulsante di download PDF
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Scarica elenco turni',
            onPressed: () async {
              final snapshot = await _turniFuture;
              final filtered = _filterTurni(snapshot);
              filtered.sort((a, b) => a.date.compareTo(b.date));

              if (filtered.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nessun turno da esportare')),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('PDF salvato nei Download'),
                  backgroundColor: Colors.green,
                ),
              );
              ;
            },
          ),
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: FiltersDrawer(
        selectedDate: _selectedDate,
        selectedPiscina: _selectedPiscina,
        selectedRole: _selectedRole,
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
            _turniFuture = fetchTurni();
          });
        },
        onPiscinaSelected: (piscina) {
          setState(() {
            _selectedPiscina = piscina;
            _turniFuture = fetchTurni();
          });
        },
        onRoleSelected: (role) {
          setState(() {
            _selectedRole = role;
            _turniFuture = fetchTurni();
          });
        },
      ),
      body: FutureBuilder<List<Turn>>(
        future: _turniFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final filtered = _filterTurni(snapshot.data!);
            filtered.sort((a, b) => a.date.compareTo(b.date));

            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final turn = filtered[index];
                return TurnTile(
                  turn: turn,
                  onDeleted: () {
                    setState(() {
                      _turniFuture = fetchTurni();
                    });
                  },
                  editCallback: (turn) async {
                    widget.onEditRequested(turn);
                    await Future.delayed(const Duration(milliseconds: 300));
                    setState(() {
                      _turniFuture = fetchTurni();
                    });
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('Nessun turno trovato.'));
          }
        },
      ),
    );
  }
}
