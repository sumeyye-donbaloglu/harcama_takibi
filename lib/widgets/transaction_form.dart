import 'package:flutter/material.dart';
import '../models/money_transaction.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    required this.onSave,
    this.transaction,
    this.onDelete,
  });

  final VoidCallback?
  onDelete; //VoidCallback->parametre almayan ve sonuç döndürmeyen fonk demek
  final MoneyTransaction? transaction;

  final String? Function(
    TransactionType type,
    String amountInput,
    String category,
    DateTime date,
  )
  onSave;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  TransactionType selectedType = TransactionType.expense;
  String _selectedCategory = 'Diğer';
  DateTime _selectedDate = DateTime.now();
  String? errorText;

  final _amountController = TextEditingController();

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

  @override
  void initState() {
    //form açılırken içini hazırlıyor
    super.initState();

    final transaction = widget.transaction;

    if (transaction != null) {
      selectedType = transaction.type;
      _selectedCategory = transaction.category;
      _selectedDate = transaction.date;

      final wholeAmount = transaction.amountMinor ~/ 100;
      final fractionText = (transaction.amountMinor % 100).toString().padLeft(
        2,
        '0',
      );

      _amountController.text = '$wholeAmount,$fractionText';
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _confirmDelete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Kaydı sil'),
          content: const Text('Bu kaydı silmek istiyor musun?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    onDelete();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.transaction == null ? 'İşlem Ekle' : 'İşlem Düzenle',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _selectDate,
              child: Text(
                'Tarih: ${_selectedDate.day}.'
                '${_selectedDate.month}.'
                '${_selectedDate.year}',
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
                //kullanıcı menüden başka bir şey seçince çalışır
                if (value == null) {
                  return;
                }

                setState(() {
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

                setState(() {
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                final error = widget.onSave(
                  selectedType,
                  _amountController.text,
                  _selectedCategory,
                  _selectedDate,
                );

                if (error != null) {
                  setState(() {
                    errorText = error;
                  });
                  return;
                }

                Navigator.of(
                  context,
                ).pop(); //hata yoksa açılmış olan alt pencereyi kapatır
              },
              child: Text(widget.transaction == null ? 'Ekle' : 'Kaydet'),
            ),
            if (widget.onDelete != null)
              TextButton(onPressed: _confirmDelete, child: const Text('Sil')),
          ],
        ),
      ),
    );
  }
}
