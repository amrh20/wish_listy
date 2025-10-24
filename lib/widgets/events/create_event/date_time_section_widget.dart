import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../services/localization_service.dart';

/// Widget for date and time selection
class DateTimeSectionWidget extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onDateSelected;
  final VoidCallback onTimeSelected;
  final String Function(DateTime) formatDate;
  final String Function(TimeOfDay) formatTime;

  const DateTimeSectionWidget({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_outlined, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.whenIsYourEvent'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Date Selector
              Expanded(
                child: GestureDetector(
                  onTap: onDateSelected,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedDate != null
                            ? AppColors.info
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: selectedDate != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: selectedDate != null
                              ? AppColors.info
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localization.translate('events.date'),
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedDate != null
                                    ? formatDate(selectedDate!)
                                    : localization.translate(
                                        'events.selectDate',
                                      ),
                                style: AppStyles.bodyMedium.copyWith(
                                  color: selectedDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                  fontWeight: selectedDate != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Time Selector
              Expanded(
                child: GestureDetector(
                  onTap: onTimeSelected,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedTime != null
                            ? AppColors.info
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: selectedTime != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          color: selectedTime != null
                              ? AppColors.info
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localization.translate('events.time'),
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedTime != null
                                    ? formatTime(selectedTime!)
                                    : localization.translate(
                                        'events.selectTime',
                                      ),
                                style: AppStyles.bodyMedium.copyWith(
                                  color: selectedTime != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                  fontWeight: selectedTime != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
