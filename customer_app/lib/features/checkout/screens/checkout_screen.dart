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
  
  // Data lists
  List<dynamic> _savedAddresses = [];
  bool _isLoadingAddresses = true;
  String _selectedAddressId = '';
  
  // Form states
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Location fields
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
    
    // Initialise Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Load initial states
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
          
          // Auto select default address
          final def = _savedAddresses.firstWhere((a) => a['isDefault'] == true, orElse: () => null);
          if (def != null) {
            _selectAddress(def);
          }
        });
      } else {
        setState(() => _isLoadingAddresses = false);
      }
    } catch (e) {
      debugPrint('Error loading saved addresses: $e');
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
      _addressController.text = addr['address'] ?? [addr['addressLine1'], addr['addressLine2']].filter((s) => s != null).join(', ');
      _pincode = addr['pincode'] ?? '';
      _city = addr['city'] ?? '';
      _state = addr['state'] ?? '';
      _latitude = addr['latitude'];
      _longitude = addr['longitude'];
      _mapLink = addr['googleMapLink'] ?? '';
      
      if (_latitude != null && _longitude != null) {
        _showMap = false;
      } else {
        _showMap = true;
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
                initialCoords: _latitude != null && _longitude != null
                    ? MapLatLng(_latitude!, _longitude!)
                    : null,
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
      setState(() {
        _checkoutError = 'Please pin and confirm your service location on the map.';
      });
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = ref.read(dioClientProvider);
      // Step 1: Create backend order
      final orderResponse = await client.post(ApiConfig.createOrder, data: {
        'bookingPayload': bookingPayload,
      });

      if (orderResponse.data != null) {
        final order = orderResponse.data;
        
        // Step 2: Open native Razorpay checkout
        final options = {
          'key': order['keyId'] ?? order['key'] ?? '',
          'amount': order['amount'],
          'currency': order['currency'] ?? 'INR',
          'name': order['description'] ?? 'Booking Payment',
          'description': first.title,
          'order_id': order['orderId'] ?? order['id'] ?? '',
          'prefill': {
            'name': _nameController.text.trim(),
            'contact': _phoneController.text.trim(),
          },
          'timeout': 300, // in seconds
        };

        _razorpay.open(options);
      }
    } catch (e) {
      debugPrint('Booking creation failed: $e');
      setState(() {
        _isSubmitting = false;
        _checkoutError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // Payment Handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('[Razorpay] Payment Success: $response');
    
    try {
      final client = ref.read(dioClientProvider);
      // Step 3: Verify payment signature with backend
      final verifyResponse = await client.post(ApiConfig.verifyPayment, data: {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (verifyResponse.data != null && verifyResponse.data['success'] == true) {
        // Clear cart
        ref.read(cartProvider.notifier).clearCart();
        
        // Show success alert
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      debugPrint('Payment verification failed: $e');
      setState(() {
        _isSubmitting = false;
        _checkoutError = 'Payment received, but verification failed: ${e.toString()}';
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[Razorpay] Payment Error: ${response.code} - ${response.message}');
    setState(() {
      _isSubmitting = false;
      _checkoutError = 'Payment failed: ${response.message ?? 'Unknown Error'}';
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[Razorpay] External Wallet Selected: ${response.walletName}');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 48, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 18, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your booking and advance payment were received successfully. A technician will be assigned shortly.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // dismiss dialog
                  context.go('/dashboard'); // route to dashboard
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
    final theme = Theme.of(context);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Saved Address Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Address Selection',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        _isLoadingAddresses
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                            : DropdownButtonFormField<String>(
                                value: _selectedAddressId.isEmpty ? null : _selectedAddressId,
                                hint: const Text('Select saved address'),
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                items: [
                                  ..._savedAddresses.map((addr) => DropdownMenuItem<String>(
                                        value: addr['_id'],
                                        child: Text('${addr['label']} (${addr['city']})', style: const TextStyle(fontSize: 13.5)),
                                      )),
                                  const DropdownMenuItem<String>(
                                    value: 'new',
                                    child: Text('-- Enter New Address --', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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
                
                const SizedBox(height: 16),

                // Location Confirmation summary or Picker
                if (!_showMap && _latitude != null && _longitude != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Service Pin Confirmed',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _addressController.text,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF047857), height: 1.4),
                              ),
                              if (_city.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('$_city, $_state - $_pincode', style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857))),
                                ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _openMapPicker,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Change Pin Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: InkWell(
                      onTap: _openMapPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          children: [
                            Icon(Icons.map_outlined, size: 36, color: AppTheme.textSecondaryColor),
                            SizedBox(height: 10),
                            Text('Pin Service Location on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            SizedBox(height: 2),
                            Text('Tap to open interactive map picker', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Form details Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Scheduling & Contact Information',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Customer Name'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Customer Name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Customer Phone'),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Customer Phone is required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dateController,
                                decoration: const InputDecoration(labelText: 'Arrival Date', suffixIcon: Icon(Icons.calendar_month, size: 20)),
                                readOnly: true,
                                onTap: _pickDate,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Date is required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _timeController,
                                decoration: const InputDecoration(labelText: 'Arrival Time', suffixIcon: Icon(Icons.access_time, size: 20)),
                                readOnly: true,
                                onTap: _pickTime,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Arrival time is required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Full Address Details'),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(labelText: 'Special Notes / Issue Descriptions'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Order summary Sidebar replica
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ...cartItems.map((item) {
                          final serviceType = item.config?['serviceType'] ?? 'Standard';
                          final materialsList = item.config?['materials'] as List<dynamic>? ?? [];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.between,
                                  children: [
                                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    Text('₹${(item.priceValue).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  ],
                                ),
                                Text(serviceType, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                                if (materialsList.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  ...materialsList.map((m) => Row(
                                        mainAxisAlignment: MainAxisAlignment.between,
                                        children: [
                                          Text('  • ${m['name']} ×${m['qty']}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                                          Text('₹${(m['total'] as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                                        ],
                                      )),
                                ],
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16, color: AppTheme.textPrimaryColor)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text('50% Advance Payable Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                            Text('₹${advance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 15, color: AppTheme.primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'The remaining 50% balance will be collected upon job verification & completion.',
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_checkoutError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _checkoutError!,
                        style: TextStyle(fontSize: 12.5, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Pay ₹${advance.toStringAsFixed(0)} Advance & Book'),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
