trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
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
