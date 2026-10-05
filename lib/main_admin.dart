import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'data/remote/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(supabaseServiceProvider).initialize();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MedTrackAdminApp(),
    ),
  );
}
