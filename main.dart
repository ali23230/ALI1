import 'package:flutter/material.dart';

void main() {
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

  DebtModel({required this.name, required this.amount});
}

class DebtHomePage extends StatefulWidget {
  const DebtHomePage({super.key});

  @override
  State<DebtHomePage> createState() => _DebtHomePageState();
}

class _DebtHomePageState extends State<DebtHomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final List<DebtModel> debtsList = [];

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
      } else {
        debtsList.add(DebtModel(name: nameText, amount: parsedAmount));
      }
    });

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
              onPressed: () {
                double? addedAmount = double.tryParse(addController.text.trim());
                if (addedAmount != null && addedAmount > 0) {
                  setState(() {
                    debtsList[index].amount += addedAmount;
                  });
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
              onPressed: () {
                double? paidAmount = double.tryParse(payController.text.trim());
                if (paidAmount != null && paidAmount > 0) {
                  setState(() {
                    debtsList[index].amount -= paidAmount;
                    if (debtsList[index].amount <= 0) {
                      debtsList.removeAt(index);
                    }
                  });
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
    return Service Scaffold(  // تم إصلاح السطر ليوافق بنية الواجهة السليمة
