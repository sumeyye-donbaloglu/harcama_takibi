import 'package:flutter/foundation.dart';
import '../models/money_transaction.dart';
import '../services/transaction_service.dart';
import 'dart:async'; //stream kullanabilmek için

class TransactionProvider extends ChangeNotifier {
  //burada extends changenotifier yapmamızın sebebi sınıfa değişiklikleri bildirme yeteneği kazandırmak.
  final TransactionService _service;
  StreamSubscription<List<MoneyTransaction>>? _subscription;

  TransactionProvider({required TransactionService service})
    : _service = service {
    //dışarıdan gelen servis değerini bu nesnenin _service alanına koy
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  final List<MoneyTransaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<MoneyTransaction> get transactions {
    return List.unmodifiable(_transactions);
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int totalMinorFor(TransactionType type, {String? excludeId}) {
    //isteğe bağlı parametre {} ile yazılır. String? ->değer verilmezse null olabilir demek
    //listedeki gelir ve giderleri toplar
    int total = 0;
    for (final transaction in _transactions) {
      if (transaction.type == type && transaction.id != excludeId) {
        total = total + transaction.amountMinor;
      }
    } //bu fonksiyonda excludeid toplama eklemek istemediğimiz kayıt yani güncellenen kayıt

    return total;
  }

  Future<String> addTransaction(MoneyTransaction transaction) {
    return _service.addTransaction(transaction);
  }

  Future<void> updateTransaction(MoneyTransaction transaction) {
    return _service.updateTransaction(transaction);
  } //isteği servise gönderiyoruz. provider sadece servisle iletişim kurar.

  Future<void> deleteTransaction(String id) {
    return _service.deleteTransaction(id);
  }

  void _onTransactionsReceived(List<MoneyTransaction> transactions) {
    _transactions.clear();
    _transactions.addAll(transactions);

    _isLoading = false;
    _errorMessage = null;

    notifyListeners(); //veriler değişti diye haber veriyoruz.
  }

  void _startListening() {
    _subscription = _service.watchTransactions().listen(
      _onTransactionsReceived,
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'İşlemler yüklenemedi.';
        notifyListeners();
      },
    );
  }
}
