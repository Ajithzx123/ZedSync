import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-wide preferences. Persistence comes later; values live in memory.
class SettingsController extends GetxController {
  final baseCurrency = 'USD'.obs;
  final privacyMode = false.obs;
  final themeMode = ThemeMode.system.obs;

  static const currencies = ['USD', 'EUR', 'GBP', 'INR'];

  void togglePrivacy() => privacyMode.toggle();

  void setBaseCurrency(String ccy) => baseCurrency.value = ccy;

  void setThemeMode(ThemeMode m) {
    themeMode.value = m;
    Get.changeThemeMode(m);
  }
}
