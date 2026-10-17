import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/money_transaction.dart';

class TransactionService {
  final String userId;

  TransactionService({required this.userId});

  CollectionReference<Map<String, dynamic>> get _transactionsRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  Future<String> addTransaction(MoneyTransaction transaction) async {
    final documentRef = await _transactionsRef.add(
      transaction.toMap(),
    ); //bu metot firestore a veri ekler.

    return documentRef.id;
  }

  Stream<List<MoneyTransaction>> watchTransactions() {
    return _transactionsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((document) {
        return MoneyTransaction.fromMap(document.id, document.data());
      }).toList();
    });
  }

  Future<void> updateTransaction(MoneyTransaction transaction) async {
    await _transactionsRef.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }
}
