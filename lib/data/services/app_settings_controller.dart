import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProfileSettings {
  const AppProfileSettings({
    required this.displayName,
    required this.status,
    required this.avatarKey,
  });

  final String displayName;
  final String status;
  final String avatarKey;

  AppProfileSettings copyWith({
    String? displayName,
    String? status,
    String? avatarKey,
  }) {
    return AppProfileSettings(
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      avatarKey: avatarKey ?? this.avatarKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'status': status,
      'avatarKey': avatarKey,
    };
  }

  factory AppProfileSettings.fromJson(Map<String, dynamic> json) {
    return AppProfileSettings(
      displayName: json['displayName'] as String? ?? '',
      status: json['status'] as String? ?? 'Student',
      avatarKey: json['avatarKey'] as String? ?? 'classic_blue',
    );
  }
}

class TrackingSettings {
  const TrackingSettings({
    required this.autoSaveHistoryCache,
    required this.cloudSyncReminder,
    required this.openLastActiveDate,
    required this.confirmResetSensitiveActions,
    required this.showActiveDateBadge,
  });

  final bool autoSaveHistoryCache;
  final bool cloudSyncReminder;
  final bool openLastActiveDate;
  final bool confirmResetSensitiveActions;
  final bool showActiveDateBadge;

  TrackingSettings copyWith({
    bool? autoSaveHistoryCache,
    bool? cloudSyncReminder,
    bool? openLastActiveDate,
    bool? confirmResetSensitiveActions,
    bool? showActiveDateBadge,
  }) {
    return TrackingSettings(
      autoSaveHistoryCache: autoSaveHistoryCache ?? this.autoSaveHistoryCache,
      cloudSyncReminder: cloudSyncReminder ?? this.cloudSyncReminder,
      openLastActiveDate: openLastActiveDate ?? this.openLastActiveDate,
      confirmResetSensitiveActions:
          confirmResetSensitiveActions ?? this.confirmResetSensitiveActions,
      showActiveDateBadge: showActiveDateBadge ?? this.showActiveDateBadge,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSaveHistoryCache': autoSaveHistoryCache,
      'cloudSyncReminder': cloudSyncReminder,
      'openLastActiveDate': openLastActiveDate,
      'confirmResetSensitiveActions': confirmResetSensitiveActions,
      'showActiveDateBadge': showActiveDateBadge,
    };
  }

  factory TrackingSettings.fromJson(Map<String, dynamic> json) {
    return TrackingSettings(
      autoSaveHistoryCache: json['autoSaveHistoryCache'] as bool? ?? true,
      cloudSyncReminder: json['cloudSyncReminder'] as bool? ?? true,
      openLastActiveDate: json['openLastActiveDate'] as bool? ?? false,
      confirmResetSensitiveActions:
          json['confirmResetSensitiveActions'] as bool? ?? true,
      showActiveDateBadge: json['showActiveDateBadge'] as bool? ?? true,
    );
  }
}

class PersonalizationSettings {
  const PersonalizationSettings({
    required this.themeMode,
    required this.compactCards,
    required this.showQuickHints,
    required this.largeText,
    required this.reduceMotion,
    required this.showCurrencySymbol,
    required this.startPageIndex,
    required this.accentColorKey,
  });

  final ThemeMode themeMode;
  final bool compactCards;
  final bool showQuickHints;
  final bool largeText;
  final bool reduceMotion;
  final bool showCurrencySymbol;
  final int startPageIndex;
  final String accentColorKey;

  PersonalizationSettings copyWith({
    ThemeMode? themeMode,
    bool? compactCards,
    bool? showQuickHints,
    bool? largeText,
    bool? reduceMotion,
    bool? showCurrencySymbol,
    int? startPageIndex,
    String? accentColorKey,
  }) {
    return PersonalizationSettings(
      themeMode: themeMode ?? this.themeMode,
      compactCards: compactCards ?? this.compactCards,
      showQuickHints: showQuickHints ?? this.showQuickHints,
      largeText: largeText ?? this.largeText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      showCurrencySymbol: showCurrencySymbol ?? this.showCurrencySymbol,
      startPageIndex: startPageIndex ?? this.startPageIndex,
      accentColorKey: accentColorKey ?? this.accentColorKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'compactCards': compactCards,
      'showQuickHints': showQuickHints,
      'largeText': largeText,
      'reduceMotion': reduceMotion,
      'showCurrencySymbol': showCurrencySymbol,
      'startPageIndex': startPageIndex,
      'accentColorKey': accentColorKey,
    };
  }

  factory PersonalizationSettings.fromJson(Map<String, dynamic> json) {
    final themeName = json['themeMode'] as String?;
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => ThemeMode.system,
    );
    return PersonalizationSettings(
      themeMode: themeMode,
      compactCards: json['compactCards'] as bool? ?? false,
      showQuickHints: json['showQuickHints'] as bool? ?? true,
      largeText: json['largeText'] as bool? ?? false,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      showCurrencySymbol: json['showCurrencySymbol'] as bool? ?? true,
      startPageIndex: json['startPageIndex'] as int? ?? 0,
      accentColorKey: json['accentColorKey'] as String? ?? 'blue',
    );
  }
}

class AppSettingsData {
  const AppSettingsData({
    required this.profile,
    required this.tracking,
    required this.personalization,
  });

  final AppProfileSettings profile;
  final TrackingSettings tracking;
  final PersonalizationSettings personalization;

  AppSettingsData copyWith({
    AppProfileSettings? profile,
    TrackingSettings? tracking,
    PersonalizationSettings? personalization,
  }) {
    return AppSettingsData(
      profile: profile ?? this.profile,
      tracking: tracking ?? this.tracking,
      personalization: personalization ?? this.personalization,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'tracking': tracking.toJson(),
      'personalization': personalization.toJson(),
    };
  }

  factory AppSettingsData.fromJson(Map<String, dynamic> json) {
    return AppSettingsData(
      profile: AppProfileSettings.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? const {}),
      ),
      tracking: TrackingSettings.fromJson(
        Map<String, dynamic>.from(json['tracking'] as Map? ?? const {}),
      ),
      personalization: PersonalizationSettings.fromJson(
        Map<String, dynamic>.from(json['personalization'] as Map? ?? const {}),
      ),
    );
  }

  factory AppSettingsData.defaults() {
    return const AppSettingsData(
      profile: AppProfileSettings(
        displayName: '',
        status: 'Student',
        avatarKey: 'classic_blue',
      ),
      tracking: TrackingSettings(
        autoSaveHistoryCache: true,
        cloudSyncReminder: true,
        openLastActiveDate: false,
        confirmResetSensitiveActions: true,
        showActiveDateBadge: true,
      ),
      personalization: PersonalizationSettings(
        themeMode: ThemeMode.system,
        compactCards: false,
        showQuickHints: true,
        largeText: false,
        reduceMotion: false,
        showCurrencySymbol: true,
        startPageIndex: 0,
        accentColorKey: 'blue',
      ),
    );
  }
}

class AppSettingsController {
  AppSettingsController._();

  static const _storageKey = 'sguard_app_settings_v1';
  static final AppSettingsController instance = AppSettingsController._();

  final ValueNotifier<AppSettingsData> settings =
      ValueNotifier<AppSettingsData>(AppSettingsData.defaults());

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        settings.value = AppSettingsData.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {
        settings.value = AppSettingsData.defaults();
      }
    }
    _isInitialized = true;
  }

  Future<void> updateProfile(AppProfileSettings profile) async {
    await _update(settings.value.copyWith(profile: profile));
  }

  Future<void> updateTracking(TrackingSettings tracking) async {
    await _update(settings.value.copyWith(tracking: tracking));
  }

  Future<void> updatePersonalization(
    PersonalizationSettings personalization,
  ) async {
    await _update(settings.value.copyWith(personalization: personalization));
  }

  Future<void> _update(AppSettingsData next) async {
    settings.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(next.toJson()));
  }

  static Color accentColorFromKey(String key) {
    switch (key) {
      case 'emerald':
        return const Color(0xFF147D64);
      case 'sunset':
        return const Color(0xFFC05621);
      case 'slate':
        return const Color(0xFF334155);
      default:
        return const Color(0xFF004AAD);
    }
  }
}
