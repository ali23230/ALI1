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
    loadFromFile();
  }

  // الحصول على مسار الملف المضمون في ذاكرة التطبيق
  Future<File> getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/my_store_debts.json');
  }

  // قراءة البيانات من الملف الداخلي
  Future<void> loadFromFile() async {
    try {
      final file = await getFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          final List decoded = jsonDecode(contents);
          setState(() {
            debtsList = decoded.map((e) => DebtModel.fromJson(e)).toList();
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

  // حفظ البيانات مباشرة في الملف مع إجبار الكتابة الفورية
  Future<void> saveToFile() async {
    try {
      final file = await getFile();
      final encoded = jsonEncode(debtsList.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded, flush: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم الحفظ في الملف بنجاح!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ في الحفظ: $e"),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> deleteDebt(int index) async {
    setState(() {
      debtsList.removeAt(index);
    });
    await saveToFile();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadFromFile,
            tooltip: 'تحديث البيانات',
          )
        ],
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
                                        onPressed: () => shareDebt(debt),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.grey),
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
