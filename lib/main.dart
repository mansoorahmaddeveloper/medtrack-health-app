import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'data/remote/supabase_client.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(supabaseServiceProvider).initialize();
  await container.read(notificationServiceProvider).initialize();
  await container.read(pushNotificationServiceProvider).initialize();
  await container.read(reminderSchedulerProvider).processFollowUps();
  await container.read(reminderSchedulerProvider).rescheduleAllActiveMedicines();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MedTrackApp(),
    ),
  );
}
