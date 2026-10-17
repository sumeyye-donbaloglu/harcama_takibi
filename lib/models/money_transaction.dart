import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() {
    //mapi kullanma amacımız firestore a hangi alanlar ve değerler gönderileceğini belirlemek
    return {
      'amountMinor': amountMinor,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'category': category,
      'description': description,
    }; //yani amountminor adında bir alan olsun ve ona amountminor değişkeninin değerini ver
  }

  factory MoneyTransaction.fromMap(String id, Map<String, dynamic> data) {
    return MoneyTransaction(
      id: id,
      amountMinor: data['amountMinor'] as int,
      type: TransactionType.values.byName(data['type'] as String),
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] as String,
      description: data['description'] as String,
    );
  }
}
