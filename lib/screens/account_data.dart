import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/build_brevetti_list.dart';
import '../functions/fetch_user_data.dart';

class AccountData extends StatefulWidget {
  const AccountData({super.key});

  @override
  State<AccountData> createState() => _AccountDataState();
}

class _AccountDataState extends State<AccountData> {
  bool isMen = true;

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout effettuato con successo')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserData(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Errore: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Nessun dato trovato'));
          }

          final userData = snapshot.data!;

          return Column(
            children: [
              // Header con immagine e dettagli utente
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/poolBG.jpg'),
                    fit: BoxFit.cover,
                  ),
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  children: [
                    GestureDetector(
                      child: CircleAvatar(
                        radius: screenWidth * 0.1,
                        foregroundImage: AssetImage(isMen
                            ? 'assets/images/profile man.png'
                            : 'assets/images/profile women.png'),
                      ),
                      onTap: () {
                        setState(() {
                          isMen = !isMen;
                        });
                      },
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      '${userData['nome']} ${userData['cognome']}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      userData['email'],
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Lista brevetti
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: const Text(
                  'Brevetti:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.01,
                  ),
                  itemCount: buildBrevettiList(userData).length,
                  itemBuilder: (context, index) {
                    final brevetto = buildBrevettiList(userData)[index];
                    return ListTile(
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green),
                      title: Text(
                        brevetto,
                        style: TextStyle(fontSize: screenWidth * 0.045),
                      ),
                    );
                  },
                ),
              ),

              // Logout button
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF0563EC),
                    foregroundColor: Colors.white,
                    onPressed: () async {
                      bool? confirmLogout = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Conferma Logout'),
                            content: const Text(
                                'Sei sicuro di voler effettuare il logout?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Annulla'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Conferma'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmLogout == true) {
                        await _logout(context);
                      }
                    },
                    child: const Icon(Icons.logout),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
