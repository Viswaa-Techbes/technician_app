import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/core/utils/formatters.dart';
import 'package:customer_app/features/booking/models/booking_models.dart';
import 'package:customer_app/features/booking/providers/booking_provider.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const BookingFlowScreen({super.key, required this.serviceId});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  final _addressController = TextEditingController(text: '12th Cross Road, Indiranagar');
  final _cityController = TextEditingController(text: 'Bengaluru');
  final _stateController = TextEditingController(text: 'Karnataka');
  final _pincodeController = TextEditingController(text: '560038');
  final _notesController = TextEditingController();

  LatLng _selectedCoords = const LatLng(12.9716, 77.5946); // Indiranagar default
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingWizardProvider);
    final notifier = ref.read(bookingWizardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.slate950,
      appBar: AppBar(
        title: const Text('Configure Booking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (state.step > 0) {
              notifier.prevStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Stepper Progress Indicator
            _buildStepperHeader(state.step),
            const SizedBox(height: 10),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildStepContent(state, notifier),
              ),
            ),

            // Navigation Sticky Bottom Bar
            _buildBottomBar(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(int currentStep) {
    final stepTitles = ['Cameras', 'Materials', 'Location', 'Schedule', 'Summary'];
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.slate900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final isActive = index <= currentStep;
          final isCurrent = index == currentStep;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCurrent
                      ? AppColors.emerald500
                      : (isActive ? AppColors.emerald800.withOpacity(0.4) : AppColors.slate800),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.slate400,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (index < 4)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: index < currentStep
                          ? AppColors.emerald500
                          : AppColors.slate800,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BookingWizardState state, BookingWizardNotifier notifier) {
    switch (state.step) {
      case 0:
        return _buildCameraSetupStep(state, notifier);
      case 1:
        return _buildMaterialsStep(state, notifier);
      case 2:
        return _buildLocationStep(state, notifier);
      case 3:
        return _buildScheduleStep(state, notifier);
      case 4:
        return _buildSummaryStep(state, notifier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCameraSetupStep(BookingWizardState state, BookingWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select Camera Model',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (state.cameraTypes.isEmpty)
          const Center(child: CircularProgressIndicator(color: AppColors.emerald500))
        else
          ...state.cameraTypes.map((type) {
            final isSelected = state.selectedCameraType?.id == type.id;
            return Card(
              color: isSelected ? AppColors.emerald800.withOpacity(0.15) : AppColors.slate900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? AppColors.emerald500 : Colors.white.withOpacity(0.04),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                onTap: () => notifier.updateCamera(type, state.cameraCount),
                title: Text(
                  type.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  type.description,
                  style: TextStyle(color: AppColors.slate400, fontSize: 12),
                ),
                trailing: Text(
                  '${Formatters.currency(type.installationPrice)}/unit',
                  style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        const SizedBox(height: 32),

        const Text(
          'Camera Count',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 28),
              onPressed: state.cameraCount > 1
                  ? () => notifier.updateCamera(state.selectedCameraType!, state.cameraCount - 1)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                '${state.cameraCount}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
              onPressed: () => notifier.updateCamera(state.selectedCameraType!, state.cameraCount + 1),
            ),
          ],
        ),
        const SizedBox(height: 32),

        const Text(
          'Installation Area',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Indoor (No extra charge)'),
                selected: state.installationArea == 'indoor',
                onSelected: (selected) {
                  if (selected) notifier.updateArea('indoor');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('Outdoor (+₹350 charge)'),
                selected: state.installationArea == 'outdoor',
                onSelected: (selected) {
                  if (selected) notifier.updateArea('outdoor');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialsStep(BookingWizardState state, BookingWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Wire Cabling Length',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.slate900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Length (meters)', style: TextStyle(color: AppColors.slate300)),
                    Text(
                      '${state.wireLength.toInt()} m',
                      style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                Slider(
                  value: state.wireLength,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: AppColors.emerald500,
                  inactiveColor: AppColors.slate800,
                  onChanged: (val) => notifier.updateWireLength(val),
                ),
                Text(
                  'Cabling cost: ${Formatters.currency(state.wireLength * 35.0)} (₹35 per meter)',
                  style: TextStyle(color: AppColors.slate400, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        const Text(
          'Additional Hardware & Addons',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (state.addons.isEmpty)
          const Center(child: CircularProgressIndicator(color: AppColors.emerald500))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.addons.length,
            itemBuilder: (context, index) {
              final addon = state.addons[index];
              final isChecked = state.selectedAddonIds.contains(addon.id);
              return CheckboxListTile(
                value: isChecked,
                onChanged: (_) => notifier.toggleAddon(addon.id),
                title: Text(addon.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  addon.description ?? 'Useful setup hardware extension',
                  style: TextStyle(color: AppColors.slate400, fontSize: 12),
                ),
                secondary: Icon(Icons.widgets_outlined, color: isChecked ? Colors.tealAccent : AppColors.slate400),
                activeColor: AppColors.emerald500,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
              );
            },
          ),
      ],
    );
  }

  Widget _buildLocationStep(BookingWizardState state, BookingWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Service Location',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Live OSM Map Container
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedCoords,
                initialZoom: 14.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedCoords = point;
                  });
                  notifier.updateLocation(
                    addressLine1: _addressController.text,
                    city: _cityController.text,
                    stateVal: _stateController.text,
                    pincode: _pincodeController.text,
                    lat: point.latitude,
                    lng: point.longitude,
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.techbes.customer_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedCoords,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Tap on map to place PIN at exact location',
            style: TextStyle(color: AppColors.slate400, fontSize: 11),
          ),
        ),
        const SizedBox(height: 24),

        // Address Form fields
        TextField(
          controller: _addressController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Address Line 1 / Building'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _stateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pincodeController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Pincode'),
        ),
      ],
    );
  }

  Widget _buildScheduleStep(BookingWizardState state, BookingWizardNotifier notifier) {
    final dates = List.generate(7, (index) {
      final date = DateTime.now().add(Duration(days: index + 1));
      return date;
    });

    final slots = ['09:00 AM', '11:30 AM', '02:00 PM', '04:30 PM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select Preferred Date',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: dates.map((date) {
              final formatted = '${date.day}/${date.month}/${date.year}';
              final isSelected = state.scheduledDate == formatted;
              final weekdayName = _getWeekdayName(date.weekday);
              final dayNum = '${date.day}';

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ChoiceChip(
                  label: Column(
                    children: [
                      Text(weekdayName, style: TextStyle(color: isSelected ? Colors.white : AppColors.slate400, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(dayNum, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) notifier.updateSchedule(formatted, state.timeSlot ?? slots[0]);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),

        const Text(
          'Select Time Slot',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            final isSelected = state.timeSlot == slot;
            return ChoiceChip(
              label: Text(slot, style: const TextStyle(fontWeight: FontWeight.bold)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.updateSchedule(state.scheduledDate ?? '${dates[0].day}/${dates[0].month}/${dates[0].year}', slot);
                }
              },
            );
          },
        ),
        const SizedBox(height: 32),

        const Text(
          'Special Instructions (Optional)',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          onChanged: (val) => notifier.updateNotes(val),
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Add instructions like parking details, safety rules, etc.',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStep(BookingWizardState state, BookingWizardNotifier notifier) {
    final invoice = state.priceResult?.breakdown ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Booking Summary',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Config detail card
        Card(
          color: AppColors.slate900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow('Camera Type', state.selectedCameraType?.name ?? 'Standard'),
                _buildSummaryRow('Camera Count', '${state.cameraCount} units'),
                _buildSummaryRow('Cabling Length', '${state.wireLength.toInt()} meters'),
                _buildSummaryRow('Installation Area', state.installationArea.toUpperCase()),
                _buildSummaryRow('Date', state.scheduledDate ?? 'TBD'),
                _buildSummaryRow('Time Slot', state.timeSlot ?? 'TBD'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Price Invoice card
        const Text(
          'Price Breakdown',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.slate900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInvoiceRow('Inspection/Base Charge', invoice['baseCharge'] ?? 499.0),
                _buildInvoiceRow('Installation Charge', invoice['cameraTotal'] ?? 0.0),
                if ((invoice['areaCharge'] ?? 0.0) > 0)
                  _buildInvoiceRow('Area Adjustment Charge', invoice['areaCharge']!),
                _buildInvoiceRow('Cabling Cost', invoice['wireTotal'] ?? 0.0),
                if ((invoice['addonsTotal'] ?? 0.0) > 0)
                  _buildInvoiceRow('Addons Hardware Total', invoice['addonsTotal']!),
                const Divider(height: 24, color: Colors.white10),
                _buildInvoiceRow('Taxable Amount', invoice['taxableAmount'] ?? 0.0),
                _buildInvoiceRow('GST (18%)', invoice['taxTotal'] ?? 0.0),
                const Divider(height: 24, color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      Formatters.currency(state.priceResult?.grandTotal ?? 0.0),
                      style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.slate400, fontSize: 13)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.slate300, fontSize: 13)),
          Text(Formatters.currency(amount), style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BookingWizardState state, BookingWizardNotifier notifier) {
    final isLastStep = state.step == 4;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state.step > 0)
            OutlinedButton(
              onPressed: () => notifier.prevStep(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back'),
            )
          else
            const SizedBox(),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      if (state.step == 2) {
                        // Capture location details before moving on
                        notifier.updateLocation(
                          addressLine1: _addressController.text,
                          city: _cityController.text,
                          stateVal: _stateController.text,
                          pincode: _pincodeController.text,
                          lat: _selectedCoords.latitude,
                          lng: _selectedCoords.longitude,
                        );
                      }
                      
                      if (isLastStep) {
                        final success = await notifier.submitBooking(widget.serviceId);
                        if (success && mounted) {
                          context.go('/booking-success', extra: {'bookingId': state.createdBookingId});
                        }
                      } else {
                        notifier.nextStep();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isLastStep ? 'Confirm & Book' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(int index) {
    switch (index) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}
