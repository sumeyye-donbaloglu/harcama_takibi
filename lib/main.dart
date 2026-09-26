import 'package:flutter/material.dart';

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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Harcama Takibi'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<MoneyTransaction> _transactions = [];

  final List<String> _expenseCategories = [
    'Market',
    'Yeme-İçme',
    'Ulaşım',
    'Ev/Faturalar',
    'Abonelik',
    'Sağlık',
    'Alışveriş',
    'Diğer',
  ];

  final List<String> _incomeCategories = ['Maaş', 'Ek Gelir', 'Diğer'];

  String _selectedCategory = 'Diğer';

  int _nextTransactionId = 1; //bu sayaç kayıtlara kimlik verecek

  final _amountController = TextEditingController();

  @override //dispose metodu controllerı temizler. controllerı oluşturduğumuz sınıfa yazarız.
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int _totalMinorFor(TransactionType type) {
    int total = 0;
    for (final transaction in _transactions) {
      if (transaction.type == type) {
        total = total + transaction.amountMinor;
      }
    }

    return total;
  }

  void _showTransactionForm() {
    TransactionType selectedType = TransactionType.expense;
    String? errorText;
    _selectedCategory = 'Diğer';
    _amountController.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            List<String> categories = _expenseCategories;

            if (selectedType == TransactionType.income) {
              categories = _incomeCategories;
            }
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'İşlem Ekle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TransactionType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'İşlem türü',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TransactionType.income,
                          child: Text('Gelir'),
                        ),
                        DropdownMenuItem(
                          value: TransactionType.expense,
                          child: Text('Gider'),
                        ),
                      ],
                      onChanged: (TransactionType? value) {
                        if (value == null) {
                          return;
                        }

                        setSheetState(() {
                          selectedType = value;
                          _selectedCategory = 'Diğer';
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tutar',
                        hintText: '250,00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedType),
                      initialValue: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final category in categories)
                          DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }

                        setSheetState(() {
                          _selectedCategory = value;
                        });
                      },
                    ), // Kategori menüsü burada bitti.
                    const SizedBox(height: 16),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        final error = _addTransaction(selectedType);

                        if (error != null) {
                          setSheetState(() {
                            errorText = error;
                          });
                          return;
                        }

                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Ekle'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _addTransaction(TransactionType type) {
    final amountText = _amountController.text.trim();
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
    //son durumda şçyle wholemount=50 tl,fractionminor=50 kuruş

    final amountMinor = wholeAmount * 100 + fractionMinor;
    //kuruş cinsinden amountminoru hesapladık

    //amountminor 0 olamaz ama
    if (amountMinor <= 0) {
      return 'Tutar sıfırdan büyük olmalı.';
    }

    //gider sınırı ekledik 99999999999
    final currentExpenseMinor = _totalMinorFor(type);

    if (amountMinor > 99999999999 - currentExpenseMinor) {
      return 'Bu işlem türünün toplam sınırı aşılacağı için eklenemedi.';
    }

    String category = _selectedCategory;
    String description = 'Gider';

    if (type == TransactionType.income) {
      description = 'Gelir';
    }

    final newTransaction = MoneyTransaction(
      id: 'islem-$_nextTransactionId',
      amountMinor: amountMinor,
      type: type,
      date: DateTime.now(),
      category: category,
      description: description,
    );

    setState(() {
      _transactions.add(newTransaction);
      _nextTransactionId = _nextTransactionId + 1;
      //setstate durumun değiştiğini bildiriyo fluttera ekran yeniden oluşsun istiyo
    });

    _amountController.clear(); // eklenen giderin controllerini temizliyoruz
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
