import 'package:flutter/material.dart';
import '../models/money_transaction.dart';
import '../widgets/transaction_form.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
  //bu satır şu demek: bu ekranın değişebilen durumunu _myhomepagestate yönetecek demek
}

class _MyHomePageState extends State<MyHomePage> {
  final List<MoneyTransaction> _transactions = [];

  int _nextTransactionId = 1; //bu sayaç kayıtlara kimlik verecek

  int _totalMinorFor(TransactionType type, {String? excludeId}) {
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

  void _showTransactionForm({MoneyTransaction? transaction}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return TransactionForm(
          transaction: transaction,
          onDelete: transaction == null
              ? null
              : () {
                  _deleteTransaction(transaction.id);
                },
          onSave: (type, amountInput, category,date) {
            return _saveTransaction(
              type,
              amountInput,
              category,
              date,
              existingTransaction: transaction,
            );
          },
        );
      },
    );
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((transaction) => transaction.id == id);
    });
  }

  String? _saveTransaction(
    //ekleme ve düzenlemeyi burada yöneticem
    TransactionType type,
    String amountInput,
    String category, 
    DateTime date, {
    MoneyTransaction? existingTransaction, //düzenlenen eski kayıt
  }) {
    //Düzenlenecek kayıtı bulalım
    int existingIndex = -1; //düzenlenecek kaydın numarası

    if (existingTransaction != null) {
      existingIndex = _transactions.indexWhere(
        (transaction) => transaction.id == existingTransaction.id,
      );

      if (existingIndex == -1) {
        return 'Düzenlenecek kayıt bulunamadı.';
      }
    }

    final amountText = amountInput.trim();
    if (amountText.isEmpty) {
      return "Lütfen bir tutar girin";
    }
    final isValidAmount = RegExp(
      r'^[0-9]+([.,][0-9]{1,2})?$',
    ).hasMatch(amountText);

    if (!isValidAmount) {
      return "Tutarı arada boşluk olmadan, en fazla iki ondalık basamakla girin. Örnek: 50,25";
    }
    final normalizedAmount = amountText.replaceAll(
      ',',
      '.',
    ); //virgülü noktaya çevirsin diye
    final parts = normalizedAmount.split(
      '.',
    ); //splitle metin listesi olur 50.25= ["50","25"]
    final wholeAmount = int.tryParse(
      parts[0],
    ); //parts 0 ı tam sayı olarak alıyor.

    //ama eğer tam sayı çok büyükse int e sığmayabilir.bunun için;
    if (wholeAmount == null) {
      return 'Tutar çok büyük. Daha küçük bir tutar girin.';
    }

    //tutara sınır koyuyoruz.
    if (wholeAmount > 999999999) {
      return 'Tutar en fazla 999.999.999,99 olabilir.';
    }

    String fractionText = '0';
    if (parts.length == 2) {
      //ondalıklı sayıysa girilen tutar
      fractionText =
          parts[1]; //50,5 ise tutar parts[1]=5 oluyor fractionText yani ama biz 50 kuruş olsun istiyoruz.
    }

    fractionText = fractionText.padRight(
      2,
      '0',
    ); //metin iki karakterdeb kısaysa sağına sıfır ekle demek.

    final fractionMinor = int.parse(fractionText);
    //son durumda şöyle wholemount=50 tl,fractionminor=50 kuruş

    final amountMinor = wholeAmount * 100 + fractionMinor;
    //kuruş cinsinden amountminoru hesapladık

    //amountminor 0 olamaz ama
    if (amountMinor <= 0) {
      return 'Tutar sıfırdan büyük olmalı.';
    }

    //gider sınırı ekledik 99999999999
    final otherTotalMinor = _totalMinorFor(
      type,
      excludeId: existingTransaction?.id,
    );

    if (amountMinor > 99999999999 - otherTotalMinor) {
      return 'Bu işlem türünün toplam sınırı aşılacağı için eklenemedi.';
    }

    String description = 'Gider';

    if (type == TransactionType.income) {
      description = 'Gelir';
    }

    final newTransaction = MoneyTransaction(
      id: existingTransaction?.id ?? 'islem-$_nextTransactionId',
      amountMinor: amountMinor,
      type: type,
      date: date,
      category: category,
      description: description,
    );

    setState(() {
      if (existingTransaction == null) {
        //yeni eklenen kayıtsa
        _transactions.add(newTransaction);
        _nextTransactionId = _nextTransactionId + 1;
      } else {
        _transactions[existingIndex] = newTransaction; //düzenlenecek kayıtsa
      }
      //setstate durumun değiştiğini bildiriyo fluttera ekran yeniden oluşsun istiyo
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final incomeMinor = _totalMinorFor(TransactionType.income);
    final expenseMinor = _totalMinorFor(TransactionType.expense);
    final remainingMinor = incomeMinor - expenseMinor;

    final sortedTransactions = List<MoneyTransaction>.of(_transactions);

    sortedTransactions.sort((first, second) {
      return second.date.compareTo(
        first.date,
      ); //eklenen kayıtları date e göre sıralıyor
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showTransactionForm,
        tooltip: 'İşlem ekle',
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Kalan Tutar', textAlign: TextAlign.center),
                      Text(
                        '${(remainingMinor / 100).toStringAsFixed(2)} TL',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          Text(
                            'Gelir: ${(incomeMinor / 100).toStringAsFixed(2)} TL',
                          ),
                          Text(
                            'Gider: ${(expenseMinor / 100).toStringAsFixed(2)} TL',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 24),
              const Text(
                'İşlemler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_transactions.isEmpty) const Text('Henüz işlem eklenmedi.'),

              for (int i = 0; i < sortedTransactions.length; i++)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (i == 0 ||
                        !DateUtils.isSameDay(
                          sortedTransactions[i].date,
                          sortedTransactions[i - 1].date,
                        ))
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          '${sortedTransactions[i].date.day}.'
                          '${sortedTransactions[i].date.month}.'
                          '${sortedTransactions[i].date.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Card(
                      child: ListTile(
                        onTap: () {
                          //on tap dokununca çalışan fonku çalıştırır.fonk adı yok ama burda
                          _showTransactionForm(
                            transaction: sortedTransactions[i],
                          );
                        },

                        title: Text(sortedTransactions[i].category),
                        subtitle: Text(sortedTransactions[i].description),
                        trailing: Text(
                          '${(sortedTransactions[i].amountMinor / 100).toStringAsFixed(2)} TL',
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
