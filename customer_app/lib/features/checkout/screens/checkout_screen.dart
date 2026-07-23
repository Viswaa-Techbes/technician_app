import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';
import '../../cart/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../components/map_location_picker.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late Razorpay _razorpay;
  List<dynamic> _savedAddresses = [];
  bool _isLoadingAddresses = true;
  String _selectedAddressId = '';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _showMap = true;
  String _mapLink = '';
  double? _latitude;
  double? _longitude;
  String _pincode = '';
  String _city = '';
  String _state = '';

  bool _isSubmitting = false;
  String? _checkoutError;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    
    _loadProfileData();
    _loadSavedAddresses();
    _prefillFromCart();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _prefillFromCart() {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isNotEmpty) {
      final first = cartItems[0];
      if (first.config != null) {
        final config = first.config!;
        setState(() {
          _notesController.text = config['notes'] ?? '';
          _dateController.text = config['date'] ?? '';
          _timeController.text = config['time'] ?? '';
          _mapLink = config['mapLink'] ?? '';
          _latitude = config['latitude'];
          _longitude = config['longitude'];
          _pincode = config['pincode'] ?? '';
          _addressController.text = config['fullAddress'] ?? '';
          _city = config['city'] ?? '';
          _state = config['state'] ?? '';
          if (_latitude != null && _longitude != null) {
            _showMap = false;
          }
        });
      }
    }
  }

  void _loadProfileData() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      setState(() {
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['mobileNumber'] ?? user['phone'] ?? '';
      });
    }
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/addresses');
      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _savedAddresses = response.data['data'] ?? [];
          _isLoadingAddresses = false;
          final def = _savedAddresses.firstWhere((a) => a['isDefault'] == true, orElse: () => null);
          if (def != null) {
            _selectAddress(def);
          }
        });
      } else {
        setState(() => _isLoadingAddresses = false);
      }
    } catch (e) {
      debugPrint('Addresses error: $e');
      setState(() => _isLoadingAddresses = false);
    }
  }

  void _selectAddress(dynamic addr) {
    setState(() {
      _selectedAddressId = addr['_id'];
      if (_selectedAddressId == 'new') {
        _addressController.clear();
        _pincode = '';
        _city = '';
        _state = '';
        _latitude = null;
        _longitude = null;
        _mapLink = '';
        _showMap = true;
        return;
      }

      _nameController.text = addr['name'] ?? _nameController.text;
      _phoneController.text = addr['mobile'] ?? _phoneController.text;
      _addressController.text = addr['address'] ?? [addr['addressLine1'], addr['addressLine2']].where((s) => s != null).join(', ');
      _pincode = addr['pincode'] ?? '';
      _city = addr['city'] ?? '';
      _state = addr['state'] ?? '';
      _latitude = addr['latitude'];
      _longitude = addr['longitude'];
      _mapLink = addr['googleMapLink'] ?? '';
      
      if (_latitude != null && _longitude != null) {
        _showMap = false;
      }
    });
  }

  void _openMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: MapLocationPicker(
                initialCoords: _latitude != null && _longitude != null ? MapLatLng(_latitude!, _longitude!) : null,
                onLocationSelected: (data) {
                  setState(() {
                    _mapLink = 'https://maps.google.com/?q=${data.latitude},${data.longitude}';
                    _latitude = data.latitude;
                    _longitude = data.longitude;
                    _pincode = data.pincode;
                    _addressController.text = data.address;
                    _city = data.city;
                    _state = data.state;
                    _showMap = false;
                  });
                  context.pop();
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitBooking() async {
    setState(() {
      _checkoutError = null;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      setState(() => _checkoutError = 'Please pin and confirm your service location on the map.');
      return;
    }

    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    final first = cartItems[0];
    final total = ref.read(cartProvider.notifier).totalAmount;

    final Map<String, dynamic> cctvDetails = (() {
      final List<dynamic> materialsList = first.config?['materials'] ?? [];
      final materialLengths = materialsList.where((m) => m['unit'] == 'meter').map((m) => {'id': m['id'], 'length': m['qty']}).toList();
      final materialQuantities = materialsList.where((m) => m['unit'] != 'meter').map((m) => {'id': m['id'], 'qty': m['qty']}).toList();
      
      return {
        'serviceCategory': first.config?['categoryId'] ?? 'cctv',
        'serviceType': first.config?['serviceType'] ?? 'installation',
        'selectedMaterials': materialsList,
        'materialLengths': materialLengths,
        'materialQuantities': materialQuantities,
        'mapLink': _mapLink,
        'date': _dateController.text,
        'time': _timeController.text,
        'notes': _notesController.text.trim(),
        'priceBreakdown': first.config?['priceBreakdown'] ?? {},
      };
    })();

    final bookingPayload = {
      'service': first.title,
      'serviceId': first.config?['subcategoryId'] ?? first.serviceId.toString(),
      'serviceName': first.title,
      'address': _addressController.text.trim(),
      'description': _notesController.text.trim(),
      'date': _dateController.text,
      'timeSlot': _timeController.text,
      'customerName': _nameController.text.trim(),
      'customerPhone': _phoneController.text.trim(),
      'totalAmount': total,
      'serviceType': first.config?['serviceType'] ?? 'installation',
      'addressId': _selectedAddressId.isNotEmpty && _selectedAddressId != 'new' ? _selectedAddressId : null,
      'lat': _latitude.toString(),
      'lng': _longitude.toString(),
      'latitude': _latitude,
      'longitude': _longitude,
      'city': _city,
      'state': _state,
      'pincode': _pincode,
      'cctvDetails': cctvDetails,
    };

    setState(() => _isSubmitting = true);

    try {
      final client = ref.read(dioClientProvider);
      final orderResponse = await client.post(ApiConfig.createOrder, data: {'bookingPayload': bookingPayload});
      
      if (orderResponse.data != null) {
        final order = orderResponse.data;
        final options = {
          'key': order['keyId'] ?? order['key'] ?? '',
          'amount': order['amount'],
          'currency': order['currency'] ?? 'INR',
          'name': 'TechBes Rollout Deposit',
          'description': first.title,
          'order_id': order['orderId'] ?? order['id'] ?? '',
          'prefill': {
            'name': _nameController.text.trim(),
            'contact': _phoneController.text.trim(),
          },
          'timeout': 300,
        };
        _razorpay.open(options);
      }
    } catch (e) {
      debugPrint('Order fail: $e');
      setState(() {
        _isSubmitting = false;
        _checkoutError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final client = ref.read(dioClientProvider);
      final verifyResponse = await client.post(ApiConfig.verifyPayment, data: {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (verifyResponse.data != null && verifyResponse.data['success'] == true) {
        ref.read(cartProvider.notifier).clearCart();
        _showSuccessDialog();
      } else {
        throw Exception('Payment signature verification failed');
      }
    } catch (e) {
      debugPrint('Verify fail: $e');
      setState(() {
        _isSubmitting = false;
        _checkoutError = 'Signature verification failed: ${e.toString()}';
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[Razorpay] Failed: ${response.code} - ${response.message}');
    setState(() {
      _isSubmitting = false;
      _checkoutError = 'Payment failed: ${response.message ?? 'Cancelled by user'}';
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFD1FAE5),
                child: Icon(Icons.check, size: 36, color: const Color(0xFF047857)),
              ),
              const SizedBox(height: 20),
              const Text('Booking Confirmed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 8),
              const Text(
                'Your scheduled booking and deposit have been successfully registered. Track active milestones in dashboard.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                  context.go('/dashboard');
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).totalAmount;
    final advance = ref.read(cartProvider.notifier).advanceAmount;

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your checkout card list is empty.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Summary')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Saved Address Dropdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Service Address Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 10),
                        _isLoadingAddresses
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                            : DropdownButtonFormField<String>(
                                value: _selectedAddressId.isEmpty ? null : _selectedAddressId,
                                hint: const Text('Select saved address'),
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                items: [
                                  ..._savedAddresses.map((addr) => DropdownMenuItem<String>(
                                        value: addr['_id'],
                                        child: Text('${addr['label']} (${addr['city']})', style: const TextStyle(fontSize: 13)),
                                      )),
                                  const DropdownMenuItem<String>(
                                    value: 'new',
                                    child: Text('-- Create New Custom Location --', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    if (val == 'new') {
                                      _selectAddress({'_id': 'new'});
                                    } else {
                                      final addr = _savedAddresses.firstWhere((a) => a['_id'] == val);
                                      _selectAddress(addr);
                                    }
                                  }
                                },
                              ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 14),

                // 2. Map confirmation status
                if (!_showMap && _latitude != null && _longitude != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Confirmed Pin Location', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                              const SizedBox(height: 4),
                              Text(_addressController.text, style: const TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.35)),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: _openMapPicker,
                                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor, padding: EdgeInsets.zero, minimumSize: Size.zero),
                                child: const Text('Modify Pin Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Card(
                    child: InkWell(
                      onTap: _openMapPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            Icon(Icons.map_outlined, size: 32, color: AppTheme.textSecondaryColor),
                            SizedBox(height: 8),
                            Text('Confirm location coordinates on map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // 3. Contact & Schedule Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Recipient Name'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Recipient Name required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Recipient Phone'),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Phone number required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dateController,
                                decoration: const InputDecoration(labelText: 'Arrival Date', suffixIcon: Icon(Icons.calendar_month, size: 18)),
                                readOnly: true,
                                onTap: _pickDate,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Arrival Date required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _timeController,
                                decoration: const InputDecoration(labelText: 'Arrival Slot', suffixIcon: Icon(Icons.access_time, size: 18)),
                                readOnly: true,
                                onTap: _pickTime,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Arrival time required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Detailed Street Address'),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Address description required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(labelText: 'Special Directions (Optional)'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 4. Order Summary with Taxes Breakdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Detailed Booking Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 12),
                        ...cartItems.map((item) {
                          final serviceType = item.config?['serviceType'] ?? 'Standard';
                          final List<dynamic> materialsList = item.config?['materials'] ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('₹${(item.priceValue).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              Text(serviceType, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryColor)),
                              if (materialsList.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                ...materialsList.map((m) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('  • ${m['name']} ×${m['qty']}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                                          Text('₹${(m['total'] as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                                        ],
                                      ),
                                    )),
                              ],
                            ],
                          );
                        }),
                        const Divider(height: 20),
                        _buildSummaryLine('Subtotal', total / 1.18), // Deduct GST for breakdown
                        _buildSummaryLine('Estimated CGST / SGST (18%)', total - (total / 1.18)),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total (Incl. Taxes)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('50% Advance Payable Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.primaryColor)),
                            Text('₹${advance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: AppTheme.primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Note: The remaining 50% balance will be collected upon job verification & sign-off.',
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_checkoutError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                      child: Text(_checkoutError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Pay ₹${advance.toStringAsFixed(0)} Deposit & Confirm Booking'),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryLine(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          Text('₹${val.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }
}
