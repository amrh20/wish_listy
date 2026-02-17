import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Bottom sheet shown when the user taps "Reserve Gift" or "Extend".
/// Lets the user choose a deadline (within two weeks, within month, or custom date)
/// and confirms with that date.
class ReservationDeadlineBottomSheet extends StatefulWidget {
  final void Function(DateTime? reservedUntil) onConfirm;
  /// When true, title is "Select a new date" (for extending); otherwise "When do you plan to get this gift?".
  final bool isExtension;
  /// When extending, the current reservation end date; the date picker will pre-select this.
  final DateTime? initialDeadline;

  const ReservationDeadlineBottomSheet({
    super.key,
    required this.onConfirm,
    this.isExtension = false,
    this.initialDeadline,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(DateTime? reservedUntil) onConfirm,
    bool isExtension = false,
    DateTime? initialDeadline,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReservationDeadlineBottomSheet(
        onConfirm: onConfirm,
        isExtension: isExtension,
        initialDeadline: initialDeadline,
      ),
    );
  }

  @override
  State<ReservationDeadlineBottomSheet> createState() =>
      _ReservationDeadlineBottomSheetState();
}

class _ReservationDeadlineBottomSheetState
    extends State<ReservationDeadlineBottomSheet> {
  static const int _optionWithinTwoWeeks = 0;
  static const int _optionWithinMonth = 1;
  static const int _optionCustom = 2;

  int _selectedIndex = 0;
  DateTime? _customDate;

  @override
  void initState() {
    super.initState();
    if (widget.isExtension && widget.initialDeadline != null) {
      _selectedIndex = _optionCustom;
      _customDate = widget.initialDeadline;
    }
  }

  /// Base date for "2 weeks" / "1 month": when extending, use current deadline; otherwise today.
  DateTime get _baseDate {
    return (widget.isExtension && widget.initialDeadline != null)
        ? widget.initialDeadline!
        : DateTime.now();
  }

  /// Returns the chosen deadline. Custom date = exact picked date (absolute).
  /// When extending, "2 weeks" / "1 month" = current deadline + 14/30 days; when reserving = today + 14/30.
  DateTime? get _effectiveDate {
    switch (_selectedIndex) {
      case _optionWithinTwoWeeks:
        return _baseDate.add(const Duration(days: 14));
      case _optionWithinMonth:
        return _baseDate.add(const Duration(days: 30));
      case _optionCustom:
        return _customDate; // Always the exact date (and time) chosen by the user
      default:
        return null;
    }
  }

  /// DatePicker returns date-only (midnight local). We add current hour/minute
  /// so the backend gets a precise UTC instant and reminders fire at the right time.
  /// When extending, pre-select [initialDeadline] if it's in the valid range.
  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365));
    final initialDate = (widget.initialDeadline != null &&
            !widget.initialDeadline!.isBefore(firstDate) &&
            !widget.initialDeadline!.isAfter(lastDate))
        ? widget.initialDeadline!
        : (_customDate ?? firstDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null && mounted) {
      final withTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        now.hour,
        now.minute,
        now.second,
      );
      setState(() => _customDate = withTime);
    }
  }

  void _onConfirm() {
    final date = _effectiveDate;
    if (_selectedIndex == _optionCustom && date == null) {
      _pickCustomDate().then((_) {
        if (_customDate != null && mounted) {
          Navigator.of(context).pop();
          widget.onConfirm(_customDate);
        }
      });
      return;
    }
    Navigator.of(context).pop();
    widget.onConfirm(date);
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isExtension
                ? localization.translate('reservation.selectNewDateForReservation')
                : localization.translate('reservation.whenPlanToGetGift'),
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('reservation.expiryNote'),
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            title: localization.translate('reservation.withinTwoWeeks'),
            subtitle: _formatOptionDate(_baseDate.add(const Duration(days: 14))),
            isSelected: _selectedIndex == _optionWithinTwoWeeks,
            onTap: () => setState(() => _selectedIndex = _optionWithinTwoWeeks),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            title: localization.translate('reservation.withinMonth'),
            subtitle: _formatOptionDate(_baseDate.add(const Duration(days: 30))),
            isSelected: _selectedIndex == _optionWithinMonth,
            onTap: () => setState(() => _selectedIndex = _optionWithinMonth),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            title: localization.translate('reservation.customDate'),
            subtitle: _selectedIndex == _optionCustom && _customDate != null
                ? _formatOptionDate(_customDate!)
                : localization.translate('reservation.tapToPickDate'),
            isSelected: _selectedIndex == _optionCustom,
            onTap: () async {
              setState(() => _selectedIndex = _optionCustom);
              await _pickCustomDate();
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: localization.translate('reservation.confirmReservation'),
            onPressed: _onConfirm,
            variant: ButtonVariant.gradient,
            gradientColors: const [AppColors.primary, AppColors.secondary],
            icon: Icons.check_circle_outline,
            size: ButtonSize.large,
          ),
        ],
      ),
    );
  }

  String _formatOptionDate(DateTime date) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final locale = localization.currentLanguage == 'ar' ? 'ar' : 'en';
    return DateFormat.yMMMd(locale).format(date);
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withOpacity(0.08)
          : AppColors.surfaceVariant.withOpacity(0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
