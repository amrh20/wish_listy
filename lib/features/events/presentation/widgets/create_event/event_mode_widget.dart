import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

/// Widget for event mode selection (in-person, online, hybrid)
class EventModeWidget extends StatelessWidget {
  final EventMode selectedMode;
  final ValueChanged<EventMode> onModeChanged;

  const EventModeWidget({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.eventMode'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('events.howWillPeopleAttend'),
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildModeOption(
                EventMode.inPerson,
                localization.translate('events.inPerson'),
                localization.translate('events.inPersonDescription'),
                Icons.location_on_outlined,
                AppColors.success,
                localization,
              ),
              _buildModeOption(
                EventMode.online,
                localization.translate('events.online'),
                localization.translate('events.onlineDescription'),
                Icons.video_call_outlined,
                AppColors.info,
                localization,
              ),
              _buildModeOption(
                EventMode.hybrid,
                localization.translate('events.hybrid'),
                localization.translate('events.hybridDescription'),
                Icons.connect_without_contact_outlined,
                AppColors.warning,
                localization,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    EventMode value,
    String title,
    String description,
    IconData icon,
    Color color,
    LocalizationService localization,
  ) {
    final isSelected = selectedMode == value;
    return GestureDetector(
      onTap: () => onModeChanged(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.textTertiary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
