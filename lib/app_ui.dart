import 'package:flutter/material.dart';

import 'app_keys.dart';

Route<T> buildPageRoute<T>(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(fade);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFF111827),
  IconData icon = Icons.notifications_rounded,
}) {
  final messenger = rootScaffoldMessengerKey.currentState ??
      ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

void showFakeNotification(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFF111827),
  IconData icon = Icons.notifications_rounded,
}) {
  showAppSnackBar(
    context,
    message,
    backgroundColor: backgroundColor,
    icon: icon,
  );
}

void showGlobalFakeNotification(
  String message, {
  Color backgroundColor = const Color(0xFF111827),
  IconData icon = Icons.notifications_rounded,
}) {
  final context =
      rootScaffoldMessengerKey.currentContext ?? rootNavigatorKey.currentContext;
  if (context == null) return;
  showFakeNotification(
    context,
    message,
    backgroundColor: backgroundColor,
    icon: icon,
  );
}

class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.scale = 0.97,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double scale;
  final bool enabled;
  final Duration duration;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || !widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.enabled ? widget.onTap : null,
          onHighlightChanged: _setPressed,
          child: widget.child,
        ),
      ),
    );
  }
}

class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.margin,
    this.color = const Color(0xFFE5E7EB),
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsets? margin;
  final Color color;

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.45 + (_controller.value * 0.35);
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
