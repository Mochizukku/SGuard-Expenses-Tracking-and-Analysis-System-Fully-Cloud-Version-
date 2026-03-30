import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fully_cloud_sguard/data/services/record_book_store.dart';
import 'package:fully_cloud_sguard/presentation/pages/analysis/analysispage.dart';
import 'package:fully_cloud_sguard/presentation/pages/analysis/graph_detail_page.dart';
import 'package:fully_cloud_sguard/presentation/pages/home/homepage.dart';
import 'package:fully_cloud_sguard/presentation/pages/profile/managerecordpage.dart';
import 'package:fully_cloud_sguard/presentation/pages/profile/record_export_page.dart';
import 'package:fully_cloud_sguard/presentation/pages/profile/settingpage.dart';
import 'package:fully_cloud_sguard/presentation/pages/recordbook/recordbookpage.dart';

void main() {
  setUp(() {
    _resetRecordBookData();
  });

  tearDown(() {
    _resetRecordBookData();
  });

  group('SettingPage', () {
    testWidgets('renders the planned settings rows', (tester) async {
      await tester.pumpWidget(_wrap(const SettingPage()));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Tracking System'), findsOneWidget);
      expect(find.text('Personalization'), findsOneWidget);
    });
  });

  group('ManageRecordPage', () {
    testWidgets('renders month-filtered records and opens export page', (tester) async {
      final snapshot = DailyRecordSnapshot(
        dateKey: '2026-02-10',
        balance: 900,
        categories: [
          SpendingCategory(
            name: 'Food',
            items: [SpendingItem(name: 'Lunch', amount: 120, date: DateTime(2026, 2, 10))],
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          ManageRecordPage(
            dateKeysLoader: () async => ['2026-02-10', '2026-02-09', '2026-01-15'],
            snapshotLoader: (dateKey) async => snapshot,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manage Records'), findsOneWidget);
      expect(find.text('February 10, 2026'), findsOneWidget);
      expect(find.text('February 9, 2026'), findsOneWidget);
      expect(find.text('January 15, 2026'), findsNothing);
      expect(find.text('Export PDF'), findsNothing);

      await tester.tap(find.byTooltip('Open export page'));
      await tester.pumpAndSettle();

      expect(find.byType(RecordExportPage), findsOneWidget);
      expect(find.text('Record Export'), findsOneWidget);
    });
  });

  group('RecordExportPage', () {
    testWidgets('shows preview data for selected snapshot', (tester) async {
      final snapshot = DailyRecordSnapshot(
        dateKey: '2026-02-10',
        balance: 700,
        categories: [
          SpendingCategory(
            name: 'Food',
            items: [SpendingItem(name: 'Lunch', amount: 120, date: DateTime(2026, 2, 10))],
          ),
          SpendingCategory(
            name: 'Billing',
            items: [SpendingItem(name: 'Internet', amount: 80, date: DateTime(2026, 2, 10))],
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          RecordExportPage(
            initialDateKey: '2026-02-10',
            dateKeysLoader: () async => ['2026-02-10'],
            snapshotLoader: (dateKey) async => snapshot,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Record Export'), findsOneWidget);
      expect(find.text('February 10, 2026'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Internet'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
    });
  });

  group('HomePageContent', () {
    testWidgets('shows empty-state copy when yesterday has no spending', (tester) async {
      await _setLargeSurface(tester);
      RecordBookData.activeDate = DateTime(2026, 3, 24);
      RecordBookData.balance = 500;
      RecordBookData.notifyListeners();

      await tester.pumpWidget(_wrap(const HomePageContent()));

      expect(find.text('No spending data for yesterday.'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
      expect(find.textContaining('Current day:  0.00'), findsOneWidget);
    });

    testWidgets('tapping yesterday pie chart opens graph detail page', (tester) async {
      await _setLargeSurface(tester);
      RecordBookData.activeDate = DateTime(2026, 3, 24);
      RecordBookData.balance = 1000;
      RecordBookData.categories = [
        SpendingCategory(
          name: 'Food',
          items: [SpendingItem(name: 'Lunch', amount: 120, date: DateTime(2026, 3, 23))],
        ),
        SpendingCategory(
          name: 'Billing',
          items: [SpendingItem(name: 'Internet', amount: 80, date: DateTime(2026, 3, 23))],
        ),
      ];
      RecordBookData.notifyListeners();

      await tester.pumpWidget(_wrap(const HomePageContent()));
      await tester.tap(find.byType(PieChart));
      await tester.pumpAndSettle();

      expect(find.byType(GraphDetailPage), findsOneWidget);
      expect(find.text('March 23, 2026'), findsOneWidget);
      expect(find.text('Underlying Records'), findsOneWidget);
    });
  });

  group('AnalysisPage', () {
    testWidgets('shows no-spent placeholder for empty daily charts', (tester) async {
      RecordBookData.activeDate = DateTime.now();
      RecordBookData.balance = 300;
      RecordBookData.notifyListeners();

      await tester.pumpWidget(_wrap(const AnalysisPage()));

      expect(find.text('No spent'), findsNWidgets(2));
      expect(find.byType(BarChart), findsNWidgets(6));
    });

    testWidgets('tapping populated chart opens graph detail page', (tester) async {
      final activeDate = DateTime(2026, 3, 24);
      final yesterday = DateTime(2026, 3, 23);

      RecordBookData.activeDate = activeDate;
      RecordBookData.balance = 1000;
      RecordBookData.categories = [
        SpendingCategory(
          name: 'Food',
          items: [
            SpendingItem(name: 'Breakfast', amount: 100, date: activeDate),
            SpendingItem(name: 'Dinner', amount: 75, date: yesterday),
          ],
        ),
        SpendingCategory(
          name: 'Billing',
          items: [
            SpendingItem(name: 'Power', amount: 50, date: activeDate),
            SpendingItem(name: 'Water', amount: 25, date: yesterday),
          ],
        ),
      ];
      RecordBookData.notifyListeners();

      await tester.pumpWidget(_wrap(const AnalysisPage()));
      await tester.tap(find.byType(PieChart).first);
      await tester.pumpAndSettle();

      expect(find.byType(GraphDetailPage), findsOneWidget);
      expect(find.text('Underlying Records'), findsOneWidget);
      expect(find.textContaining('Mar 23, 2026'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _resetRecordBookData() {
  RecordBookData.balance = 0;
  RecordBookData.activeDate = DateTime(2026, 3, 24);
  RecordBookData.categories = [
    SpendingCategory(name: 'Billing'),
    SpendingCategory(name: 'Food'),
    SpendingCategory(name: 'Others'),
  ];
  RecordBookData.revision.value = 0;
}
