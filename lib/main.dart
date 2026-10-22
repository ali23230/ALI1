import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        amount: (json['amount'] ?? 0.0).toDouble(),
      );
}

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  final TextEditingController searchController = TextEditingController();

  // متغيرات الآلة الحاسبة
  final TextEditingController calcNum1Controller = TextEditingController();
  final TextEditingController calcNum2Controller = TextEditingController();
  String calcResult = '0';

  @override
  void initState() {
    super.initState();
    _loadData();
    searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    searchController.dispose();
    calcNum1Controller.dispose();
    calcNum2Controller.dispose();
    super.dispose();
  }

  // تصفية الزبائن للبحث
  void _filterCustomers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredCustomers = customers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.phone.contains(query);
      }).toList();
    });
  }

  // حساب المجموع الكلي للديون
  double get totalDebt {
    return customers.fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      customers.map((c) => c.toJson()).toList(),
    );
    await prefs.setString('customers_list', encodedData);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('customers_list');
    if (encodedData != null) {
      try {
        final List decodedList = jsonDecode(encodedData);
        setState(() {
          customers = decodedList.map((item) => Customer.fromJson(item)).toList();
          filteredCustomers = customers;
        });
      } catch (e) {
        // تجاهل الخطأ
      }
    } else {
      setState(() {
        filteredCustomers = customers;
      });
    }
  }

  // إضافة زبون جديد
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
                    _filterCustomers();
                  });
                  _saveData();
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

  // مشاركة الدين عبر تطبيقات الهاتف (Partage)
  void _shareCustomerDebt(Customer customer) {
    final String message =
        'السلام عليكم ${customer.name}، نذكركم بأن مبلغ الدين الحالي لديكم هو: ${customer.amount} د.ج. شكراً لكم.';
    Share.share(message);
  }

  // خصم من الدين
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
                  _saveData();
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

  // إضافة دين
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
                  _saveData();
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
      _filterCustomers();
    });
    _saveData();
  }

  // عمليات الآلة الحاسبة
  void _calculate(String operation) {
    final double? n1 = double.tryParse(calcNum1Controller.text);
    final double? n2 = double.tryParse(calcNum2Controller.text);

    if (n1 == null || n2 == null) {
      setState(() {
        calcResult = 'أدخل أرقاماً صحيحة';
      });
      return;
    }

    setState(() {
      switch (operation) {
        case '+':
          calcResult = (n1 + n2).toStringAsFixed(2);
          break;
        case '-':
          calcResult = (n1 - n2).toStringAsFixed(2);
          break;
        case '*':
          calcResult = (n1 * n2).toStringAsFixed(2);
          break;
        case '/':
          calcResult = n2 != 0 ? (n1 / n2).toStringAsFixed(2) : 'قسمة على صفر';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة ديون الزبائن'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // 1. بطاقة إجمالي الدين
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المبلغ الكلي للدين العام:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$totalDebt د.ج',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ],
            ),
          ),

          // 2. شريط البحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'بحث عن زبون (بالاسم أو الهاتف)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // 3. الآلة الحاسبة
          ExpansionTile(
            title: const Text('🧮 الآلة الحاسبة السريعة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: calcNum1Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'الرقم الأول'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: calcNum2Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'الرقم الثاني'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(onPressed: () => _calculate('+'), child: const Text('+')),
                        ElevatedButton(onPressed: () => _calculate('-'), child: const Text('-')),
                        ElevatedButton(onPressed: () => _calculate('*'), child: const Text('×')),
                        ElevatedButton(onPressed: () => _calculate('/'), child: const Text('÷')),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text('النتيجة: $calcResult',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),

          // 4. قائمة الزبائن
          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(
                    child: Text(
                      'لا يوجد زبائن مطابقة للبحث أو القائمة فارغة',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'الهاتف: ${customer.phone.isEmpty ? "غير محدد" : customer.phone}'),
                              Text('الدين الحالي: ${customer.amount} د.ج',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // زر المشاركة (Partage)
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.blue),
                                tooltip: 'مشاركة (Messenger, SMS...)',
                                onPressed: () => _shareCustomerDebt(customer),
                              ),
                              // زر الخصم (أخضر)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.green),
                                tooltip: 'خصم من الدين',
                                onPressed: () =>
                                    _showPayPartDialog(context, customer),
                              ),
                              // زر الزيادة (أحمر)
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Colors.red),
                                tooltip: 'إضافة دين',
                                onPressed: () =>
                                    _showAddDebtDialog(context, customer),
                              ),
                              // زر الحذف
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.grey),
                                onPressed: () => _deleteCustomer(customer),
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
    );
  }
}
