// ✅ FILE: turn_list.dart aggiornato per Turn con fromJson
import 'package:flutter/material.dart';
import 'package:pool_app/models/turn.dart';
import 'package:pool_app/functions/fetch_turni.dart';
import 'package:pool_app/widget/filter_widgets/filters_drawer.dart';
import 'package:pool_app/widgets/turn_tile.dart';

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
      /// usa la data “pura” (senza orario)
      final shiftDate = turno.date;
      return shiftDate.month == _selectedDate.month &&
          shiftDate.year  == _selectedDate.year &&
          (_selectedPiscina == 'Tutte' || turno.poolId == _selectedPiscina) &&
          (_selectedRole   == 'Tutti' || turno.role   == _selectedRole);
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
                child: Row(
                  children: [
                    Text('Compenso totale:  '),
                    SizedBox(
                      width: 15.0,
                      height: 15.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ],
                ),
              );
            } // ...
            else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final filtered = _filterTurni(snapshot.data!);

              // ► NUOVO calcolo: somma i totalPay di ogni turno
              compensoTotale = filtered.fold(0.0, (sum, t) => sum + t.totalPay);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 20,
                ),
                child: Text(
                  'Compenso totale:  ${compensoTotale.toStringAsFixed(2)}€',
                ),
              );
            } else {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
                child: Text('Compenso totale: 0.00€'),
              );
            }
          },
        ),
        actions: [
          IconButton(
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
            filtered.sort((a, b) => a.start.compareTo(b.start));
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
                    widget.onEditRequested(
                      turn,
                    ); // esegue la logica di modifica (es: cambia tab)
                    await Future.delayed(
                      const Duration(milliseconds: 300),
                    ); // evita race condition
                    setState(() {
                      _turniFuture = fetchTurni(); // forza il refetch
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
