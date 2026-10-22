import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String phone;
  double amount;

  Customer({required this.name, required this.phone, required this.amount});

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'amount': amount,
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        name: json['name'],
        phone: json['phone'],
        amount: json['amount'],
      );
}

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();
    _loadData(); // تحميل البيانات المحفوظة عند فتح التطبيق
  }

  // حفظ البيانات محلياً
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      customers.map((c) => c.toJson()).toList(),
    );
    await prefs.setString('customers_list', encodedData);
  }

  // استرجاع البيانات المحفوظة
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('customers_list');
    if (encodedData != null) {
      final List decodedList = jsonDecode(encodedData);
      setState(() {
        customers = decodedList.map((item) => Customer.fromJson(item)).toList();
      });
    }
  }

  // 1. إضافة زبون جديد
  void _showAddCustomerDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة زبون جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الزبون'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'مبلغ الدين الأولي'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final String name = nameController.text.trim();
                final String phone = phoneController.text.trim();
                final double? amount = double.tryParse(amountController.text);

                if (name.isNotEmpty) {
                  setState(() {
                    customers.add(
                      Customer(
                        name: name,
                        phone: phone,
                        amount: amount ?? 0.0,
                      ),
                    );
                  });
                  _saveData(); // حفظ التغييرات
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  // 2. إرسال رسالة
  void _sendMessage(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إرسال رسالة لـ ${customer.name}'),
        content: Text('رقم الهاتف: ${customer.phone}\nالدين الحالي: ${customer.amount} د.ج'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // 3. خصم من الدين (أيقونة خضراء)
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
                  _saveData(); // حفظ التغييرات فوراً
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

  // 4. زيادة الدين (أيقونة حمراء)
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
                  _saveData(); // حفظ التغييرات فوراً
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

  // 5. حذف زبون
  void _deleteCustomer(Customer customer) {
    setState(() {
      customers.remove(customer);
    });
    _saveData(); // حفظ التغييرات بعد الحذف
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة ديون الزبائن'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: customers.isEmpty
          ? const Center(
              child: Text(
                'لا يوجد زبائن حالياً، اضغط على زر (+) في الأسفل لإضافة زبون',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الهاتف: ${customer.phone.isEmpty ? "غير محدد" : customer.phone}'),
                        Text('الدين الحالي: ${customer.amount} د.ج',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue),
                          tooltip: 'إرسال رسالة',
                          onPressed: () => _sendMessage(customer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
                          tooltip: 'خصم من الدين',
                          onPressed: () => _showPayPartDialog(context, customer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.red),
                          tooltip: 'إضافة دين',
                          onPressed: () => _showAddDebtDialog(context, customer),
                        ),
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
