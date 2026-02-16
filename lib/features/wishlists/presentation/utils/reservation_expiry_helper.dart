import 'package:wish_listy/core/services/localization_service.dart';

/// Result of formatting a reservation expiry date for display.
class ReservationExpiryFormat {
  const ReservationExpiryFormat({required this.text, required this.isUrgent});
  final String text;
  /// True when expiration is today or tomorrow (use amber/warning color).
  final bool isUrgent;
}

/// Shared logic for formatting [reservedUntil] for display.
/// Reused by ItemActionBarWidget and WishlistItemCardWidget.
ReservationExpiryFormat formatReservationExpiry(
  DateTime reservedUntil,
  LocalizationService localization,
) {
  final now = DateTime.now();
  final atMidnight = DateTime(reservedUntil.year, reservedUntil.month, reservedUntil.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = atMidnight.difference(today).inDays;

  if (days <= 0) {
    return ReservationExpiryFormat(
      text: localization.translate('details.expiresToday'),
      isUrgent: true,
    );
  }
  if (days == 1) {
    return ReservationExpiryFormat(
      text: localization.translate('details.expiresTomorrow'),
      isUrgent: true,
    );
  }
  if (days <= 14) {
    final key = localization.translate('details.expiresInDays');
    final text = key.contains('{count}') ? key.replaceAll('{count}', '$days') : 'Expires in $days days';
    return ReservationExpiryFormat(text: text, isUrgent: false);
  }
  final key = localization.translate('details.expiresOn');
  final dateStr = '${reservedUntil.day}/${reservedUntil.month}/${reservedUntil.year}';
  final text = key.contains('{date}') ? key.replaceAll('{date}', dateStr) : 'Expires on $dateStr';
  return ReservationExpiryFormat(text: text, isUrgent: false);
}
