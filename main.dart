import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      home: const DebtHomePage(),
    );
  }
}

class DebtModel {
  String name;
  double amount;
  DateTime lastUpdated;

  DebtModel({
    required this.name,
    required this.amount,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory DebtModel.fromJson(Map<String, dynamic> json) => DebtModel(
        name: json['name'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: json['lastUpdated'] != null 
            ? DateTime.parse(json['lastUpdated']) 
            : DateTime.now(),
      );
}

class DebtHomePage extends StatefulWidget {
  const DebtHomePage({super.key});

  @override
  State<DebtHomePage> createState() => _DebtHomePageState();
}

class _DebtHomePageState extends State<DebtHomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  List<DebtModel> debtsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFromFile();
  }

  Future<File> getSecureFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/debts_data_v3.json');
  }

  Future<void> loadFromFile() async {
    try {
      final file = await getSecureFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.trim().isNotEmpty) {
          final List decoded = jsonDecode(contents);
          setState(() {
            debtsList = decoded.map((e) => DebtModel.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Reading error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveToFile() async {
    try {
      final file = await getSecureFile();
      final encoded = jsonEncode(debtsList.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded, flush: true);
    } catch (e) {
      debugPrint("Saving error: $e");
    }
  }

  Future<void> addDebt() async {
    String nameText = nameController.text.trim();
    String amountText = amountController.text.trim();

    if (nameText.isEmpty || amountText.isEmpty) return;

    double? parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null) return;

    setState(() {
      int existingIndex = debtsList.indexWhere(
        (item) => item.name.trim().toLowerCase() == nameText.toLowerCase(),
      );

      if (existingIndex != -1) {
        debtsList[existingIndex].amount += parsedAmount;
        debtsList[existingIndex].lastUpdated = DateTime.now();
      } else {
        debtsList.add(DebtModel(
          name: nameText,
          amount: parsedAmount,
          lastUpdated: DateTime.now(),
        ));
      }
    });

    await saveToFile();
    nameController.clear();
    amountController.clear();
  }

  // نافذة تسديد أو إنقاص جزء من الدين
  void showPayPartDialog(int index) {
    final TextEditingController payController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تسديد جزء من دين: ${debtsList[index].name}'),
          content: TextField(
            controller: payController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المبلغ المدفوع (دج)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                double? payAmount = double.tryParse(payController.text.trim());
                if (payAmount != null && payAmount > 0) {
                  setState(() {
                    debtsList[index].amount -= payAmount;
                    if (debtsList[index].amount < 0) {
                      debtsList[index].amount = 0;
                    }
                    debtsList[index].lastUpdated = DateTime.now();
                  });
                  await saveToFile();
                }
                Navigator.pop(context);
              },
              child: const Text('خصم المبلغ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteDebt(int index) async {
    setState(() {
      debtsList.removeAt(index);
    });
    await saveToFile();
  }

  void shareDebt(DebtModel debt) {
    String dateFormatted = DateFormat('yyyy/MM/dd HH:mm').format(debt.lastUpdated);
    String message = 'تفاصيل الدين:\nالزبون: ${debt.name}\nالمبلغ المتبقي: ${debt.amount} دج\nآخر تحديث: $dateFormatted';
    Share.share(message);
  }

  double getTotal() {
    double total = 0;
    for (var item in debtsList) {
      total += item.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسيير ديون المحل'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الزبون',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ الدين (دج)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: addDebt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size.fromHeight(45),
                    ),
                    child: const Text('حفظ الدين', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'المجموع الكلي: ${getTotal()} دج',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const Divider(height: 30),
                  Expanded(
                    child: debtsList.isEmpty
                        ? const Center(child: Text('لا توجد ديون مسجلة حالياً'))
                        : ListView.builder(
                            itemCount: debtsList.length,
                            itemBuilder: (context, index) {
                              final debt = debtsList[index];
                              String dateFormatted = DateFormat('yyyy/MM/dd HH:mm').format(debt.lastUpdated);
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    debt.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'المتبقي: ${debt.amount} دج',
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'التاريخ: $dateFormatted',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // زر تسديد جزء من الدين (أيقونة ناقص خضراء)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
                                        tooltip: 'تسديد جزء من الدين',
                                        onPressed: () => showPayPartDialog(index),
                                      ),
                                      // زر المشاركة
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.orange),
                                        tooltip: 'مشاركة',
                                        onPressed: () => shareDebt(debt),
                                      ),
                                      // زر الحذف
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.grey),
                                        tooltip: 'حذف',
                                        onPressed: () => deleteDebt(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
