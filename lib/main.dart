import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' as intl;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تسيير ديون المحل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: DebtHomePage(),
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
        name: json['name'],
        amount: (json['amount'] as num).toDouble(),
        lastUpdated: DateTime.parse(json['lastUpdated']),
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
  final TextEditingController searchController = TextEditingController();

  List<DebtModel> debtsList = [];
  String searchQuery = '';
  bool sortByAmount = false;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  // تحميل البيانات المحفوظة
  Future<void> _loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? debtsData = prefs.getString('saved_debts');
    if (debtsData != null) {
      final List<dynamic> decoded = jsonDecode(debtsData);
      setState(() {
        debtsList = decoded.map((item) => DebtModel.fromJson(item)).toList();
      });
    }
  }

  // حفظ البيانات على الهاتف
  Future<void> _saveDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(debtsList.map((e) => e.toJson()).toList());
    await prefs.setString('saved_debts', encoded);
  }

  void addDebt() {
    String nameText = nameController.text.trim();
    String amountText = amountController.text.trim();

    if (nameText.isEmpty || amountText.isEmpty) return;

    double? parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null) return;

    int existingIndex = debtsList.indexWhere(
      (item) => item.name.trim().toLowerCase() == nameText.toLowerCase(),
    );

    setState(() {
      if (existingIndex != -1) {
        debtsList[existingIndex].amount += parsedAmount;
        debtsList[existingIndex].lastUpdated = DateTime.now();
      } else {
        debtsList.add(
          DebtModel(
            name: nameText,
            amount: parsedAmount,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    });

    _saveDebts();
    nameController.clear();
    amountController.clear();
  }

  void showAddMoreDialog(int index) {
    final TextEditingController addController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('زيادة دين: ${debtsList[index].name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الدين الحالي: ${debtsList[index].amount.toStringAsFixed(2)} دج'),
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
              onPressed: () {
                double? addedAmount = double.tryParse(addController.text.trim());
                if (addedAmount != null && addedAmount > 0) {
                  setState(() {
                    debtsList[index].amount += addedAmount;
                    debtsList[index].lastUpdated = DateTime.now();
                  });
                  _saveDebts();
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

  void showPayDialog(int index) {
    final TextEditingController payController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تسديد دين: ${debtsList[index].name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الدين الحالي: ${debtsList[index].amount.toStringAsFixed(2)} دج'),
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
              onPressed: () {
                double? paidAmount = double.tryParse(payController.text.trim());
                if (paidAmount != null && paidAmount > 0) {
                  setState(() {
                    debtsList[index].amount -= paidAmount;
                    debtsList[index].lastUpdated = DateTime.now();
                    if (debtsList[index].amount <= 0) {
                      debtsList.removeAt(index);
                    }
                  });
                  _saveDebts();
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

  void deleteDebt(int index) {
    setState(() {
      debtsList.removeAt(index);
    });
    _saveDebts();
  }

  void shareDebtInfo(DebtModel debt) {
    String dateFormatted = intl.DateFormat('yyyy/MM/dd HH:mm').format(debt.lastUpdated);
    String message =
        "تذكير بمستحقات المحل:\nالزبون: ${debt.name}\nالمبلغ المتبقي: ${debt.amount.toStringAsFixed(2)} دج\nتاريخ آخر تحديث: $dateFormatted";
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
    // تصفية وحساب القائمة حسب البحث والترتيب
    List<DebtModel> filteredList = debtsList.where((item) {
      return item.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    if (sortByAmount) {
      filteredList.sort((a, b) => b.amount.compareTo(a.amount));
    } else {
      filteredList.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسيير ديون المحل'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(sortByAmount ? Icons.sort_by_alpha : Icons.attach_money),
            tooltip: sortByAmount ? 'ترتيب حسب الأحدث' : 'ترتيب حسب الأعلى ديناً',
            onPressed: () {
              setState(() {
                sortByAmount = !sortByAmount;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // مدخلات الزبون والمبلغ
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الزبون',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ الدين (دج)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: addDebt,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('حفظ الدين', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(45),
              ),
            ),
            const SizedBox(height: 15),

            // شريط البحث
            TextField(
              controller: searchController,
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'بحث عن زبون...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع الكلي للديون:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '${getTotal().toStringAsFixed(2)} دج',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // قائمة الديون
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(child: Text('لا توجد ديون مسجلة'))
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final debt = filteredList[index];
                        final originalIndex = debtsList.indexOf(debt);
                        String dateFormatted = intl.DateFormat('yyyy/MM/dd - HH:mm').format(debt.lastUpdated);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              debt.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المتبقي: ${debt.amount.toStringAsFixed(2)} دج',
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'آخر تعديل: $dateFormatted',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.orange),
                                  tooltip: 'مشاركة كشف الحساب',
                                  onPressed: () => shareDebtInfo(debt),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                                  tooltip: 'زيادة دين',
                                  onPressed: () => showAddMoreDialog(originalIndex),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.payment, color: Colors.green),
                                  tooltip: 'تسديد جزء',
                                  onPressed: () => showPayDialog(originalIndex),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.grey),
                                  tooltip: 'حذف',
                                  onPressed: () => deleteDebt(originalIndex),
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
