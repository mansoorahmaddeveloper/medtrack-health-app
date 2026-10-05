import 'package:flutter_test/flutter_test.dart';
import 'package:medtrack/core/constants/app_constants.dart';

void main() {
  test('app constants are defined', () {
    expect(AppConstants.appName, 'MedTrack');
    expect(AppConstants.doseFollowUpDelay.inMinutes, 5);
  });
}
