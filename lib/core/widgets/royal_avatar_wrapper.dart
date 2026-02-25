import 'package:flutter/material.dart';
import 'package:wish_listy/core/utils/royal_name_helper.dart';

/// A wrapper widget that adds a golden crown icon above the avatar
/// if the user's name matches any "Royal Names" (Easter Egg: Marwa, Nelly, etc.)
class RoyalAvatarWrapper extends StatelessWidget {
  /// The original avatar widget (e.g., CircleAvatar)
  final Widget child;

  /// The user's full name to check against royal names
  final String userName;

  /// Size of the crown icon (default: 20)
  final double crownSize;

  /// Top offset for positioning the crown (default: -15)
  final double topOffset;

  const RoyalAvatarWrapper({
    super.key,
    required this.child,
    required this.userName,
    this.crownSize = 20,
    this.topOffset = -15,
  });

  @override
  Widget build(BuildContext context) {
    final isRoyal = RoyalNameHelper.isRoyalName(userName);

    if (!isRoyal) {
      // If not royal, just return the child widget as-is
      return child;
    }

    // If royal, wrap in Stack with crown icon
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Original avatar (base layer)
        child,
        // Golden crown icon (positioned above and centered)
        Positioned(
          top: topOffset,
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset(
              'assets/images/queen.png',
              width: crownSize,
              height: crownSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image not found
                return Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: crownSize,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

