import 'package:intl/intl.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class ChatDateFormatter {
  static String _languageCode() => LocalizationService().currentLanguage;

  static String formatTime(DateTime dateTime) {
    final locale = _languageCode();
    final localTime = dateTime.toLocal();
    return DateFormat.jm(locale).format(localTime);
  }

  static String formatConversationTime(DateTime dateTime) {
    final locale = _languageCode();
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final isToday = _isSameDay(localTime, now);
    final isYesterday = _isSameDay(
      localTime,
      now.subtract(const Duration(days: 1)),
    );

    if (isToday) {
      return DateFormat.jm(locale).format(localTime);
    }
    if (isYesterday) {
      return locale == 'ar' ? 'أمس' : 'Yesterday';
    }
    if (now.difference(localTime).inDays < 7) {
      return DateFormat.E(locale).format(localTime);
    }
    return DateFormat.yMd(locale).format(localTime);
  }

  static String formatMessageHeader(DateTime dateTime) {
    final locale = _languageCode();
    final localTime = dateTime.toLocal();
    final now = DateTime.now();

    if (_isSameDay(localTime, now)) {
      final time = DateFormat.jm(locale).format(localTime);
      return locale == 'ar' ? 'اليوم $time' : 'Today at $time';
    }

    if (_isSameDay(localTime, now.subtract(const Duration(days: 1)))) {
      final time = DateFormat.jm(locale).format(localTime);
      return locale == 'ar' ? 'أمس $time' : 'Yesterday at $time';
    }

    return DateFormat('EEE, MMM d • jm', locale).format(localTime);
  }

  static String formatMessageGroupDate(DateTime dateTime) {
    final locale = _languageCode();
    final localTime = dateTime.toLocal();
    final now = DateTime.now();

    if (_isSameDay(localTime, now)) {
      return locale == 'ar' ? 'اليوم' : 'Today';
    }
    if (_isSameDay(localTime, now.subtract(const Duration(days: 1)))) {
      return locale == 'ar' ? 'أمس' : 'Yesterday';
    }
    if (now.difference(localTime).inDays < 7) {
      return DateFormat.EEEE(locale).format(localTime);
    }
    return DateFormat.yMMMd(locale).format(localTime);
  }

  static bool shouldShowDateSeparator({
    required DateTime current,
    required DateTime? previous,
  }) {
    if (previous == null) return true;
    return !_isSameDay(current.toLocal(), previous.toLocal());
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
