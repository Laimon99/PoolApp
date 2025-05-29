import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pool_app/functions/delete_turn.dart';
import 'package:pool_app/widget/filter_widgets/filters_drawer.dart';
import '../functions/fetch_turni.dart';
import '../functions/filtered_total pay.dart';

class TurnList extends StatefulWidget {
  const TurnList({super.key});

  @override
  _TurnListState createState() => _TurnListState();
}

class _TurnListState extends State<TurnList> {
  late Future<List<Map<String, dynamic>>> _turniFuture;
  DateTime _selectedDate = DateTime.now();
  String _selectedPiscina = 'Tutte';
  String _selectedRole = 'Tutti';
  double compensoTotale = 0.0; // Inizializza compensoTotale a 0.0
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _turniFuture =
        fetchTurni(); // Inizializza il future al caricamento iniziale
  }

  final Map<String, String> _italianDaysOfWeek = {
    'Monday': 'Luned\u00ec',
    'Tuesday': 'Marted\u00ec',
    'Wednesday': 'Mercoled\u00ec',
    'Thursday': 'Gioved\u00ec',
    'Friday': 'Venerd\u00ec',
    'Saturday': 'Sabato',
    'Sunday': 'Domenica',
  };

  String _formatTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String formatDate(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    String dayOfWeek = DateFormat('EEEE').format(dateTime);
    String italianDay = _italianDaysOfWeek[dayOfWeek] ?? dayOfWeek;
    return '$italianDay ${dateTime.day}';
  }

  List<Map<String, dynamic>> _filterTurni(List<Map<String, dynamic>> turni) {
    return turni.where((turno) {
      DateTime turnoDate = DateTime.parse(turno['date']);

      // Filtro per mese e anno
      bool isDateMatch = turnoDate.month == _selectedDate.month &&
          turnoDate.year == _selectedDate.year;

      // Filtro per piscina se non è 'Tutte'
      bool isPiscinaMatch = _selectedPiscina == 'Tutte' || turno['piscina'] == _selectedPiscina;

      // Filtro per ruolo se non è 'Tutti'
      bool isRoleMatch = _selectedRole == 'Tutti' || turno['role'] == _selectedRole;

      return isDateMatch && isPiscinaMatch && isRoleMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: FutureBuilder<List<Map<String, dynamic>>>(
          future: _turniFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
                child: Row(
                  children: [
                    Text('Compenso totale:  '),
                    SizedBox(
                      width: 15.0, // Larghezza
                      height: 15.0, // Altezza
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0, // Spessore dell'anello
                      ),
                    )
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Row(
                children: [
                  const Text('Compenso totale:  '),
                  Text('Errore: ${snapshot.error}'),
                ],
              );
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final turni = snapshot.data!;
              final filteredTurni = _filterTurni(turni);
              compensoTotale =
                  filteredTotalPay(filteredTurni); // Calcola il compenso totale

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
                child: Text(
                    'Compenso totale:  ${compensoTotale.toStringAsFixed(2)}'),
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
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer(); // Apre il Drawer
            },
          ),
        ],
      ),
      endDrawer: FiltersDrawer(
        selectedDate: _selectedDate,
        onDateSelected: (newDate) {
          setState(() {
            _selectedDate = newDate;
            _turniFuture = fetchTurni(); // Ricarica i turni con la nuova data
          });
        },
        onPiscinaSelected: (String newPiscina) {
          setState(() {
            _selectedPiscina = newPiscina;
            _turniFuture = fetchTurni(); // Ricarica i turni con la nuova data
          });
        },
        onRoleSelected: (String newRole) {
          setState(() {
            _selectedRole = newRole;
            _turniFuture = fetchTurni(); // Ricarica i turni con la nuova data
          });
        },
        selectedPiscina: _selectedPiscina,
        selectedRole: _selectedRole,
      ),
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.02),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [],
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            // Secondo FutureBuilder per ottenere i turni
            future: _turniFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Errore: ${snapshot.error}'),
                );
              } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Nessun turno trovato.'),
                );
              } else if (snapshot.hasData) {
                final turni = snapshot.data!;
                final filteredTurni = _filterTurni(turni);

                filteredTurni.sort((a, b) {
                  final dateTimeA = DateTime.parse(a['date']);
                  final dateTimeB = DateTime.parse(b['date']);
                  int dateComparison = dateTimeA.compareTo(dateTimeB);

                  if (dateComparison == 0) {
                    final startTimeA = DateTime.parse(a['start_time']);
                    final startTimeB = DateTime.parse(b['start_time']);
                    return startTimeA.compareTo(startTimeB);
                  }
                  return dateComparison;
                });

                return Expanded(
                  child: ListView.builder(
                    itemCount: filteredTurni.length,
                    itemBuilder: (context, index) {
                      final turno = filteredTurni[index];
                      return Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: Dismissible(
                          key: Key(turno['id'].toString()),  // Usa un identificatore unico per ogni item
                          direction: DismissDirection.startToEnd, // Abilita lo scorrimento orizzontale
                          onDismissed: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                              try{
                                await deleteTurno(turno);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Turno eliminato con successo')),
                                );
                              }catch (e) {
                                // Gestisci eventuali errori
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Errore durante l\'eliminazione del turno')),
                                );
                              }
                            }
                          },
                          background: Container(
                            color: Colors.red, // Colore di sfondo quando si scorre verso sinistra
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Icon(
                                  Icons.delete, // Icona di eliminazione
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          child: Card(
                            color: const Color(0xFF0563EC),
                            shadowColor: const Color(0xFF0563EC),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.015,
                              ),
                              title: Text(
                                '${formatDate(turno['date'])}\nOre: ${_formatTime(turno['start_time'])} - ${_formatTime(turno['end_time'])}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              subtitle: Text(
                                'Ruolo: ${(turno['role'][0].toUpperCase())}${(turno['role'].substring(1).toLowerCase())}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.04,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${turno['piscina']}',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'Compenso: ${(turno['pay']).toStringAsFixed(2)}€',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.03,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Hai selezionato il turno ${index + 1}'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
