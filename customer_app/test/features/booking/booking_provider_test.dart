import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:customer_app/features/booking/models/booking_models.dart';
import 'package:customer_app/features/booking/repositories/booking_repository.dart';
import 'package:customer_app/features/booking/providers/booking_provider.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  group('BookingWizardNotifier State Machine Tests', () {
    late BookingRepository mockRepo;
    late BookingWizardNotifier notifier;

    setUp(() {
      mockRepo = MockBookingRepository();
      
      // Stub the camera type and addon API requests for setup
      when(() => mockRepo.getCameraTypes()).thenAnswer((_) async => [
        const CctvCameraType(id: 'c1', name: 'Dome', slug: 'dome', description: 'desc', installationPrice: 650),
      ]);
      when(() => mockRepo.getAddons()).thenAnswer((_) async => [
        const CctvAddon(id: 'a1', name: 'Rack', slug: 'rack', price: 1000),
      ]);

      notifier = BookingWizardNotifier(mockRepo);
    });

    test('Initial step is 0', () {
      expect(notifier.state.step, 0);
    });

    test('nextStep increments step up to 4', () {
      notifier.nextStep();
      expect(notifier.state.step, 1);
      
      notifier.nextStep();
      notifier.nextStep();
      notifier.nextStep();
      expect(notifier.state.step, 4);

      // Should not go beyond 4
      notifier.nextStep();
      expect(notifier.state.step, 4);
    });

    test('prevStep decrements step down to 0', () {
      notifier.nextStep();
      notifier.prevStep();
      expect(notifier.state.step, 0);

      // Should not go below 0
      notifier.prevStep();
      expect(notifier.state.step, 0);
    });

    test('updateArea changes installationArea', () {
      notifier.updateArea('outdoor');
      expect(notifier.state.installationArea, 'outdoor');
    });
  });
}
