import 'package:flutter/material.dart';

import '../../../data/services/record_book_store.dart';

class SpendingItem {
  String name;
  double amount;
  DateTime date;

  SpendingItem({required this.name, double? amount, DateTime? date})
      : amount = amount ?? 0.0,
        date = RecordBookStore.normalizeDate(date ?? DateTime.now());

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory SpendingItem.fromJson(Map<String, dynamic> json) {
    return SpendingItem(
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
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

  double get total => items.fold(0.0, (sum, item) => sum + item.amount);

  Map<String, dynamic> toJson() => {
        'name': name,
        'isExpanded': isExpanded,
        'isFavorite': isFavorite,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory SpendingCategory.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((item) => SpendingItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return SpendingCategory(
      name: json['name'] as String? ?? 'Untitled',
      isExpanded: json['isExpanded'] as bool? ?? true,
      isFavorite: json['isFavorite'] as bool? ?? false,
      items: items,
    );
  }
}

class RecordBookData {
  static double balance = 0.0;
  static DateTime activeDate = RecordBookStore.normalizeDate(DateTime.now());
  static List<SpendingCategory> categories = RecordBookStore.defaultCategories();
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void notifyListeners() {
    revision.value++;
  }
}

class RecordBookPage extends StatefulWidget {
  const RecordBookPage({super.key});

  @override
  State<RecordBookPage> createState() => _RecordBookPageState();
}

class _RecordBookPageState extends State<RecordBookPage> {
  double get _overallSpendingTotal {
    return RecordBookData.categories.fold(0.0, (sum, category) => sum + category.total);
  }

  String _formatLongDate(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _commit(VoidCallback action) {
    setState(action);
    RecordBookData.notifyListeners();
    RecordBookStore.saveLocalSnapshot();
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
          activeDate: RecordBookData.activeDate,
          onConfirm: (newBalance) {
            _commit(() {
              RecordBookData.balance = newBalance;
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
      onConfirm: (value) {
        if (value.trim().isEmpty) {
          return;
        }
        _commit(() {
          RecordBookData.categories.add(SpendingCategory(name: value.trim()));
        });
      },
    );
  }

  void _editCategory(SpendingCategory category) {
    _showTextInputDialog(
      title: 'Edit Category',
      initialValue: category.name,
      hint: 'Category Name',
      onConfirm: (value) {
        if (value.trim().isEmpty) {
          return;
        }
        _commit(() {
          category.name = value.trim();
        });
      },
    );
  }

  void _deleteCategory(SpendingCategory category) {
    _commit(() {
      RecordBookData.categories.remove(category);
    });
  }

  void _showTextInputDialog({
    required String title,
    String initialValue = '',
    required String hint,
    required ValueChanged<String> onConfirm,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog<void>(
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
            ),
          ],
        );
      },
    );
  }

  void _addItemToCategory(SpendingCategory category) {
    _showItemInputDialog(
      title: 'Add Item',
      onConfirm: (name, amount) {
        _commit(() {
          category.items.add(
            SpendingItem(
              name: name,
              amount: amount,
              date: RecordBookData.activeDate,
            ),
          );
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
      onConfirm: (name, amount) {
        _commit(() {
          item.name = name;
          item.amount = amount;
          item.date = RecordBookData.activeDate;
        });
      },
      onDelete: () {
        _commit(() {
          category.items.removeAt(index);
        });
      },
    );
  }

  void _showItemInputDialog({
    required String title,
    String initialName = '',
    double initialAmount = 0.0,
    required void Function(String, double) onConfirm,
    VoidCallback? onDelete,
  }) {
    final nameController = TextEditingController(text: initialName);
    final amountController =
        TextEditingController(text: initialAmount == 0.0 ? '' : initialAmount.toStringAsFixed(2));

    showDialog<void>(
      context: context,
      builder: (context) {
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
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(hintText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Record Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(_formatLongDate(RecordBookData.activeDate)),
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
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  onConfirm(name, amount);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  List<SpendingCategory> get _sortedCategories {
    final favorites = <SpendingCategory>[];
    final others = <SpendingCategory>[];

    for (final category in RecordBookData.categories) {
      if (category.isFavorite) {
        favorites.add(category);
      } else {
        others.add(category);
      }
    }

    return [...favorites, ...others];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: RecordBookData.revision,
      builder: (context, _, __) {
        final primaryBlue = const Color(0xFF004EC4);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Balance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF16304B)),
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
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF16304B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'For ${_formatLongDate(RecordBookData.activeDate)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4A6078), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: primaryBlue, size: 24),
                    onPressed: _showBalanceOverlay,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Spending List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF16304B)),
              ),
              const SizedBox(height: 12),
              ..._sortedCategories.map((category) => _buildCategory(category, primaryBlue)),
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
                    color: const Color(0xFF004AAD),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: _addNewCategory,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add Category',
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
      },
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF16304B)),
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
                        _commit(() {
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
                        category.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: iconColor,
                        size: 20,
                      ),
                      onPressed: () {
                        _commit(() {
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
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF324A64)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '\$ ${item.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF324A64)),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
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
                  const Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
  const BalanceOverlayDialog({
    super.key,
    required this.initialBalance,
    required this.activeDate,
    required this.onConfirm,
  });

  final double initialBalance;
  final DateTime activeDate;
  final ValueChanged<double> onConfirm;

  @override
  State<BalanceOverlayDialog> createState() => _BalanceOverlayDialogState();
}

class _BalanceOverlayDialogState extends State<BalanceOverlayDialog> {
  late final TextEditingController _balanceController;

  String _formatLongDate(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(text: widget.initialBalance.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Active record date: ${_formatLongDate(widget.activeDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextField(
                    controller: _balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Enter Balance Amount',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                          .map((currency) => DropdownMenuItem(value: currency, child: Text(currency)))
                          .toList(),
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
                    widget.onConfirm(balance);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004EC4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
