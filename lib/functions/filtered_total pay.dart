double filteredTotalPay(List<Map<String, dynamic>> turni) {
  double compensoTotale = 0.0;

  for (var turno in turni) {
    compensoTotale += turno['pay'] ?? 0.0;  // Aggiungi il compenso se presente
  }

  return compensoTotale;
}
