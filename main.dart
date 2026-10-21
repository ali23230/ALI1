import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String debugLog = "جاري التحميل...";

  @override
  void initState() {
    super.initState();
    loadDebts();
  }

  // تحميل البيانات
  Future<void> loadDebts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? names = prefs.getStringList('saved_names');
      List<String>? amounts = prefs.getStringList('saved_amounts');
      List<String>? dates = prefs.getStringList('saved_dates');

      if (names != null && amounts != null && names.length == amounts.length) {
        debtsList.clear();
        for (int i = 0; i < names.length; i++) {
          double amt = double.tryParse(amounts[i]) ?? 0.0;
          DateTime dt = dates != null && i < dates.length 
              ? (DateTime.tryParse(dates[i]) ?? DateTime.now()) 
              : DateTime.now();
          debtsList.add(DebtModel(name: names[i], amount: amt, lastUpdated: dt));
        }
        setState(() {
          debugLog = "تم استرجاع ${debtsList.length} زبون بنجاح";
        });
      } else {
        setState(() {
          debugLog = "لا توجد بيانات محفوظة في الذاكرة حالياً";
        });
      }
    } catch (e) {
      setState(() {
        debugLog = "خطأ أثناء القراءة: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // حفظ البيانات بشكل إجباري ومباشر على القدام
  Future<bool> saveDebts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> names = debtsList.map((e) => e.name).toList();
      List<String> amounts = debtsList.map((e) => e.amount.toString()).toList();
      List<String> dates = debtsList.map((e) => e.lastUpdated.toIso8601String()).toList();

      bool res1 = await prefs.setStringList('saved_names', names);
      bool res2 = await prefs.setStringList('saved_amounts', amounts);
      bool res3 = await prefs.setStringList('saved_dates', dates);

      bool success = res1 && res2 && res3;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "تم الحفظ بنجاح في ذاكرة الهاتف!" : "فشل الحفظ في القرص!"),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      return success;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء الحفظ: $e"), backgroundColor: Colors.red),
      );
      return false;
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

    await saveDebts();
    nameController.clear();
    amountController.clear();
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
            tooltip: 'إعادة قراءة الذاكرة',
            onPressed: loadDebts,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // شريط العرض والتشخيص
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.amber.shade100,
                    child: Text(
                      "حالة الذاكرة: $debugLog",
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.share, color: Colors.orange),
                                    onPressed: () => shareDebt(debt),
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
