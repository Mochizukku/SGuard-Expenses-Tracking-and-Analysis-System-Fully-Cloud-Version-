import 'package:flutter/material.dart';

import '../../../data/services/record_book_store.dart';
import '../../../data/services/record_export_service.dart';
import '../recordbook/recordbookpage.dart';

class ManageRecordPage extends StatefulWidget {
  const ManageRecordPage({super.key});

  @override
  State<ManageRecordPage> createState() => _ManageRecordPageState();
}

class _ManageRecordPageState extends State<ManageRecordPage> {
  bool _isLoading = true;
  List<String> _cloudDates = <String>[];

  @override
  void initState() {
    super.initState();
    _refreshDates();
  }

  String _formatDateKey(String dateKey) {
    final date = DateTime.parse(dateKey);
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

  Future<void> _refreshDates() async {
    setState(() => _isLoading = true);
    final dates = await RecordBookStore.listCloudDateKeys();
    if (!mounted) {
      return;
    }
    setState(() {
      _cloudDates = dates;
      _isLoading = false;
    });
  }

  Future<void> _loadDate(String dateKey) async {
    setState(() => _isLoading = true);
    final snapshot = await RecordBookStore.loadCloudSnapshotByDateKey(dateKey);
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    if (snapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cloud record found for that date.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded ${_formatDateKey(dateKey)} into the record book.')),
    );
  }

  Future<void> _exportDate(String dateKey) async {
    setState(() => _isLoading = true);
    final snapshot = await RecordBookStore.fetchCloudSnapshotByDateKey(dateKey);
    if (!mounted) {
      return;
    }
    if (snapshot == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cloud record found for export.')),
      );
      return;
    }

    try {
      await RecordExportService.exportSnapshotPdf(snapshot);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDateKey = RecordBookStore.dateKeyFromDate(RecordBookData.activeDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Records'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDates,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Active Record',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(_formatDateKey(activeDateKey)),
                    const SizedBox(height: 6),
                    Text('Balance: \$${RecordBookData.balance.toStringAsFixed(2)}'),
                    Text('Categories: ${RecordBookData.categories.length}'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _isLoading ? null : RecordExportService.exportCurrentSnapshotPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export Active PDF'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _refreshDates,
                          icon: const Icon(Icons.sync),
                          label: const Text('Refresh Cloud Dates'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cloud Records',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_cloudDates.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No cloud records found yet. Save today to cloud first.'),
                ),
              )
            else
              ..._cloudDates.map(
                (dateKey) => Card(
                  child: ListTile(
                    title: Text(_formatDateKey(dateKey)),
                    subtitle: Text(dateKey == activeDateKey ? 'Currently loaded' : 'Stored in cloud'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Load',
                          onPressed: _isLoading ? null : () => _loadDate(dateKey),
                          icon: const Icon(Icons.folder_open),
                        ),
                        IconButton(
                          tooltip: 'Export PDF',
                          onPressed: _isLoading ? null : () => _exportDate(dateKey),
                          icon: const Icon(Icons.picture_as_pdf),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
