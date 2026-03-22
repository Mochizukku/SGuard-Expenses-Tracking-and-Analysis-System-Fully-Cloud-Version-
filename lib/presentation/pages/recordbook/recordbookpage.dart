import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class SpendingItem {
  String name;
  double amount;
  DateTime date;

  SpendingItem({required this.name, double? amount, DateTime? date}) 
      : amount = amount ?? 0.0,
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory SpendingItem.fromJson(Map<String, dynamic> json) {
    return SpendingItem(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}

class SpendingCategory {
  String name;
  List<SpendingItem> items;
  bool isExpanded;
  bool isFavorite;

  SpendingCategory({
    required this.name,
    List<SpendingItem>? items,
    this.isExpanded = true,
    this.isFavorite = false,
  }) : items = items ?? [];

  double get total => items.fold(0, (sum, item) => sum + item.amount);

  Map<String, dynamic> toJson() => {
        'name': name,
        'isExpanded': isExpanded,
        'isFavorite': isFavorite,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory SpendingCategory.fromJson(Map<String, dynamic> json) {
    return SpendingCategory(
      name: json['name'] as String,
      isExpanded: json['isExpanded'] as bool? ?? true,
      isFavorite: json['isFavorite'] as bool? ?? false,
      items: (json['items'] as List<dynamic>?)?.map((i) {
        return SpendingItem.fromJson(i as Map<String, dynamic>);
      }).toList(),
    );
  }
}

class RecordBookData {
  static double balance = 0.00;
  static DateTime startDate = DateTime(2026, 1, 1);
  static DateTime endDate = DateTime(2026, 2, 1);
  static List<SpendingCategory> categories = [
    SpendingCategory(
      name: 'Billing',
      items: [],
    ),
    SpendingCategory(
      name: 'Food',
      items: [],
    ),
    SpendingCategory(
      name: 'Others',
      items: [],
    ),
  ];
}

class RecordBookPage extends StatefulWidget {
  const RecordBookPage({super.key});

  @override
  State<RecordBookPage> createState() => _RecordBookPageState();
}

class _RecordBookPageState extends State<RecordBookPage> {
  double get _overallSpendingTotal {
    return RecordBookData.categories.fold(
      0.0,
      (sum, category) => sum + category.total,
    );
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      "Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.",
      "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."
    ];
    return '${monthNames[date.month - 1]} ${date.day}';
  }

  void _showBalanceOverlay() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BalanceOverlayDialog(
          initialBalance: RecordBookData.balance,
          initialStartDate: RecordBookData.startDate,
          initialEndDate: RecordBookData.endDate,
          onConfirm: (newBalance, newStart, newEnd) {
            setState(() {
              RecordBookData.balance = newBalance;
              RecordBookData.startDate = newStart;
              RecordBookData.endDate = newEnd;
            });
            Navigator.of(context).pop();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  void _addNewCategory() {
    _showTextInputDialog(
      title: 'New Category',
      hint: 'Category Name',
      onConfirm: (val) {
        if (val.trim().isNotEmpty) {
          setState(() {
            RecordBookData.categories.add(SpendingCategory(name: val.trim()));
          });
        }
      },
    );
  }

  void _editCategory(SpendingCategory category) {
    _showTextInputDialog(
      title: 'Edit Category',
      initialValue: category.name,
      hint: 'Category Name',
      onConfirm: (val) {
        if (val.trim().isNotEmpty) {
          setState(() {
            category.name = val.trim();
          });
        }
      },
    );
  }

  void _deleteCategory(SpendingCategory category) {
    setState(() {
      RecordBookData.categories.remove(category);
    });
  }

  void _showTextInputDialog({
    required String title,
    String initialValue = '',
    required String hint,
    required Function(String) onConfirm,
  }) {
    final TextEditingController controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm(controller.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  void _addItemToCategory(SpendingCategory category) {
    _showItemInputDialog(
      title: 'Add Item',
      onConfirm: (name, amount, date) {
        setState(() {
          category.items.add(SpendingItem(name: name, amount: amount, date: date));
        });
      },
    );
  }

  void _editItem(SpendingCategory category, int index) {
    final item = category.items[index];
    _showItemInputDialog(
      title: 'Edit Item',
      initialName: item.name,
      initialAmount: item.amount,
      initialDate: item.date,
      onConfirm: (name, amount, date) {
        setState(() {
          item.name = name;
          item.amount = amount;
          item.date = date;
        });
      },
      onDelete: () {
        setState(() {
          category.items.removeAt(index);
        });
      },
    );
  }

  void _showItemInputDialog({
    required String title,
    String initialName = '',
    double initialAmount = 0.0,
    DateTime? initialDate,
    required Function(String, double, DateTime) onConfirm,
    VoidCallback? onDelete,
  }) {
    final TextEditingController nameController =
        TextEditingController(text: initialName);
    final TextEditingController amountController = TextEditingController(
        text: initialAmount == 0.0 ? '' : initialAmount.toStringAsFixed(2));
    DateTime selectedDate = initialDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Item Name'),
                  autofocus: true,
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(hintText: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) {
                      setStateDialog(() => selectedDate = d);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: const OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${selectedDate.month}/${selectedDate.day}/${selectedDate.year}'),
                        const Icon(Icons.calendar_today, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (onDelete != null)
                TextButton(
                  onPressed: () {
                    onDelete();
                    Navigator.pop(context);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final double amt = double.tryParse(amountController.text) ?? 0.0;
                  if (nameController.text.trim().isNotEmpty) {
                    onConfirm(nameController.text.trim(), amt, selectedDate);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              )
            ],
          );
        });
      },
    );
  }

  List<SpendingCategory> get _sortedCategories {
    final List<SpendingCategory> favs = [];
    final List<SpendingCategory> nonFavs = [];
    for (var c in RecordBookData.categories) {
      if (c.isFavorite) favs.add(c);
      else nonFavs.add(c);
    }
    return [...favs, ...nonFavs];
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF004EC4);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            'My Balance:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${RecordBookData.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(RecordBookData.startDate)} - ${_formatDate(RecordBookData.endDate)}, ${RecordBookData.startDate.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.add, color: primaryBlue, size: 28),
                onPressed: _showBalanceOverlay,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Spending List:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._sortedCategories.map((c) => _buildCategory(c, primaryBlue)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              border: Border.all(color: const Color(0xFF004EC4), width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF003A96),
                  ),
                ),
                Text(
                  '\$ ${_overallSpendingTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF003A96),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (RecordBookData.categories.length < 30)
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFF004AAD),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: TextButton.icon(
                onPressed: _addNewCategory,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Category limit reached (30/30).',
                  style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategory(SpendingCategory category, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        category.isFavorite ? Icons.star : Icons.star_border,
                        color: category.isFavorite ? Colors.orange : iconColor,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          category.isFavorite = !category.isFavorite;
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: iconColor, size: 20),
                      onPressed: () => _editCategory(category),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: iconColor, size: 20),
                      onPressed: () => _deleteCategory(category),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        category.isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: iconColor,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          category.isExpanded = !category.isExpanded;
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (category.isExpanded) ...[
            const SizedBox(height: 8),
            ...category.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return InkWell(
                onTap: () => _editItem(category, index),
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 12, bottom: 8, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 12)),
                      Text('\$ ${item.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: TextButton(
                onPressed: () => _addItemToCategory(category),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: Icon(Icons.add, color: iconColor),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('\$ ${category.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class BalanceOverlayDialog extends StatefulWidget {
  final double initialBalance;
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(double, DateTime, DateTime) onConfirm;

  const BalanceOverlayDialog({
    super.key,
    required this.initialBalance,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onConfirm,
  });

  @override
  State<BalanceOverlayDialog> createState() => _BalanceOverlayDialogState();
}

class _BalanceOverlayDialogState extends State<BalanceOverlayDialog> {
  late TextEditingController _balanceController;
  late int startMonth, startDay, startYear;
  late int endMonth, endDay, endYear;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
        text: widget.initialBalance.toStringAsFixed(2));
    startMonth = widget.initialStartDate.month;
    startDay = widget.initialStartDate.day;
    startYear = widget.initialStartDate.year;
    endMonth = widget.initialEndDate.month;
    endDay = widget.initialEndDate.day;
    endYear = widget.initialEndDate.year;
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e, child: Text(e.toString().padLeft(2, '0'))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextField(
                    controller: _balanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Enter Balance Amount',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'US Dollars (\$)',
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: ['US Dollars (\$)']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {},
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Starting date:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdown<int>(
                        value: startMonth,
                        items: List.generate(12, (i) => i + 1),
                        onChanged: (v) => setState(() => startMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildDropdown<int>(
                        value: startDay,
                        items: List.generate(31, (i) => i + 1),
                        onChanged: (v) => setState(() => startDay = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildDropdown<int>(
                        value: startYear,
                        items: List.generate(10, (i) => 2026 + i),
                        onChanged: (v) => setState(() => startYear = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('End date:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdown<int>(
                        value: endMonth,
                        items: List.generate(12, (i) => i + 1),
                        onChanged: (v) => setState(() => endMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildDropdown<int>(
                        value: endDay,
                        items: List.generate(31, (i) => i + 1),
                        onChanged: (v) => setState(() => endDay = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildDropdown<int>(
                        value: endYear,
                        items: List.generate(10, (i) => 2026 + i),
                        onChanged: (v) => setState(() => endYear = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final double balance =
                        double.tryParse(_balanceController.text) ?? 0.0;
                    final start = DateTime(startYear, startMonth, startDay);
                    final end = DateTime(endYear, endMonth, endDay);
                    widget.onConfirm(balance, start, end);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004EC4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('CONFIRM',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
