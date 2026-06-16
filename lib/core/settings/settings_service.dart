import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  String get apiBaseUrl => _normalizeApiBaseUrl(
        _prefs.getString(AppConstants.apiBaseUrlKey) ??
            AppConstants.defaultApiBaseUrl,
      );

  Future<void> setApiBaseUrl(String url) => _prefs.setString(
        AppConstants.apiBaseUrlKey,
        _normalizeApiBaseUrl(url),
      );

  static String _normalizeApiBaseUrl(String url) {
    var base = url.trim();
    if (base.isEmpty) return AppConstants.defaultApiBaseUrl;
    base = base.replaceAll(RegExp(r'/+$'), '');
    const suffix = '/api/v1';
    if (base.endsWith(suffix)) {
      base = base.substring(0, base.length - suffix.length);
    }
    return base.replaceAll(RegExp(r'/+$'), '');
  }

  bool get offlineCashOnly =>
      _prefs.getBool(AppConstants.offlineCashOnlyKey) ?? false;

  Future<void> setOfflineCashOnly(bool value) =>
      _prefs.setBool(AppConstants.offlineCashOnlyKey, value);

  String get localeCode =>
      _prefs.getString(AppConstants.localeCodeKey) ??
      AppConstants.defaultLocaleCode;

  Locale get locale => Locale(localeCode);

  Future<void> setLocaleCode(String code) =>
      _prefs.setString(AppConstants.localeCodeKey, code);

  bool get autoPrintOnSale =>
      _prefs.getBool(AppConstants.autoPrintOnSaleKey) ?? false;

  Future<void> setAutoPrintOnSale(bool value) =>
      _prefs.setBool(AppConstants.autoPrintOnSaleKey, value);

  String? get posBranchId => _prefs.getString(AppConstants.posBranchIdKey);

  Future<void> setPosBranchId(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(AppConstants.posBranchIdKey);
    } else {
      await _prefs.setString(AppConstants.posBranchIdKey, id);
    }
  }

  String? get adminBranchFilterId =>
      _prefs.getString(AppConstants.adminBranchFilterIdKey);

  Future<void> setAdminBranchFilterId(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(AppConstants.adminBranchFilterIdKey);
    } else {
      await _prefs.setString(AppConstants.adminBranchFilterIdKey, id);
    }
  }
}
