import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import 'event_type_selection_widget.dart';

/// Widget for event preview
class EventPreviewWidget extends StatelessWidget {
  final String eventName;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String? location;
  final EventTypeOption selectedEventType;
  final String Function(DateTime) formatDate;
  final String Function(TimeOfDay) formatTime;

  const EventPreviewWidget({
    super.key,
    required this.eventName,
    required this.selectedDate,
    required this.selectedTime,
    required this.location,
    required this.selectedEventType,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedEventType.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_outlined,
                color: selectedEventType.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Event Preview',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  selectedEventType.color.withOpacity(0.1),
                  selectedEventType.color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedEventType.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selectedEventType.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selectedEventType.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName.isEmpty ? 'Your Event Name' : eventName,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (selectedDate != null) ...[
                        Text(
                          '${formatDate(selectedDate!)}${selectedTime != null ? ' at ${formatTime(selectedTime!)}' : ''}',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Date & Time TBD',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      if (location != null && location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location!,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
