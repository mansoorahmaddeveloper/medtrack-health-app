import 'package:go_router/go_router.dart';

import '../constants/routes.dart';

/// Global navigation for notification taps and background handlers.
abstract final class AppNavigator {
  static GoRouter? _router;

  static void bind(GoRouter router) => _router = router;

  static void openDoseConfirm(String doseLogId) {
    _router?.push('${AppRoutes.doseConfirm}/$doseLogId');
  }

  static void openSos() {
    _router?.push(AppRoutes.sos);
  }
}
