import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../functions/add_turn.dart';
import '../functions/build_brevetti_list.dart';
import '../functions/fetch_user_data.dart';
import '../functions/get_piscine.dart';
import '../functions/get_roles.dart';
import 'dart:developer' as dev;


class NewTurn extends StatefulWidget {
  const NewTurn({super.key});

  @override
  _NewTurnState createState() => _NewTurnState();
}

class _NewTurnState extends State<NewTurn> {
  final _formKey = GlobalKey<FormState>();

  String? selectedRole;
  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  List<String> selectedCertificates = [];
  String? selectedPiscina;
  bool _isRoleSelectorVisible = false;
  bool _isPiscinaSelectorVisible = false;

  bool showValidationErrors = false;

  final certificates = [
    'ab',
    'istruttore',
    'aiut allenatore',
    'fitness',
    'sport acqua',
    'neonatale',
    'accoglienza'
  ];

  List<String> piscine = [];
  List<String> roles = [];

  final Map<String, String> _italianDaysOfWeek = {
    'Monday': 'Lunedì',
    'Tuesday': 'Martedì',
    'Wednesday': 'Mercoledì',
    'Thursday': 'Giovedì',
    'Friday': 'Venerdì',
    'Saturday': 'Sabato',
    'Sunday': 'Domenica',
  };

  Future<void> fetchData() async {
    List<String> fetchedPiscine = await getPiscine();
    List<String> fetchedRoles = await getRoles();
    setState(() {
      piscine = fetchedPiscine;
      roles = fetchedRoles;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String _formatDate(DateTime dateTime) {
    String dayOfWeek = DateFormat('EEEE').format(dateTime);
    String italianDay = _italianDaysOfWeek[dayOfWeek] ?? dayOfWeek;
    return '$italianDay ${dateTime.day}';
  }

  bool isLoading = false;

  void _addTurn() {
    setState(() {
      showValidationErrors = true;
    });

    bool isValid = _formKey.currentState!.validate();

    if (isValid &&
        selectedDate != null &&
        selectedStartTime != null &&
        selectedEndTime != null) {
      AddTurn.add(
        context: context,
        selectedRole: selectedRole,
        selectedPiscina: selectedPiscina,
        selectedDate: selectedDate,
        selectedStartTime: selectedStartTime,
        selectedEndTime: selectedEndTime,
        selectedCertificates: selectedCertificates,
        setLoading: (bool value) {
          setState(() {
            isLoading = value;
          });
        },
        resetForm: () {
          setState(() {
            selectedRole = null;
            selectedDate = null;
            selectedStartTime = null;
            selectedEndTime = null;
            selectedCertificates.clear();
            selectedPiscina = null;
            showValidationErrors = false;
          });
        },
      );
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (selectedStartTime ?? TimeOfDay.now())
          : (selectedEndTime ?? TimeOfDay.now()),
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          selectedStartTime = pickedTime;
        } else {
          selectedEndTime = pickedTime;
        }
      });
    }
  }

  Future<double> _calculateTotalPay() async {
    if (selectedRole == null ||
        selectedStartTime == null ||
        selectedEndTime == null) {
      return 0;
    }

    // Durata turno -------------------------------------------------------------
    final startTime = AddTurn.timeOfDayToDateTime(selectedStartTime!);
    final endTime   = AddTurn.timeOfDayToDateTime(selectedEndTime!);
    final durationInHours = endTime.difference(startTime).inMinutes / 60.0;

    //-------------------- DEBUG: cosa arriva fin qui ---------------------------
    dev.log('▶ role = $selectedRole');
    dev.log('▶ certificati utente = $selectedCertificates');
    dev.log('▶ durata (h) = $durationInHours');
    //--------------------------------------------------------------------------

    // Paghe --------------------------------------------------------------------
    double finalPay   = 0;    // valore che tornerai
    double defaultPay = 0;    // basepay

    // 2️⃣ leggi il documento «roles/<selectedRole>»
    final roleSnap = await FirebaseFirestore.instance
        .collection('roles')
        .doc(selectedRole)          // ← deve esistere!
        .get();

    if (!roleSnap.exists) {
      dev.log('⛔ Il documento roles/$selectedRole NON esiste');
      return 0;
    }

    final data = roleSnap.data()!;
    defaultPay = (data['basepay'] as num).toDouble();
    // --------------------------------------------------------------------
    // 3️⃣ scorri TUTTE le conditions e prendi la tariffa più alta che ti spetta
    finalPay = defaultPay;   // partiamo dalla basepay

    // 3️⃣ scorri le conditions
    for (final cond in (data['conditions'] as List<dynamic>)) {
      // estrai campi
      final reqCert = (cond['requiredCertificate'] as String).trim();
      final pay     = (cond['pay'] as num).toDouble();

      dev.log('🔍 condizione → reqCert=$reqCert  pay=$pay');

      if (selectedCertificates.contains(reqCert) && pay > finalPay) {
        finalPay = pay;
      }
    }

    // Se nessuna condizione ha fatto match, resta la basepay
    if (finalPay == 0) {
      dev.log('⚠ Nessun match: rimane basepay=$defaultPay');
      finalPay = defaultPay;
    }

    // 4️⃣ calcolo finale
    final totale = finalPay * durationInHours;
    dev.log('💰 paga oraria scelta = $finalPay   → Totale = $totale');
    return totale;
  }
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder(
      future: fetchUserData(),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Errore: ${snapshot.error}')),
          );
        }

        final userData = snapshot.data;
        selectedCertificates = buildBrevettiList(userData!);

        return Scaffold(
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: screenHeight * 0.1),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isPiscinaSelectorVisible = true;
                                          });
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.02,
                                            vertical: screenHeight * 0.01,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Colors.black.withOpacity(0.1),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.04,
                                              vertical: screenHeight * 0.015,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  selectedPiscina ?? 'Piscina',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_drop_down,
                                                    color: Colors.black87),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isRoleSelectorVisible = true;
                                          });
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.02,
                                            vertical: screenHeight * 0.01,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Colors.black.withOpacity(0.1),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.04,
                                              vertical: screenHeight * 0.015,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  selectedRole ?? 'Ruolo',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_drop_down,
                                                    color: Colors.black87),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.03),
                                  Center(
                                    child: GestureDetector(
                                      onTap: _pickDate,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.01,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.04,
                                            vertical: screenHeight * 0.015,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                selectedDate == null
                                                    ? 'Seleziona Data'
                                                    : 'Data: ${_formatDate(selectedDate!)}',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today, color: Colors.black87),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _pickTime(true),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.01,
                                              vertical: screenHeight * 0.01,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: screenWidth * 0.03,
                                                vertical: screenHeight * 0.015,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    selectedStartTime == null
                                                        ? 'Ora Inizio'
                                                        : 'Inizio: ${selectedStartTime!.format(context)}',
                                                    style: TextStyle(
                                                      fontSize: screenWidth * 0.04,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const Icon(Icons.access_time, color: Colors.black87),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _pickTime(false),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.01,
                                              vertical: screenHeight * 0.01,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: screenWidth * 0.04,
                                                vertical: screenHeight * 0.015,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    selectedEndTime == null
                                                        ? 'Ora Fine'
                                                        : 'Fine: ${selectedEndTime!.format(context)}',
                                                    style: TextStyle(
                                                      fontSize: screenWidth * 0.04,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const Icon(Icons.access_time, color: Colors.black87),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.05),
                                  Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.only(left: screenWidth * 0.02),
                                      child: FutureBuilder<double>(
                                        future:
                                            _calculateTotalPay(), // Chiamata al Future
                                        builder: (context, snapshot) {
                                          // Verifica lo stato del future
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator(); // Mostra l'indicatore di caricamento
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                'Errore: ${snapshot.error}');
                                          } else if (snapshot.hasData) {
                                            // Mostra il valore calcolato
                                            return Text(
                                              'Paga Totale: ${snapshot.data!.toStringAsFixed(2)}€',
                                              style: TextStyle(
                                                  fontSize: screenWidth * 0.045),
                                            );
                                          } else {
                                            return Text(
                                              'Paga Totale: 0.00€',
                                              style: TextStyle(
                                                  fontSize: screenWidth * 0.045),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.05),
                                  Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.1,
                                          vertical: screenHeight * 0.02,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        backgroundColor: const Color(0xFF0563EC),
                                      ),
                                      onPressed: _addTurn,
                                      child: Text(
                                        'Aggiungi Turno',
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isPiscinaSelectorVisible)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPiscinaSelectorVisible = false;
                            });
                          },
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Card(
                                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: piscine.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(
                                        piscine[index],
                                        style: TextStyle(fontSize: screenWidth * 0.045),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedRole = roles[index];
                                          _isRoleSelectorVisible = false;
                                        });
                                        dev.log('👆 Ruolo selezionato = $selectedRole');
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (_isRoleSelectorVisible)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRoleSelectorVisible = false;
                            });
                          },
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Card(
                                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: roles.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(
                                        roles[index] == 'sport_acqua'
                                            ? 'Sport d\'acqua'
                                            : roles[index].length <= 2
                                            ? roles[index].toUpperCase()
                                            : '${roles[index][0].toUpperCase()}${roles[index].substring(1).toLowerCase()}',
                                        style: TextStyle(fontSize: screenWidth * 0.045),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedRole = roles[index];
                                          _isRoleSelectorVisible = false;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
