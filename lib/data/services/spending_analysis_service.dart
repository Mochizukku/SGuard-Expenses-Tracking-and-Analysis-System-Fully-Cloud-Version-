import '../../presentation/pages/recordbook/recordbookpage.dart';
import 'record_book_store.dart';

class SpendingAnalysisService {
  SpendingAnalysisService._();

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static bool isWithinRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static List<SpendingCategory> categoriesInRange(
    List<SpendingCategory> categories,
    DateTime start,
    DateTime end,
  ) {
    return categories
        .map(
          (category) {
            final items = category.items
                .where((item) => isWithinRange(item.date, start, end))
                .map(
                  (item) => SpendingItem(
                    name: item.name,
                    amount: item.amount,
                    date: item.date,
                  ),
                )
                .toList();

            return SpendingCategory(
              name: category.name,
              isExpanded: category.isExpanded,
              isFavorite: category.isFavorite,
              items: items,
            );
          },
        )
        .where((category) => category.items.isNotEmpty)
        .toList();
  }

  static Map<String, double> categoryTotalsInRange(
    List<SpendingCategory> categories,
    DateTime start,
    DateTime end,
  ) {
    final filtered = categoriesInRange(categories, start, end);
    return {
      for (final category in filtered) category.name: category.total,
    };
  }

  static double totalInRange(
    List<SpendingCategory> categories,
    DateTime start,
    DateTime end,
  ) {
    return categoriesInRange(categories, start, end)
        .fold<double>(0.0, (sum, category) => sum + category.total);
  }

  static Future<List<SpendingCategory>> historicalCategoriesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final summary = await RecordBookStore.summarizeHistoryRange(start, end);
    return summary.categories;
  }

  static Future<Map<String, double>> historicalCategoryTotalsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final summary = await RecordBookStore.summarizeHistoryRange(start, end);
    return summary.categoryTotals;
  }

  static Future<double> historicalTotalInRange(
    DateTime start,
    DateTime end,
  ) async {
    final summary = await RecordBookStore.summarizeHistoryRange(start, end);
    return summary.total;
  }
}
