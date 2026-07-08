import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';
import 'package:wish_listy/features/chat/presentation/widgets/message_bubble.dart';

class SwipeableMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onReply;
  final String? peerDisplayName;

  const SwipeableMessageBubble({
    super.key,
    required this.message,
    required this.onReply,
    this.peerDisplayName,
  });

  @override
  State<SwipeableMessageBubble> createState() => _SwipeableMessageBubbleState();
}

class _SwipeableMessageBubbleState extends State<SwipeableMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapController;
  late Animation<double> _snapAnim;

  double _dragOffset = 0.0;
  double _snapStartOffset = 0.0;
  bool _replyTriggered = false;
  bool _isDragging = false;

  static const double _triggerThreshold = 60.0;
  static const double _maxDragOffset = 76.0;

  @override
  void initState() {
    super.initState();
    _snapAnim = const AlwaysStoppedAnimation(0.0);
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onSnapTick);
  }

  @override
  void dispose() {
    _snapController.removeListener(_onSnapTick);
    _snapController.dispose();
    super.dispose();
  }

  void _onSnapTick() {
    if (_isDragging || !mounted) return;
    setState(() {
      _dragOffset = _snapAnim.value;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    // Only allow dragging to the right (positive direction)
    if (dx < 0 && _dragOffset <= 0) return;

    _isDragging = true;
    _snapController.stop();

    setState(() {
      _dragOffset = (_dragOffset + dx).clamp(0.0, _maxDragOffset);
    });

    if (_dragOffset >= _triggerThreshold && !_replyTriggered) {
      _replyTriggered = true;
      HapticFeedback.lightImpact();
      widget.onReply();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    _replyTriggered = false;
    _snapStartOffset = _dragOffset;
    _snapAnim = Tween<double>(
      begin: _snapStartOffset,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _snapController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset / _triggerThreshold).clamp(0.0, 1.0);
    final iconOpacity = progress;
    final iconScale = 0.5 + progress * 0.5;

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Reply icon that appears behind the sliding bubble
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: iconOpacity,
                child: Transform.scale(
                  scale: iconScale,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Message bubble slides to the right
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: MessageBubble(
              message: widget.message,
              peerDisplayName: widget.peerDisplayName,
            ),
          ),
        ],
      ),
    );
  }
}
