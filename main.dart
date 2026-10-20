import 'package:flutter/material.dart';

void main() {
  // التقاط أي خطأ فادح ومنع الإغلاق الصامت
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const StoreApp());
  }, (error, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Text(
                'خطأ في التشغيل:\n$error',
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    ));
  });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسيير ديون المحل'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
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
              child: ListView.builder(
                itemCount: debtsList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        debtsList[index].name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'المتبقي: ${debtsList[index].amount} دج',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
