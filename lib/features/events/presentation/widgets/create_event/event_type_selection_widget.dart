import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Model for event type options
class EventTypeOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String emoji;

  EventTypeOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}

/// Widget for selecting event type
class EventTypeSelectionWidget extends StatelessWidget {
  final List<EventTypeOption> eventTypes;
  final String selectedEventType;
  final Color selectedColor;
  final ValueChanged<String> onEventTypeChanged;

  const EventTypeSelectionWidget({
    super.key,
    required this.eventTypes,
    required this.selectedEventType,
    required this.selectedColor,
    required this.onEventTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selectedColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, color: selectedColor, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.whatAreYouCelebrating'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Event Type Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  (constraints.maxWidth - 18) / 4; // 18 = 6*3 (spacing)
              final itemHeight = itemWidth * 1.1; // Slightly taller than wide
              final gridHeight = (itemHeight * 2) + 6; // 2 rows + spacing

              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  shrinkWrap: false,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: itemWidth / itemHeight,
                  ),
                  itemCount: eventTypes.length,
                  itemBuilder: (context, index) {
                    final eventType = eventTypes[index];
                    final isSelected = selectedEventType == eventType.id;

                    return GestureDetector(
                      onTap: () => onEventTypeChanged(eventType.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? eventType.color.withOpacity(0.1)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? eventType.color
                                : AppColors.textTertiary.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              eventType.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 1),
                            Icon(
                              eventType.icon,
                              color: isSelected
                                  ? eventType.color
                                  : AppColors.textTertiary,
                              size: 14,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              eventType.name,
                              style: AppStyles.caption.copyWith(
                                color: isSelected
                                    ? eventType.color
                                    : AppColors.textTertiary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
