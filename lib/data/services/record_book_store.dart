import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/pages/recordbook/recordbookpage.dart';

class DailyRecordSnapshot {
  DailyRecordSnapshot({
    required this.dateKey,
    required this.balance,
    required this.categories,
  });

  final String dateKey;
  final double balance;
  final List<SpendingCategory> categories;

  Map<String, dynamic> toCloudMap() {
    return {
      'datas': {
        'balance': balance,
        'dateKey': dateKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'records': categories.map((category) => category.toJson()).toList(),
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'datas': {
        'balance': balance,
        'dateKey': dateKey,
      },
      'records': categories.map((category) => category.toJson()).toList(),
    };
  }

  factory DailyRecordSnapshot.fromMap(Map<String, dynamic> map, {String? fallbackDateKey}) {
    final datas = (map['datas'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final rawRecords = map['records'] as List<dynamic>? ?? map['categories'] as List<dynamic>? ?? const [];

    return DailyRecordSnapshot(
      dateKey: (datas['dateKey'] as String?) ?? fallbackDateKey ?? RecordBookStore.dateKeyFromDate(DateTime.now()),
      balance: (datas['balance'] as num?)?.toDouble() ?? (map['balance'] as num?)?.toDouble() ?? 0.0,
      categories: rawRecords
          .map((record) => SpendingCategory.fromJson(Map<String, dynamic>.from(record as Map)))
          .toList(),
    );
  }
}

class PrepareTodayResult {
  const PrepareTodayResult({
    required this.didReset,
    required this.serverDateKey,
  });

  final bool didReset;
  final String serverDateKey;
}

class RecordBookStore {
  RecordBookStore._();

  static const _localSnapshotKey = 'record_book_local_snapshot_v2';

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static List<SpendingCategory> defaultCategories() {
    return [
      SpendingCategory(name: 'Billing'),
      SpendingCategory(name: 'Food'),
      SpendingCategory(name: 'Others'),
    ];
  }

  static DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  static String dateKeyFromDate(DateTime date) {
    final normalized = normalizeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  static DateTime dateFromKey(String dateKey) => DateTime.parse(dateKey);

  static List<SpendingCategory> cloneCategories(
    List<SpendingCategory> categories, {
    bool clearItems = false,
  }) {
    return categories
        .map(
          (category) => SpendingCategory(
            name: category.name,
            isExpanded: category.isExpanded,
            isFavorite: category.isFavorite,
            items: clearItems
                ? <SpendingItem>[]
                : category.items
                    .map(
                      (item) => SpendingItem(
                        name: item.name,
                        amount: item.amount,
                        date: item.date,
                      ),
                    )
                    .toList(),
          ),
        )
        .toList();
  }

  static List<SpendingCategory> emptyCategoriesFromTemplate(List<SpendingCategory> categories) {
    final template = categories.isEmpty ? defaultCategories() : categories;
    return cloneCategories(template, clearItems: true);
  }

  static DailyRecordSnapshot buildCurrentSnapshot() {
    final activeDate = normalizeDate(RecordBookData.activeDate);
    return DailyRecordSnapshot(
      dateKey: dateKeyFromDate(activeDate),
      balance: RecordBookData.balance,
      categories: cloneCategories(RecordBookData.categories),
    );
  }

  static void applySnapshot(DailyRecordSnapshot snapshot) {
    RecordBookData.balance = snapshot.balance;
    RecordBookData.activeDate = dateFromKey(snapshot.dateKey);
    RecordBookData.categories = snapshot.categories.isEmpty
        ? defaultCategories()
        : cloneCategories(snapshot.categories);
    RecordBookData.notifyListeners();
  }

  static Future<void> saveLocalSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localSnapshotKey, jsonEncode(buildCurrentSnapshot().toLocalMap()));
  }

  static Future<void> loadLocalSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localSnapshotKey);
    if (raw == null || raw.isEmpty) {
      applySnapshot(
        DailyRecordSnapshot(
          dateKey: dateKeyFromDate(DateTime.now()),
          balance: RecordBookData.balance,
          categories: defaultCategories(),
        ),
      );
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      applySnapshot(DailyRecordSnapshot.fromMap(decoded));
    } catch (_) {
      applySnapshot(
        DailyRecordSnapshot(
          dateKey: dateKeyFromDate(DateTime.now()),
          balance: RecordBookData.balance,
          categories: defaultCategories(),
        ),
      );
    }
  }

  static Future<void> saveCurrentToCloud() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final snapshot = buildCurrentSnapshot();
    await _saveSnapshotForUser(user.uid, snapshot, updateResetDay: false);
  }

  static Future<void> _saveSnapshotForUser(
    String userId,
    DailyRecordSnapshot snapshot, {
    required bool updateResetDay,
  }) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final metadata = <String, dynamic>{
      'lastSavedDate': snapshot.dateKey,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (updateResetDay) {
      metadata['lastResetDay'] = snapshot.dateKey;
    }
    await userDoc.set(metadata, SetOptions(merge: true));
    await userDoc.collection('dates').doc(snapshot.dateKey).set(snapshot.toCloudMap(), SetOptions(merge: true));
    await saveLocalSnapshot();
  }

  static Future<List<String>> listCloudDateKeys() async {
    final user = _auth.currentUser;
    if (user == null) {
      return <String>[];
    }

    await _migrateLegacySnapshotIfNeeded(user.uid);
    final collection = await _firestore.collection('users').doc(user.uid).collection('dates').get();
    final keys = collection.docs.map((doc) => doc.id).toList()..sort((a, b) => b.compareTo(a));
    return keys;
  }

  static Future<DailyRecordSnapshot?> fetchCloudSnapshotByDateKey(String dateKey) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    await _migrateLegacySnapshotIfNeeded(user.uid);
    final doc = await _firestore.collection('users').doc(user.uid).collection('dates').doc(dateKey).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return DailyRecordSnapshot.fromMap(doc.data()!, fallbackDateKey: doc.id);
  }

  static Future<DailyRecordSnapshot?> loadCloudSnapshotByDateKey(String dateKey) async {
    final snapshot = await fetchCloudSnapshotByDateKey(dateKey);
    if (snapshot == null) {
      return null;
    }

    applySnapshot(snapshot);
    await saveLocalSnapshot();
    return snapshot;
  }

  static Future<DailyRecordSnapshot?> loadLatestCloudSnapshot() async {
    final keys = await listCloudDateKeys();
    if (keys.isEmpty) {
      return null;
    }
    return loadCloudSnapshotByDateKey(keys.first);
  }

  static Future<PrepareTodayResult> prepareTodayForAuthenticatedUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      final localDateKey = dateKeyFromDate(RecordBookData.activeDate);
      return PrepareTodayResult(didReset: false, serverDateKey: localDateKey);
    }

    await _migrateLegacySnapshotIfNeeded(user.uid);

    final serverNow = await _fetchServerNow(user.uid);
    final serverDateKey = dateKeyFromDate(serverNow.toLocal());
    final userDoc = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userDoc.get();
    final userData = userSnapshot.data() ?? <String, dynamic>{};
    final lastResetDay = userData['lastResetDay'] as String?;

    if (lastResetDay == serverDateKey) {
      if (dateKeyFromDate(RecordBookData.activeDate) != serverDateKey) {
        final todaySnapshot = await fetchCloudSnapshotByDateKey(serverDateKey);
        if (todaySnapshot != null) {
          applySnapshot(todaySnapshot);
          await saveLocalSnapshot();
        }
      }
      return PrepareTodayResult(didReset: false, serverDateKey: serverDateKey);
    }

    final todayDoc = await userDoc.collection('dates').doc(serverDateKey).get();
    DailyRecordSnapshot snapshot;

    if (todayDoc.exists && todayDoc.data() != null) {
      snapshot = DailyRecordSnapshot.fromMap(todayDoc.data()!, fallbackDateKey: serverDateKey);
    } else {
      final templateCategories = RecordBookData.categories.isEmpty
          ? defaultCategories()
          : emptyCategoriesFromTemplate(RecordBookData.categories);
      snapshot = DailyRecordSnapshot(
        dateKey: serverDateKey,
        balance: RecordBookData.balance,
        categories: templateCategories,
      );
      await _saveSnapshotForUser(user.uid, snapshot, updateResetDay: true);
    }

    await userDoc.set(
      {
        'lastResetDay': serverDateKey,
        'lastServerClockAt': Timestamp.fromDate(serverNow),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    applySnapshot(snapshot);
    await saveLocalSnapshot();

    return PrepareTodayResult(didReset: true, serverDateKey: serverDateKey);
  }

  static Future<void> _migrateLegacySnapshotIfNeeded(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final doc = await userDoc.get();
    final data = doc.data();
    if (data == null || data['categories'] == null) {
      return;
    }

    final migratedDateKey = dateKeyFromDate(DateTime.now());
    final datesDoc = await userDoc.collection('dates').doc(migratedDateKey).get();
    if (!datesDoc.exists) {
      final legacySnapshot = DailyRecordSnapshot(
        dateKey: migratedDateKey,
        balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
        categories: (data['categories'] as List<dynamic>? ?? const [])
            .map((entry) => SpendingCategory.fromJson(Map<String, dynamic>.from(entry as Map)))
            .toList(),
      );
      await _saveSnapshotForUser(userId, legacySnapshot, updateResetDay: false);
    }

    await userDoc.set(
      {
        'categories': FieldValue.delete(),
        'startDate': FieldValue.delete(),
        'endDate': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<DateTime> _fetchServerNow(String userId) async {
    final clockDoc = _firestore.collection('users').doc(userId).collection('_system').doc('clock');
    await clockDoc.set({'serverNow': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    final snapshot = await clockDoc.get();
    final timestamp = snapshot.data()?['serverNow'] as Timestamp?;
    return timestamp?.toDate() ?? DateTime.now().toUtc();
  }
}
