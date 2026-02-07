import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'app_constants.dart';

class AppUtils {
  // Validation Utilities
  static bool isValidEmail(String email) {
    return RegExp(AppConstants.emailRegex).hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength &&
        password.length <= AppConstants.maxPasswordLength &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password);
  }

  static bool isValidUrl(String url) {
    return RegExp(AppConstants.urlRegex).hasMatch(url);
  }

  static bool isValidPhoneNumber(String phone) {
    return RegExp(AppConstants.phoneRegex).hasMatch(phone);
  }

  // String Utilities
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String truncateText(
    String text,
    int maxLength, {
    bool addEllipsis = true,
  }) {
    if (text.length <= maxLength) return text;
    return addEllipsis
        ? '${text.substring(0, maxLength)}...'
        : text.substring(0, maxLength);
  }

  static String generateInitials(String name) {
    List<String> names = name.trim().split(' ');
    if (names.isEmpty) return '';

    String initials = '';
    for (int i = 0; i < min(2, names.length); i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials;
  }

  static String formatCurrency(double amount, String currency) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  // Date Utilities
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String formatDate(
    DateTime dateTime, {
    String format = AppConstants.longDateFormat,
  }) {
    final months = [
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

    switch (format) {
      case AppConstants.shortDateFormat:
        return '${months[dateTime.month - 1].substring(0, 3)} ${dateTime.day}';
      case AppConstants.longDateFormat:
        return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
      default:
        return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }
  }

  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  static bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return dateTime.isAfter(weekStart);
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Color Utilities
  static Color darkenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color lightenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  static Color getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Device Utilities
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;

  static void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static void hapticFeedback([
    HapticFeedbackType type = HapticFeedbackType.lightImpact,
  ]) {
    switch (type) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  // Navigation Utilities
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppColors.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppColors.error);
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppColors.success);
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppColors.warning);
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? AppColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // File Utilities
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  static bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Random Utilities
  static String generateRandomId([int length = 8]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static Color generateRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1.0,
    );
  }

  // Debug Utilities
  static void debugLog(String message, [String tag = 'AppUtils']) {

  }

  static void debugLogError(String error, [StackTrace? stackTrace]) {
  }

  // Preference Utilities
  static String getGreeting() {
    return 'Welcome back';
  }

  static String getEventTypeEmoji(String eventType) {
    return AppConstants.eventTypeEmojis[eventType] ?? '🎈';
  }

  static int getPriorityLevel(String priority) {
    return AppConstants.priorityLevels[priority] ?? 2;
  }

  // List Utilities
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<T> shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    shuffled.shuffle();
    return shuffled;
  }

  static T? getRandomElement<T>(List<T> list) {
    if (list.isEmpty) return null;
    final random = Random();
    return list[random.nextInt(list.length)];
  }

  // Animation Utilities
  static Widget buildFadeInAnimation(
    Widget child, {
    Duration duration = AppConstants.mediumAnimation,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  static Widget buildSlideInAnimation(
    Widget child, {
    Offset begin = const Offset(0, 1),
    Duration duration = AppConstants.mediumAnimation,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: Offset.zero),
      duration: duration,
      builder: (context, value, child) {
        return Transform.translate(offset: value, child: child);
      },
      child: child,
    );
  }
}

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}
