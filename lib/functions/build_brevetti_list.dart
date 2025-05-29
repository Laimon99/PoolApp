List<String> buildBrevettiList(Map<String, dynamic> userData) {
  // Ottieni la lista di brevetti dai dati utente
  final List<String> brevetti = [];

  // Verifica i brevetti disponibili nel documento utente
  if (userData['BrevettoAB'] == true) brevetti.add('AB');
  if (userData['BrevettoIstruttore'] == true) brevetti.add('BrevettoIstruttore');
  if (userData['BrevettoAiutoAllenatore'] == true) brevetti.add('BrevettoAiutoAllenatore');
  if (userData['BrevettoNeonatale'] == true) brevetti.add('BrevettoNeonatale');
  if (userData['BrevettoFitness'] == true) brevetti.add('BrevettoFitness');
  if (userData['BrevettoSportAcqua'] == true) brevetti.add('BrevettoSportAcqua');

  return brevetti;
}