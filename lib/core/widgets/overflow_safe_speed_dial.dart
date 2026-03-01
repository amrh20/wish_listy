import 'package:flutter/material.dart';

/// A Speed Dial widget that guarantees no overflow - uses constrained layout
/// and explicit positioning to stay within screen bounds (RTL & LTR).
class OverflowSafeSpeedDial extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final Color backgroundColor;
  final Color foregroundColor;
  final List<OverflowSafeSpeedDialChild> children;
  final bool isRTL;

  const OverflowSafeSpeedDial({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.children,
    this.isRTL = false,
  });

  @override
  State<OverflowSafeSpeedDial> createState() => _OverflowSafeSpeedDialState();
}

class _OverflowSafeSpeedDialState extends State<OverflowSafeSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _controller.reverse().then((_) => _removeOverlay());
    } else {
      _showOverlay();
      _controller.forward();
    }
    setState(() => _open = !_open);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  void _showOverlay() {
    // Insert overlay in next frame so FAB has been laid out and position is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_open || _overlayEntry != null) return;
      _overlayEntry = OverlayEntry(
      builder: (context) => _SpeedDialOverlay(
        fabKey: _fabKey,
        isRTL: widget.isRTL,
        children: widget.children,
        controller: _controller,
        onClose: () {
          if (_open) _toggle();
        },
      ),
    );
      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _fabKey,
      child: GestureDetector(
        onLongPress: _toggle,
        child: AnimatedRotation(
          turns: _open ? 0.125 : 0, // 45 degrees: + becomes ×
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: 4,
            shape: const CircleBorder(),
            child: Icon(widget.icon),
          ),
        ),
      ),
    );
  }
}

class OverflowSafeSpeedDialChild {
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  OverflowSafeSpeedDialChild({
    required this.child,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });
}

class _SpeedDialOverlay extends StatelessWidget {
  final GlobalKey fabKey;
  final bool isRTL;
  final List<OverflowSafeSpeedDialChild> children;
  final AnimationController controller;
  final VoidCallback onClose;

  const _SpeedDialOverlay({
    required this.fabKey,
    required this.isRTL,
    required this.children,
    required this.controller,
    required this.onClose,
  });

  /// Staggered animation per child: 50ms delay each, easeOutBack
  Animation<double> _staggeredAnimation(int index) {
    const staggerMs = 50;
    const totalMs = 250;
    final start = (index * staggerMs) / totalMs;
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    const edgeInset = 48.0;
    const childSpacing = 16.0;
    const gapAboveFab = 8.0;

    // Position overlay just above the FAB using its actual position
    double bottomOffset = 130.0; // fallback
    final renderBox = fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final fabTop = renderBox.localToGlobal(Offset.zero).dy;
      bottomOffset = screenHeight - fabTop + gapAboveFab;
    }

    // Max width for children - ensure we never overflow
    final maxChildWidth = screenWidth - edgeInset;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        Positioned(
          left: isRTL ? 16 : null,
          right: isRTL ? null : 16,
          bottom: bottomOffset + safeBottom,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxChildWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              // Order: bottom to top = Create Wishlist, Create Event, Add Friend
              children: List.generate(children.length * 2 - 1, (i) {
                if (i.isOdd) {
                  return SizedBox(height: childSpacing);
                }
                final index = i ~/ 2;
                final child = children[index];
                final anim = _staggeredAnimation(index);
                return ScaleTransition(
                  scale: anim,
                  child: FadeTransition(
                    opacity: anim,
                    child: _ChildButton(
                      onTap: () {
                        child.onTap();
                        onClose();
                      },
                      backgroundColor: child.backgroundColor,
                      foregroundColor: child.foregroundColor,
                      child: child.child,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChildButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget child;

  const _ChildButton({
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50, maxWidth: 200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: child,
          ),
        ),
      ),
    );
  }
}
