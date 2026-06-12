import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/booking/models/booking_models.dart';
import 'package:customer_app/features/booking/repositories/booking_repository.dart';

class BookingWizardState {
  final int step;
  final List<CctvCameraType> cameraTypes;
  final List<CctvAddon> addons;
  final CctvCameraType? selectedCameraType;
  final int cameraCount;
  final String installationArea; // 'indoor' | 'outdoor'
  final double wireLength;
  final List<String> selectedAddonIds;
  
  // Schedule & Location
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? scheduledDate;
  final String? timeSlot;
  final String notes;

  // Calculation Results
  final bool isCalculating;
  final CctvPriceResult? priceResult;
  final String? errorMessage;
  final bool isSubmitting;
  final String? createdBookingId;

  const BookingWizardState({
    this.step = 0,
    this.cameraTypes = const [],
    this.addons = const [],
    this.selectedCameraType,
    this.cameraCount = 1,
    this.installationArea = 'indoor',
    this.wireLength = 10,
    this.selectedAddonIds = const [],
    this.addressLine1,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.scheduledDate,
    this.timeSlot,
    this.notes = '',
    this.isCalculating = false,
    this.priceResult,
    this.errorMessage,
    this.isSubmitting = false,
    this.createdBookingId,
  });

  BookingWizardState copyWith({
    int? step,
    List<CctvCameraType>? cameraTypes,
    List<CctvAddon>? addons,
    CctvCameraType? selectedCameraType,
    int? cameraCount,
    String? installationArea,
    double? wireLength,
    List<String>? selectedAddonIds,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? scheduledDate,
    String? timeSlot,
    String? notes,
    bool? isCalculating,
    CctvPriceResult? priceResult,
    String? errorMessage,
    bool? isSubmitting,
    String? createdBookingId,
  }) {
    return BookingWizardState(
      step: step ?? this.step,
      cameraTypes: cameraTypes ?? this.cameraTypes,
      addons: addons ?? this.addons,
      selectedCameraType: selectedCameraType ?? this.selectedCameraType,
      cameraCount: cameraCount ?? this.cameraCount,
      installationArea: installationArea ?? this.installationArea,
      wireLength: wireLength ?? this.wireLength,
      selectedAddonIds: selectedAddonIds ?? this.selectedAddonIds,
      addressLine1: addressLine1 ?? this.addressLine1,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      notes: notes ?? this.notes,
      isCalculating: isCalculating ?? this.isCalculating,
      priceResult: priceResult ?? this.priceResult,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdBookingId: createdBookingId ?? this.createdBookingId,
    );
  }
}

class BookingWizardNotifier extends StateNotifier<BookingWizardState> {
  final BookingRepository _repo;

  BookingWizardNotifier(this._repo) : super(const BookingWizardState()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final cameraTypes = await _repo.getCameraTypes();
      final addons = await _repo.getAddons();
      state = state.copyWith(
        cameraTypes: cameraTypes,
        addons: addons,
        selectedCameraType: cameraTypes.isNotEmpty ? cameraTypes.first : null,
      );
      recalculatePrice();
    } catch (_) {
      // Use fallback defaults
      final fallbacks = [
        const CctvCameraType(id: 'fallback-dome-camera', name: 'Dome Camera', slug: 'dome-camera', description: 'Indoor ceiling camera', installationPrice: 650),
        const CctvCameraType(id: 'fallback-bullet-camera', name: 'Bullet Camera', slug: 'bullet-camera', description: 'Outdoor directional camera', installationPrice: 750),
        const CctvCameraType(id: 'fallback-ptz-camera', name: 'PTZ Camera', slug: 'ptz-camera', description: 'Pan tilt zoom camera', installationPrice: 1800),
      ];
      final addons = [
        const CctvAddon(id: 'fallback-pvc-casing', name: 'PVC Casing', slug: 'pvc-casing', price: 180),
        const CctvAddon(id: 'fallback-junction-box', name: 'Junction Box', slug: 'junction-box', price: 220),
        const CctvAddon(id: 'fallback-smps', name: 'SMPS', slug: 'smps', price: 650),
        const CctvAddon(id: 'fallback-hard-disk', name: 'Hard Disk', slug: 'hard-disk', price: 3800),
      ];
      state = state.copyWith(
        cameraTypes: fallbacks,
        addons: addons,
        selectedCameraType: fallbacks.first,
      );
      recalculatePrice();
    }
  }

  void nextStep() {
    if (state.step < 4) {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void prevStep() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  void updateCamera(CctvCameraType camera, int count) {
    state = state.copyWith(selectedCameraType: camera, cameraCount: count);
    recalculatePrice();
  }

  void updateArea(String area) {
    state = state.copyWith(installationArea: area);
    recalculatePrice();
  }

  void updateWireLength(double length) {
    state = state.copyWith(wireLength: length);
    recalculatePrice();
  }

  void toggleAddon(String id) {
    final addons = List<String>.from(state.selectedAddonIds);
    if (addons.contains(id)) {
      addons.remove(id);
    } else {
      addons.add(id);
    }
    state = state.copyWith(selectedAddonIds: addons);
    recalculatePrice();
  }

  void updateLocation({
    required String addressLine1,
    required String city,
    required String stateVal,
    required String pincode,
    required double lat,
    required double lng,
  }) {
    state = state.copyWith(
      addressLine1: addressLine1,
      city: city,
      state: stateVal,
      pincode: pincode,
      latitude: lat,
      longitude: lng,
    );
  }

  void updateSchedule(String date, String slot) {
    state = state.copyWith(scheduledDate: date, timeSlot: slot);
  }

  void updateNotes(String val) {
    state = state.copyWith(notes: val);
  }

  Future<void> recalculatePrice() async {
    if (state.selectedCameraType == null) return;
    state = state.copyWith(isCalculating: true);

    try {
      final res = await _repo.calculatePrice(
        cameraTypeId: state.selectedCameraType!.id,
        cameraCount: state.cameraCount,
        installationArea: state.installationArea,
        wireLength: state.wireLength,
        addonIds: state.selectedAddonIds,
      );
      state = state.copyWith(priceResult: res, isCalculating: false);
    } catch (_) {
      // Local fallback calculation
      final cam = state.selectedCameraType!;
      final count = state.cameraCount;
      final areaCharge = state.installationArea == 'outdoor' ? 350.0 : 0.0;
      final wireTotal = state.wireLength * 35.0;
      
      double addonsTotal = 0.0;
      for (final id in state.selectedAddonIds) {
        final addon = state.addons.firstWhere((a) => a.id == id);
        addonsTotal += addon.price;
      }

      final baseCharge = 499.0;
      final cameraTotal = count * cam.installationPrice;
      final taxableAmount = baseCharge + cameraTotal + areaCharge + wireTotal + addonsTotal;
      final taxTotal = (taxableAmount * 0.18).roundToDouble();

      final res = CctvPriceResult(
        grandTotal: taxableAmount + taxTotal,
        taxTotal: taxTotal,
        taxableAmount: taxableAmount,
        breakdown: {
          'baseCharge': baseCharge,
          'cameraTotal': cameraTotal,
          'areaCharge': areaCharge,
          'wireTotal': wireTotal,
          'addonsTotal': addonsTotal,
          'taxableAmount': taxableAmount,
          'taxTotal': taxTotal,
          'grandTotal': taxableAmount + taxTotal,
        },
      );

      state = state.copyWith(priceResult: res, isCalculating: false);
    }
  }

  Future<bool> submitBooking(String serviceId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final payload = {
      'serviceId': serviceId,
      'bookingDetails': {
        'cameraTypeId': state.selectedCameraType?.id,
        'cameraCount': state.cameraCount,
        'installationArea': state.installationArea,
        'wireLength': state.wireLength,
        'addonIds': state.selectedAddonIds,
      },
      'scheduledDate': state.scheduledDate,
      'scheduledTime': state.timeSlot,
      'notes': state.notes,
      'address': {
        'addressLine1': state.addressLine1,
        'city': state.city,
        'state': state.state,
        'pincode': state.pincode,
        'latitude': state.latitude,
        'longitude': state.longitude,
      }
    };

    try {
      final res = await _repo.createBooking(payload);
      final bookingId = res['_id'] as String? ?? res['id'] as String? ?? '';
      state = state.copyWith(isSubmitting: false, createdBookingId: bookingId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to create booking: ${e.toString()}',
      );
      return false;
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

final bookingWizardProvider =
    StateNotifierProvider.autoDispose<BookingWizardNotifier, BookingWizardState>((ref) {
  return BookingWizardNotifier(ref.read(bookingRepositoryProvider));
});
