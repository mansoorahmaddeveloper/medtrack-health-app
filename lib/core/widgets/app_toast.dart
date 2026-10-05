import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Top-right toast using the root overlay so it survives route pops.
class AppToast {
  static OverlayEntry? _current;

  static OverlayState? _overlayFor(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).overlay ??
        Overlay.maybeOf(context, rootOverlay: true);
  }

  static void success(BuildContext context, String message) {
    _show(context, message, isError: false);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, isError: true);
  }

  /// Show toast then pop the current route after a short delay.
  static void successThenPop(BuildContext context, String message) {
    success(context, message);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (context.mounted) Navigator.of(context).pop();
    });
  }

  static void _show(BuildContext context, String message, {required bool isError}) {
    final overlay = _overlayFor(context);
    if (overlay == null) return;

    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastBanner(
        message: message,
        isError: isError,
        onDismiss: () {
          try {
            entry.remove();
          } catch (_) {}
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      try {
        entry.remove();
      } catch (_) {}
      if (_current == entry) _current = null;
    });
  }
}

class _ToastBanner extends StatefulWidget {
  const _ToastBanner({
    required this.message,
    required this.onDismiss,
    this.isError = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final bool isError;

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    final color = widget.isError ? AppColors.error : AppColors.primary;

    return Positioned(
      top: top,
      right: 16,
      left: 56,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: color.withValues(alpha: 0.25)),
              boxShadow: AppElevation.floating,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Icon(Icons.close, size: 18, color: AppColors.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
