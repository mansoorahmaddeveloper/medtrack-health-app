import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/profile_repository.dart';
import '../../services/sos_alert_service.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  bool _activated = false;

  Future<void> _activate() async {
    if (_activated) return;
    setState(() => _activated = true);
    final result = await ref.read(sosAlertServiceProvider).triggerEmergencyAlert();
    if (!mounted) return;
    if (result.contactsNotified == 0) {
      AppToast.error(context, result.message);
    } else if (result.smsLaunched) {
      AppToast.success(context, result.message);
    } else {
      AppToast.error(context, result.message);
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final contactsStream = ref.watch(profileRepositoryProvider).watchEmergencyContacts();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('Emergency', style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                'Need Immediate Help?',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLgMobile.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 12),
              Text(
                'Slide to activate emergency response. This will alert your emergency contacts and local services.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd,
              ),
              const Spacer(),
              const _SosPulseButton(),
              const SizedBox(height: 32),
              _SlideToActivate(
                enabled: !_activated,
                onActivated: _activate,
              ),
              const Spacer(flex: 2),
              StreamBuilder(
                stream: contactsStream,
                builder: (context, snapshot) {
                  final contacts = snapshot.data ?? [];
                  return _NotifyCard(
                    contacts: contacts,
                    onEdit: () => context.push(AppRoutes.emergencyContacts),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosPulseButton extends StatelessWidget {
  const _SosPulseButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(220, AppColors.error.withValues(alpha: 0.08)),
          _ring(180, AppColors.error.withValues(alpha: 0.12)),
          _ring(140, AppColors.error.withValues(alpha: 0.18)),
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x40BA1A1A), blurRadius: 24, spreadRadius: 4),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white.withValues(alpha: 0.95), size: 32),
                const SizedBox(height: 4),
                Text(
                  'SOS',
                  style: AppTypography.labelLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _SlideToActivate extends StatefulWidget {
  const _SlideToActivate({required this.onActivated, required this.enabled});

  final VoidCallback onActivated;
  final bool enabled;

  @override
  State<_SlideToActivate> createState() => _SlideToActivateState();
}

class _SlideToActivateState extends State<_SlideToActivate> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    const trackHeight = 56.0;
    const thumbSize = 48.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final limit = trackWidth - thumbSize - 8;

        return GestureDetector(
          onHorizontalDragUpdate: widget.enabled
              ? (d) => setState(() => _drag = (_drag + d.delta.dx).clamp(0.0, limit))
              : null,
          onHorizontalDragEnd: widget.enabled
              ? (_) {
                  if (_drag >= limit * 0.85) {
                    setState(() => _drag = limit);
                    widget.onActivated();
                  } else {
                    setState(() => _drag = 0);
                  }
                }
              : null,
          child: Container(
            height: trackHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'SLIDE TO ACTIVATE',
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Positioned(
                  left: 4 + _drag,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.keyboard_double_arrow_right, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotifyCard extends StatelessWidget {
  const _NotifyCard({required this.contacts, required this.onEdit});

  final List<EmergencyContact> contacts;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('WILL NOTIFY', style: AppTypography.labelSm),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text('Edit'),
              ),
            ],
          ),
          if (contacts.isNotEmpty) ...[
            _NotifyRow(
              icon: Icons.person_outline,
              title: contacts.first.name,
              subtitle: contacts.first.relationship ?? 'Emergency contact',
            ),
            if (contacts.length > 1) ...[
              const Divider(height: 20),
              _NotifyRow(
                icon: Icons.person_outline,
                title: contacts[1].name,
                subtitle: contacts[1].relationship ?? 'Emergency contact',
              ),
            ],
          ] else
            _NotifyRow(
              icon: Icons.person_outline,
              title: 'No contacts set',
              subtitle: 'Tap Edit to add emergency contacts',
            ),
          const Divider(height: 20),
          const _NotifyRow(
            icon: Icons.local_hospital_outlined,
            title: 'Local Emergency',
            subtitle: '911',
          ),
        ],
      ),
    );
  }
}

class _NotifyRow extends StatelessWidget {
  const _NotifyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLg),
              Text(subtitle, style: AppTypography.labelSm),
            ],
          ),
        ),
      ],
    );
  }
}
