trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'متابعة الديون',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CustomerListScreen(),
    );
  }
}

class Customer {
  String name;
  double amount;

  Customer({required this.name, required this.amount});
}

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Customer> customers = [
    Customer(name: 'زبون 1', amount: 5000.0),
    Customer(name: 'زبون 2', amount: 3500.0),
  ];

  // دالة خصم/تسديد الدين
  void _showPayPartDialog(BuildContext context, Customer customer) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('خصم دين من ${customer.name}'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المبلغ المستلم (خصم)',
              hintText: 'أدخل المبلغ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  setState(() {
                    customer.amount -= amount;
                    if (customer.amount < 0) customer.amount = 0;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('تأكيد الخصم'),
            ),
          ],
        );
      },
    );
  }

  // دالة إضافة/زيادة الدين
  void _showAddDebtDialog(BuildContext context, Customer customer) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('إضافة دين لـ ${customer.name}'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المبلغ المضاف (دين جديد)',
              hintText: 'أدخل المبلغ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  setState(() {
                    customer.amount += amount;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('تأكيد الزيادة'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCustomer(Customer customer) {
    setState(() {
      customers.remove(customer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة ديون الزبائن'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('الدين الحالي: ${customer.amount} د.ج'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر الخصم (أيقونة خضراء)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
                    tooltip: 'خصم من الدين',
                    onPressed: () => _showPayPartDialog(context, customer),
                  ),
                  // زر الزيادة (أيقونة حمراء)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.red),
                    tooltip: 'إضافة دين جديد',
                    onPressed: () => _showAddDebtDialog(context, customer),
                  ),
                  // زر الحذف
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _deleteCustomer(customer),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

    // 1. زر الخصم/التسديد الجزئي (الأيقونة الخضراء)
    IconButton(
      icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
      tooltip: 'خصم من الدين',
      onPressed: () => _showPayPartDialog(context, customer),
    ),
    
    // 2. زر زيادة الدين (الأيقونة الحمراء)
    IconButton(
      icon: const Icon(Icons.add_circle_outline, color: Colors.red),
      tooltip: 'إضافة دين جديد',
      onPressed: () => _showAddDebtDialog(context, customer),
    ),

    // 3. زر المشاركة أو الحذف
    IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.grey),
      onPressed: () => _deleteCustomer(customer),
    ),
  ],
),
