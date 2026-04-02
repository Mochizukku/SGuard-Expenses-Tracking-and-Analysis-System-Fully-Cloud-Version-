import 'package:flutter/material.dart';

import '../../../data/services/record_book_store.dart';
import '../recordbook/recordbookpage.dart';
import 'record_export_page.dart';
import 'record_history_detail_page.dart';

class ManageRecordPage extends StatefulWidget {
  const ManageRecordPage({
    super.key,
    this.dateKeysLoader,
    this.snapshotLoader,
  });

  final Future<List<String>> Function()? dateKeysLoader;
  final Future<DailyRecordSnapshot?> Function(String dateKey)? snapshotLoader;

  @override
  State<ManageRecordPage> createState() => _ManageRecordPageState();
}

class _ManageRecordPageState extends State<ManageRecordPage> {
  bool _isLoading = true;
  List<String> _historyDates = <String>[];
  DateTime? _selectedMonth;

  DateTime _normalizeMonth(DateTime date) => DateTime(date.year, date.month);

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
    final dates =
        await (widget.dateKeysLoader?.call() ?? RecordBookStore.listHistoryDateKeys());
    if (!mounted) {
      return;
    }
    setState(() {
      _historyDates = dates;
      _selectedMonth ??= dates.isNotEmpty
          ? _normalizeMonth(DateTime.parse(dates.first))
          : _normalizeMonth(DateTime.now());
      _isLoading = false;
    });
  }

  Future<void> _openDate(String dateKey) async {
    setState(() => _isLoading = true);
    final snapshot = widget.snapshotLoader != null
        ? await widget.snapshotLoader!(dateKey)
        : await RecordBookStore.fetchHistorySnapshotByDateKey(dateKey);
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    if (snapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No record found for that date.')),
      );
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordHistoryDetailPage(snapshot: snapshot),
      ),
    );

    if (updated == true) {
      await _refreshDates();
    }
  }

  void _openExportPage([String? dateKey]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordExportPage(
          initialDateKey: dateKey,
          dateKeysLoader: widget.dateKeysLoader,
          snapshotLoader: widget.snapshotLoader,
        ),
      ),
    );
  }

  String _monthLabel(DateTime date) {
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
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  List<DateTime> _monthOptions() {
    final months = <DateTime>{};
    for (final key in _historyDates) {
      final date = DateTime.parse(key);
      months.add(_normalizeMonth(date));
    }
    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  List<String> _datesForSelectedMonth() {
    final selectedMonth = _selectedMonth;
    if (selectedMonth == null) {
      return _historyDates;
    }
    return _historyDates.where((key) {
      final date = DateTime.parse(key);
      return date.year == selectedMonth.year && date.month == selectedMonth.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeDateKey = RecordBookStore.dateKeyFromDate(RecordBookData.activeDate);
    final monthOptions = _monthOptions();
    final visibleDates = _datesForSelectedMonth();

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: RefreshIndicator(
        onRefresh: _refreshDates,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Center(
              child: Container(
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: const Color(0xFF004AAD),
                        padding: const EdgeInsets.only(top: 18, left: 12, right: 12, bottom: 18),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF2C69C8)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Manage Records',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _isLoading ? null : () => _openExportPage(),
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
                              tooltip: 'Open export page',
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE8E1CC)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<DateTime>(
                                    value: _selectedMonth,
                                    hint: const Text('Select month'),
                                    items: monthOptions
                                        .map(
                                          (month) => DropdownMenuItem<DateTime>(
                                            value: month,
                                            child: Text(_monthLabel(month)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: monthOptions.isEmpty
                                        ? null
                                        : (value) => setState(
                                              () => _selectedMonth =
                                                  value == null ? null : _normalizeMonth(value),
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 32, bottom: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_historyDates.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No saved history found yet. Save or sync a record first.'),
                        )
                      else if (visibleDates.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No records stored for the selected month.'),
                        )
                      else
                        ...visibleDates.map(
                          (dateKey) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: InkWell(
                              onTap: _isLoading ? null : () => _openDate(dateKey),
                              onLongPress: _isLoading ? null : () => _openExportPage(dateKey),
                              child: Container(
                                color: const Color(0xFFD9D9D9),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      dateKey == activeDateKey ? Icons.calendar_today : Icons.history,
                                      color: const Color(0xFF004AAD),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _formatDateKey(dateKey),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: dateKey == activeDateKey ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Tap a row to open a historical record editor. Long-press a row to open export preview.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 20),
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
