import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/providers/app_providers.dart';
import '../../data/remote/supabase_client.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _usePhone = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!supabase.isConfigured)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY dart-defines to enable cloud sync.',
                ),
              ),
            ),
          SwitchListTile(
            title: const Text('Use phone OTP'),
            value: _usePhone,
            onChanged: supabase.isConfigured ? (v) => setState(() => _usePhone = v) : null,
          ),
          if (_usePhone)
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone (+92...)'),
            )
          else
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: !supabase.isConfigured
                ? null
                : () async {
                    await supabase.signInWithOtp(
                      email: _usePhone ? null : _email.text.trim(),
                      phone: _usePhone ? _phone.text.trim() : null,
                    );
                    if (context.mounted) {
                      context.push(
                        AppRoutes.otp,
                        extra: {
                          'email': _usePhone ? null : _email.text.trim(),
                          'phone': _usePhone ? _phone.text.trim() : null,
                        },
                      );
                    }
                  },
            child: const Text('Send OTP'),
          ),
        ],
      ),
    );
  }
}

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, this.email, this.phone});

  final String? email;
  final String? phone;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _token = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _token,
              decoration: const InputDecoration(labelText: 'OTP code'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final supabase = ref.read(supabaseServiceProvider);
                final response = await supabase.verifyOtp(
                  token: _token.text.trim(),
                  email: widget.email,
                  phone: widget.phone,
                );
                final userId = response.user?.id;
                if (userId != null) {
                  await ref.read(syncServiceProvider).migrateGuestDataToUser(userId);
                  await ref.read(syncServiceProvider).syncIfOnline();
                }
                if (context.mounted) context.go(AppRoutes.profile);
              },
              child: const Text('Verify & sync'),
            ),
          ],
        ),
      ),
    );
  }
}
