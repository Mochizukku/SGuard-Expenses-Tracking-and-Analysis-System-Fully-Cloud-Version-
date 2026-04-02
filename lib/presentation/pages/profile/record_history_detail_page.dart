import 'package:flutter/material.dart';

import '../../../data/services/record_book_store.dart';
import '../recordbook/recordbookpage.dart';

class RecordHistoryDetailPage extends StatefulWidget {
  const RecordHistoryDetailPage({
    super.key,
    required this.snapshot,
  });

  final DailyRecordSnapshot snapshot;

  @override
  State<RecordHistoryDetailPage> createState() => _RecordHistoryDetailPageState();
}

class _RecordHistoryDetailPageState extends State<RecordHistoryDetailPage> {
  late List<SpendingCategory> _categories;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _categories = RecordBookStore.cloneCategories(widget.snapshot.categories);
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

  double get _overallSpendingTotal {
    return _categories.fold(0.0, (sum, category) => sum + category.total);
  }

  void _commit(VoidCallback action) {
    setState(action);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await RecordBookStore.saveHistoricalSnapshot(
        DailyRecordSnapshot(
          dateKey: widget.snapshot.dateKey,
          balance: widget.snapshot.balance,
          categories: RecordBookStore.cloneCategories(_categories),
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historical record updated.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save record: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
                child: Text(_formatLongDate(DateTime.parse(widget.snapshot.dateKey))),
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

  void _addNewCategory() {
    _showTextInputDialog(
      title: 'New Category',
      hint: 'Category Name',
      onConfirm: (value) {
        if (value.trim().isEmpty) {
          return;
        }
        _commit(() {
          _categories.add(SpendingCategory(name: value.trim()));
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
      _categories.remove(category);
    });
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
              date: DateTime.parse(widget.snapshot.dateKey),
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
          item.date = DateTime.parse(widget.snapshot.dateKey);
        });
      },
      onDelete: () {
        _commit(() {
          category.items.removeAt(index);
        });
      },
    );
  }

  List<SpendingCategory> get _sortedCategories {
    final favorites = <SpendingCategory>[];
    final others = <SpendingCategory>[];
    for (final category in _categories) {
      if (category.isFavorite) {
        favorites.add(category);
      } else {
        others.add(category);
      }
    }
    return [...favorites, ...others];
  }

  Widget _buildCategory(SpendingCategory category) {
    const iconColor = Color(0xFF004EC4);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                        _commit(() {
                          category.isFavorite = !category.isFavorite;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: iconColor, size: 20),
                      onPressed: () => _editCategory(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: iconColor, size: 20),
                      onPressed: () => _deleteCategory(category),
                    ),
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
                      Expanded(child: Text(item.name, style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 12),
                      Text('\$ ${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
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
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Icon(Icons.add, color: iconColor),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    '\$ ${category.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordDate = DateTime.parse(widget.snapshot.dateKey);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004AAD),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(_formatLongDate(recordDate)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Balance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${widget.snapshot.balance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Balance is locked for historical updates.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Spending List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._sortedCategories.map(_buildCategory),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF003A96)),
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
            if (_categories.length < 30)
              Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF004AAD),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextButton.icon(
                  onPressed: _addNewCategory,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Category',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
