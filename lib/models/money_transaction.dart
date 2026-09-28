enum TransactionType {
  income, //gelir
  expense, //gider
}

class MoneyTransaction {
  final String id;
  final int amountMinor;
  final TransactionType type;
  final DateTime date;
  final String category;
  final String description;

  MoneyTransaction({
    //kurucu metot
    required this.id,
    required this.amountMinor,
    required this.type,
    required this.date,
    required this.category,
    required this.description,
  });
}
