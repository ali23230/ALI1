import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl' as intl;

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
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: const DebtHomePage(),
      ),
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
    _initData();
  }

  Future<void> _initData() async {
    await loadDebtsFromFile();
  }

  // الحصول على ملف التخزين الدائم في مسار التطبيق المحمي
  Future<File> getLocalFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/store_debts_v2.json');
  }

  // قراءة البيانات
  Future<void> loadDebtsFromFile() async {
    try {
      final file = await getLocalFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          final List decoded = jsonDecode(contents);
          setState(() {
            debtsList = decoded.map((item) => DebtModel.fromJson(item)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Read error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // حفظ البيانات بشكل فوري وتزامني
  Future<void> saveDebtsToFile() async {
    try {
      final file = await getLocalFile();
      final String encoded = jsonEncode(debtsList.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded, flush: true);
    } catch (e) {
      debugPrint("Write error: $e");
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

    await saveDebtsToFile();
    nameController.clear();
    amountController.clear();
  }

  Future<void> showAddMoreDialog(int index) async {
    final TextEditingController addController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('زيادة دين: ${debtsList[index].name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الدين الحالي: ${debtsList[index].amount} دج'),
              const SizedBox(height: 10),
              TextField(
                controller: addController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المضاف (دج)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                double? addedAmount = double.tryParse(addController.text.trim());
                if (addedAmount != null && addedAmount > 0) {
                  setState(() {
                    debtsList[index].amount += addedAmount;
                    debtsList[index].lastUpdated = DateTime.now();
                  });
                  await saveDebtsToFile();
                }
                Navigator.pop(context);
              },
              child: const Text('إضافة الدين', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showPayDialog(int index) async {
    final TextEditingController payController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تسديد دين: ${debtsList[index].name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الدين الحالي: ${debtsList[index].amount} دج'),
              const SizedBox(height: 10),
              TextField(
                controller: payController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع (دج)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                double? paidAmount = double.tryParse(payController.text.trim());
                if (paidAmount != null && paidAmount > 0) {
                  setState(() {
                    debtsList[index].amount -= paidAmount;
                    debtsList[index].lastUpdated = DateTime.now();
                    if (debtsList[index].amount <= 0) {
                      debtsList.removeAt(index);
                    }
                  });
                  await saveDebtsToFile();
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
    await saveDebtsToFile();
  }

  void shareDebt(DebtModel debt) {
    String dateFormatted = intl.DateFormat('yyyy/MM/dd HH:mm').format(debt.lastUpdated);
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
                              String dateFormatted = intl.DateFormat('yyyy/MM/dd HH:mm').format(debt.lastUpdated);
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
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.orange),
                                        tooltip: 'مشاركة',
                                        onPressed: () => shareDebt(debt),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                                        tooltip: 'زيادة دين',
                                        onPressed: () => showAddMoreDialog(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.payment, color: Colors.green),
                                        tooltip: 'تسديد جزء',
                                        onPressed: () => showPayDialog(index),
                                      ),
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
