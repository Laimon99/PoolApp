import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  var _enteredMail = '';
  var _enteredPassword = '';
  var _enteredFirstName = '';
  var _enteredLastName = '';
  final _selectedBrevetti = {
    'BrevettoAB': false,
    'BrevettoIstruttore': false,
    'BrevettoAiutoAllenatore': false,
    'BrevettoNeonatale': false,
    'BrevettoFitness': false,
    'BrevettoSportAcqua': false,
  };

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    try {
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
          email: _enteredMail,
          password: _enteredPassword,
        );
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
          email: _enteredMail,
          password: _enteredPassword,
        );
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'nome': _enteredFirstName,
          'cognome': _enteredLastName,
          'email': _enteredMail,
          ..._selectedBrevetti,
          'coordinatore': false,
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Errore di autenticazione'), backgroundColor: Colors.red,),
      );
    }
  }

  String _addSpace(String input) {
    return input.replaceAllMapped(
      RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF0563EC),],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.05),
                  Text(
                    'Benvenuto in Pool App',
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Card(
                    color: const Color(0xFFFFFFFF),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/PA.png',
                              scale: screenWidth / 100,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            if (!_isLogin)
                              _buildTextField(
                                label: 'Nome',
                                onSaved: (value) => _enteredFirstName = value!,
                              ),
                            if (!_isLogin)
                              _buildTextField(
                                label: 'Cognome',
                                onSaved: (value) => _enteredLastName = value!,
                              ),
                            _buildTextField(
                              label: 'Email',
                              onSaved: (value) => _enteredMail = value!,
                            ),
                            _buildTextField(
                              label: 'Password',
                              obscureText: true,
                              onSaved: (value) => _enteredPassword = value!,
                            ),
                            if (!_isLogin) ...[
                              SizedBox(height: screenHeight * 0.02),
                              const Text(
                                'Seleziona i Brevetti:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isLandscape ? 3 : 2,
                                  childAspectRatio: screenWidth / screenHeight * 4,
                                  crossAxisSpacing: screenWidth * 0.03,
                                  mainAxisSpacing: screenHeight * 0.01,
                                ),
                                itemCount: _selectedBrevetti.keys.length,
                                itemBuilder: (context, index) {
                                  final key = _selectedBrevetti.keys.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedBrevetti[key] = !_selectedBrevetti[key]!;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedBrevetti[key]! ? Colors.blue : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Center(
                                        child: Text(
                                          key == 'BrevettoAB' ? 'Brevetto AB' : _addSpace(key),
                                          style: TextStyle(
                                            color: _selectedBrevetti[key]! ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                            SizedBox(height: screenHeight * 0.03),
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.1,
                                  vertical: screenHeight * 0.02,
                                ),
                                backgroundColor: const Color(0xFF0563EC),
                              ),
                              child: Text(
                                _isLogin ? 'Login' : 'Registrati',
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(
                                _isLogin
                                    ? 'Crea un nuovo account'
                                    : 'Hai già un account?',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    bool obscureText = false,
    required void Function(String?) onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        obscureText: obscureText,
        onSaved: onSaved,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Questo campo è obbligatorio';
          }
          return null;
        },
      ),
    );
  }
}
