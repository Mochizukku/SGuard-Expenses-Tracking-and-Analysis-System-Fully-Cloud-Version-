import 'package:flutter/material.dart';

import '../../../data/services/record_book_store.dart';
import '../../../data/services/record_export_service.dart';

class RecordExportPage extends StatefulWidget {
  const RecordExportPage({
    super.key,
    this.initialDateKey,
    this.dateKeysLoader,
    this.snapshotLoader,
  });

  final String? initialDateKey;
  final Future<List<String>> Function()? dateKeysLoader;
  final Future<DailyRecordSnapshot?> Function(String dateKey)? snapshotLoader;

  @override
  State<RecordExportPage> createState() => _RecordExportPageState();
}

class _RecordExportPageState extends State<RecordExportPage> {
  bool _isLoading = true;
  bool _isExporting = false;
  List<String> _dateKeys = <String>[];
  String? _selectedDateKey;
  DailyRecordSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    setState(() => _isLoading = true);
    try {
      final keys = await (widget.dateKeysLoader?.call() ?? RecordBookStore.listHistoryDateKeys());
      String? selected = widget.initialDateKey;
      if (selected == null && keys.isNotEmpty) {
        selected = keys.first;
      }

      DailyRecordSnapshot? snapshot;
      if (selected != null) {
        snapshot = await (widget.snapshotLoader?.call(selected) ?? RecordBookStore.fetchHistorySnapshotByDateKey(selected));
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _dateKeys = keys;
        _selectedDateKey = selected;
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load cloud records: $error')),
      );
    }
  }

  Future<void> _selectDate(String? dateKey) async {
    if (dateKey == null) {
      return;
    }
    setState(() {
      _selectedDateKey = dateKey;
      _isLoading = true;
    });

    try {
      final snapshot = await (widget.snapshotLoader?.call(dateKey) ?? RecordBookStore.fetchHistorySnapshotByDateKey(dateKey));
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to preview record: $error')),
      );
    }
  }

  Future<void> _export() async {
    if (_snapshot == null) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      await RecordExportService.exportSnapshotPdf(_snapshot!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF shared successfully')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveToDownloads() async {
    if (_snapshot == null) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      final filePath = await RecordExportService.saveToDownloads(
        title: 'SGuard Spending Report',
        subtitle: 'Record date: ${_snapshot!.dateKey}',
        balance: _snapshot!.balance,
        categories: _snapshot!.categories,
        fileName: 'sguard-${_snapshot!.dateKey}.pdf',
      );

      if (mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF saved to: $filePath')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save PDF to Downloads')),
          );
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _formatDateKey(String dateKey) {
    final date = DateTime.parse(dateKey);
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Record Export'),
        backgroundColor: const Color(0xFF004AAD),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDates,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDateKey,
              decoration: const InputDecoration(
                labelText: 'Select cloud date',
                border: OutlineInputBorder(),
              ),
              items: _dateKeys
                  .map(
                    (key) => DropdownMenuItem<String>(
                      value: key,
                      child: Text(_formatDateKey(key)),
                    ),
                  )
                  .toList(),
              onChanged: _dateKeys.isEmpty ? null : _selectDate,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_dateKeys.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No cloud records found yet. Save a day to cloud first.'),
                ),
              )
            else if (snapshot == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No data found for the selected date.'),
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateKey(snapshot.dateKey),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text('Balance: ${snapshot.balance.toStringAsFixed(2)}'),
                      Text(
                        'Total spent: ${snapshot.categories.fold<double>(0.0, (sum, category) => sum + category.total).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...snapshot.categories.map(
                (category) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                            Text(category.total.toStringAsFixed(2)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (category.items.isEmpty)
                          const Text('No records')
                        else
                          ...category.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(item.name)),
                                  Text(item.amount.toStringAsFixed(2)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _saveToDownloads,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.download),
                      label: Text(_isExporting ? 'Saving...' : 'Save to Downloads'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _export,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF004AAD),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.share),
                      label: Text(_isExporting ? 'Sharing...' : 'Share PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
