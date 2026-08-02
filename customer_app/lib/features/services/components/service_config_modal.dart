import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../cart/providers/cart_provider.dart';
import '../../checkout/components/map_location_picker.dart';
import '../../../core/config/payment_config.dart';

class ServiceConfigModal extends ConsumerStatefulWidget {
  final String serviceSlug;
  final String serviceName;
  final String categoryId;
  final String subcategoryId;
  final double defaultPrice;
  final VoidCallback? onQuoteRequested;

  const ServiceConfigModal({
    super.key,
    required this.serviceSlug,
    required this.serviceName,
    required this.categoryId,
    required this.subcategoryId,
    required this.defaultPrice,
    this.onQuoteRequested,
  });

  @override
  ConsumerState<ServiceConfigModal> createState() => _ServiceConfigModalState();
}

class _ServiceConfigModalState extends ConsumerState<ServiceConfigModal> {
  int _step = 1;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  late Razorpay _razorpay;

  // Static options for fallback and initial states
  List<dynamic> _bookingQuestions = [];
  final Map<String, dynamic> _bookingAnswers = {};
  bool _hasError = false;
  String _errorText = '';
  final List<String> _cameraTypesList = ['IP Camera', 'Analog Camera', 'WiFi Indoor Camera', 'WiFi Outdoor Camera', '4G Camera', 'Solar Camera'];
  final List<String> _cableTypesList = ['Cat6 Cable', '3+1 CCTV Cable'];
  final List<String> _sdCardCapacities = ['32GB', '64GB', '128GB', '256GB'];

  // CCTV Form selections
  String _cctvPropertyType = 'Home';
  final Map<String, bool> _cctvSelectedCameraTypes = {'IP Camera': true};
  final Map<String, int> _cctvCameraQuantities = {'IP Camera': 1};
  final Map<String, String> _cctvCameraBrands = {};
  final Map<String, String> _cctvCameraModels = {};
  bool _cctvInstallationRequired = true;
  String _cctvCableType = 'Cat6 Cable';
  int _cctvCableLength = 20;
  bool _cctvDvrRequired = false;
  bool _cctvNvrRequired = false;
  bool _cctvNetworkRack = false;
  bool _cctvMonitorMounting = false;
  bool _cctvSdCardEnabled = false;
  String _cctvSdCardCapacity = '64GB';
  int _cctvSdCardQuantity = 1;

  // Metadata arrays from backend
  List<dynamic> _cctvBrands = [];
  List<dynamic> _cctvAllModels = [];
  List<dynamic> _cctvSdCards = [];
  List<dynamic> _cctvCables = [];
  List<dynamic> _cctvInstallationCharges = [];
  List<dynamic> _cctvAccessories = [];

  // CCTV Products variables
  List<dynamic> _availableProducts = [];
  final Map<String, bool> _selectedProductsCheckboxes = {};
  final Map<String, int> _selectedProductQuantities = {};
  final Map<String, String> _selectedProductVariants = {};

  // Price calculations breakdown
  double _packageCost = 0;
  double _visitCharge = 499;
  double _labourCost = 0;
  double _discount = 0;
  double _gst = 0;
  double _grandTotal = 0;
  bool _isCalculatingPrice = false;

  // Date & Time slots
  DateTime? _selectedDate;
  String _selectedTimeSlot = '09:00 AM - 11:00 AM';
  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];
  final _notesController = TextEditingController();

  // Uploaded Images
  final List<String> _uploadedImages = [];
  bool _isSimulatingUpload = false;

  // Service Location Address
  List<dynamic> _savedAddresses = [];
  String _selectedAddressId = 'new';
  final _houseNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  double? _latitude;
  double? _longitude;
  String _mapLink = '';
  String _fullAddress = '';

  // Payment configuration
  String _paymentMethod = 'online'; // online (Razorpay) or wallet
  double _walletBalance = 0.0;
  String _customerName = '';
  String _customerPhone = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _fetchCctvMetadata();
    _fetchAddressesAndWallet();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _houseNumberController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchCctvMetadata() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorText = '';
    });
    try {
      final client = ref.read(dioClientProvider);
      final List<Future<dynamic>> requests = [
        client.get('/api/v2/cctv/brands'),
        client.get('/api/v2/cctv/models'),
        client.get('/api/v2/cctv/sd-cards'),
        client.get('/api/v2/cctv/cable-pricings'),
        client.get('/api/v2/cctv/installation-charges'),
        client.get('/api/v2/cctv/accessories'),
      ];
      if (widget.serviceSlug == 'buy-cctv-products') {
        requests.add(client.get('/api/v2/cctv/products'));
      } else {
        requests.add(client.get('/api/v2/catalog/subcategories/${widget.serviceSlug}/questions'));
      }
      final results = await Future.wait(requests);

      if (mounted) {
        setState(() {
          _cctvBrands = results[0].data['data'] ?? [];
          _cctvAllModels = results[1].data['data'] ?? [];
          _cctvSdCards = results[2].data['data'] ?? [];
          _cctvCables = results[3].data['data'] ?? [];
          _cctvInstallationCharges = results[4].data['data'] ?? [];
          _cctvAccessories = results[5].data['data'] ?? [];
          
          if (widget.serviceSlug == 'buy-cctv-products') {
            if (results.length > 6) {
              _availableProducts = results[6].data['data'] ?? [];
            }
          } else {
            if (results.length > 6) {
              _bookingQuestions = results[6].data['data'] ?? [];
              // Initialize answers with defaults
              _bookingAnswers.clear();
              for (var q in _bookingQuestions) {
                final qText = q['question'] ?? '';
                _bookingAnswers[qText] = q['type'] == 'multiselect' ? <String>[] : '';
              }
            }
          }

          // Initialize defaults for first selected camera type
          _initializeCameraDefaults();
          _isLoading = false;
        });
        _calculateEstimatePrice();
      }
    } catch (e) {
      debugPrint('Metadata fetch failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorText = 'Could not retrieve configuration details from server. Please check your network and try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _initializeCameraDefaults() {
    for (final type in _cameraTypesList) {
      if (_cctvBrands.isNotEmpty) {
        _cctvCameraBrands[type] = _cctvBrands[0]['_id'];
        final matchingModel = _cctvAllModels.firstWhere(
          (m) => m['cameraType'] == type && (m['brandId']?['_id'] == _cctvBrands[0]['_id'] || m['brandId'] == _cctvBrands[0]['_id']),
          orElse: () => _cctvAllModels.firstWhere((m) => m['cameraType'] == type, orElse: () => null),
        );
        if (matchingModel != null) {
          _cctvCameraModels[type] = matchingModel['_id'];
        }
      }
    }
  }

  Future<void> _fetchAddressesAndWallet() async {
    try {
      final client = ref.read(dioClientProvider);
      final results = await Future.wait([
        client.get('/api/user/addresses'),
        client.get('/api/auth/me'),
        client.get('/api/v2/wallet'),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].data != null && results[0].data['success'] == true) {
            _savedAddresses = results[0].data['data'] ?? [];
            if (_savedAddresses.isNotEmpty) {
              _selectSavedAddress(_savedAddresses[0]);
            }
          }
          if (results[1].data != null && results[1].data['success'] == true) {
            final user = results[1].data['data'];
            _customerName = user['name'] ?? '';
            _customerPhone = user['mobileNumber'] ?? user['phone'] ?? '';
          }
          if (results[2].data != null && results[2].data['success'] == true) {
            _walletBalance = (results[2].data['data']['balance'] as num).toDouble();
          }
        });
      }
    } catch (e) {
      debugPrint('Addresses or profile load failed: $e');
    }
  }

  void _selectSavedAddress(dynamic addr) {
    setState(() {
      _selectedAddressId = addr['_id'] ?? 'new';
      _houseNumberController.text = addr['houseNumber'] ?? '';
      _streetController.text = addr['street'] ?? '';
      _areaController.text = addr['area'] ?? '';
      _landmarkController.text = addr['landmark'] ?? '';
      _pincodeController.text = addr['pincode'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _stateController.text = addr['state'] ?? '';
      _latitude = addr['latitude'] != null ? (addr['latitude'] as num).toDouble() : null;
      _longitude = addr['longitude'] != null ? (addr['longitude'] as num).toDouble() : null;
      _mapLink = addr['mapLink'] ?? '';
    });
  }

  void _resetAddressForm() {
    setState(() {
      _selectedAddressId = 'new';
      _houseNumberController.clear();
      _streetController.clear();
      _areaController.clear();
      _landmarkController.clear();
      _pincodeController.clear();
      _cityController.clear();
      _stateController.clear();
      _latitude = null;
      _longitude = null;
      _mapLink = '';
    });
  }

  Future<void> _calculateEstimatePrice() async {
    if (widget.serviceSlug == 'buy-cctv-products') {
      final productsTotal = _selectedProductsList.fold<double>(0, (sum, p) => sum + p['total']);
      const deliveryCharge = 199.0;
      final baseTotal = productsTotal + deliveryCharge;
      final gstVal = (baseTotal * 0.18).roundToDouble();
      final grandTotalVal = baseTotal + gstVal;

      setState(() {
        _packageCost = productsTotal;
        _visitCharge = deliveryCharge;
        _labourCost = 0;
        _discount = 0;
        _gst = gstVal;
        _grandTotal = grandTotalVal;
        _isCalculatingPrice = false;
      });
      return;
    }

    final isInstallation = widget.serviceSlug == 'install-new-cctv' || widget.serviceSlug.contains('install');
    if (!isInstallation) {
      setState(() {
        _packageCost = widget.defaultPrice;
        _visitCharge = 0.0;
        _labourCost = 0.0;
        _discount = 0.0;
        _gst = (_packageCost * 0.18).roundToDouble();
        _grandTotal = _packageCost + _gst;
        _isCalculatingPrice = false;
      });
      return;
    }

    final activeTypes = _cctvSelectedCameraTypes.entries.where((e) => e.value).map((e) => e.key).toList();
    if (activeTypes.isEmpty) {
      setState(() {
        _packageCost = 0;
        _labourCost = 0;
        _gst = 0;
        _grandTotal = 0;
      });
      return;
    }

    setState(() => _isCalculatingPrice = true);

    final List<Map<String, dynamic>> cameraTypesPayload = [];
    for (final type in activeTypes) {
      cameraTypesPayload.add({
        'type': type,
        'brandId': _cctvCameraBrands[type] ?? '',
        'modelId': _cctvCameraModels[type] ?? '',
        'quantity': _cctvCameraQuantities[type] ?? 1,
      });
    }

    final payload = {
      'subcategoryId': widget.subcategoryId,
      'subcategorySlug': widget.serviceSlug,
      'propertyType': _cctvPropertyType,
      'cameraTypes': cameraTypesPayload,
      'installationRequired': _cctvInstallationRequired,
      'cableType': _cctvCableType,
      'cableLength': _cctvCableLength,
      'dvrRequired': _cctvDvrRequired,
      'nvrRequired': _cctvNvrRequired,
      'networkRack': _cctvNetworkRack,
      'monitorMounting': _cctvMonitorMounting,
      'sdCardRequired': _cctvSdCardEnabled,
      'sdCardCapacity': _cctvSdCardCapacity,
      'sdCardQuantity': _cctvSdCardQuantity,
    };

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.post('/api/v2/cctv/calculate-price', data: payload);
      
      if (response.data != null && response.data['success'] == true && mounted) {
        final pb = response.data['data']['priceBreakdown'];
        setState(() {
          _packageCost = (pb['installationTotal'] as num).toDouble();
          _visitCharge = (pb['baseCharge'] as num).toDouble();
          
          double otherAddons = 0;
          otherAddons += (pb['cameraTotal'] as num).toDouble();
          otherAddons += (pb['cableTotal'] as num).toDouble();
          otherAddons += (pb['sdCardTotal'] as num).toDouble();
          otherAddons += (pb['dvrTotal'] as num).toDouble();
          otherAddons += (pb['nvrTotal'] as num).toDouble();
          otherAddons += (pb['rackTotal'] as num).toDouble();
          otherAddons += (pb['monitorTotal'] as num).toDouble();

          _labourCost = otherAddons;
          _discount = 0;
          _gst = (pb['taxTotal'] as num).toDouble();
          _grandTotal = (pb['grandTotal'] as num).toDouble();
          _isCalculatingPrice = false;
        });
      }
    } catch (e) {
      debugPrint('Price calculation API failed, using fallback calculations: $e');
      // Offline/Error Local pricing fallback
      double camerasTotal = 0;
      for (final type in activeTypes) {
        final modelId = _cctvCameraModels[type];
        final model = _cctvAllModels.firstWhere((m) => m['_id'] == modelId, orElse: () => null);
        final price = model != null ? (model['price'] as num).toDouble() : 1400.0;
        camerasTotal += price * (_cctvCameraQuantities[type] ?? 1);
      }

      double installationTotal = _cctvInstallationRequired ? (activeTypes.length * 400.0) : 0.0;
      double cableTotal = _cctvInstallationRequired ? (_cctvCableLength * (_cctvCableType.contains('Cat6') ? 45.0 : 35.0)) : 0.0;
      double sdTotal = _cctvSdCardEnabled ? (_cctvSdCardQuantity * (_cctvSdCardCapacity == '32GB' ? 299.0 : _cctvSdCardCapacity == '64GB' ? 499.0 : 899.0)) : 0.0;
      double dvrTotal = _cctvDvrRequired ? 2500.0 : 0.0;
      double nvrTotal = _cctvNvrRequired ? 3500.0 : 0.0;
      double rackTotal = _cctvNetworkRack ? 1200.0 : 0.0;
      double monitorTotal = _cctvMonitorMounting ? 800.0 : 0.0;
      double baseVisit = widget.defaultPrice;

      double subTotal = baseVisit + camerasTotal + installationTotal + cableTotal + sdTotal + dvrTotal + nvrTotal + rackTotal + monitorTotal;
      double tax = subTotal * 0.18;

      if (mounted) {
        setState(() {
          _packageCost = installationTotal;
          _visitCharge = baseVisit;
          _labourCost = camerasTotal + cableTotal + sdTotal + dvrTotal + nvrTotal + rackTotal + monitorTotal;
          _gst = tax;
          _grandTotal = subTotal + tax;
          _isCalculatingPrice = false;
        });
      }
    }
  }

  void _openMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    _pincodeController.text = data.pincode;
                    _fullAddress = data.address;
                    _cityController.text = data.city;
                    _stateController.text = data.state;
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

  void _simulateImageUpload() async {
    setState(() => _isSimulatingUpload = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        final mockIndex = _uploadedImages.length + 1;
        _uploadedImages.add('https://images.unsplash.com/photo-1557862921-37829c790f19?w=600&fit=crop&q=80&mock=$mockIndex');
        _isSimulatingUpload = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site image uploaded successfully (Simulated)')),
      );
    }
  }

  Map<String, dynamic> _buildBookingPayload() {
    final isBuyCctvProducts = widget.serviceSlug == 'buy-cctv-products';
    final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
    
    final activeTypes = _cctvSelectedCameraTypes.entries.where((e) => e.value).map((e) => e.key).toList();
    final List<Map<String, dynamic>> cameraTypesPayload = [];
    for (final type in activeTypes) {
      cameraTypesPayload.add({
        'type': type,
        'brandId': _cctvCameraBrands[type] ?? '',
        'modelId': _cctvCameraModels[type] ?? '',
        'quantity': _cctvCameraQuantities[type] ?? 1,
      });
    }

    final formattedAddress = '${_houseNumberController.text.trim()}, ${_streetController.text.trim()}, ${_areaController.text.trim()}, ${_landmarkController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim()} - ${_pincodeController.text.trim()}';

    return {
      'service': widget.serviceName,
      'serviceId': widget.subcategoryId,
      'serviceName': widget.serviceName,
      'address': formattedAddress,
      'description': _notesController.text.isNotEmpty ? _notesController.text.trim() : 'Booking requested via customer app',
      'date': dateStr,
      'timeSlot': isBuyCctvProducts ? null : _selectedTimeSlot,
      'customerName': _customerName.isNotEmpty ? _customerName : 'Techbes User',
      'customerPhone': _customerPhone.isNotEmpty ? _customerPhone : '9900012345',
      'totalAmount': _grandTotal,
      'serviceType': isBuyCctvProducts ? 'other' : 'installation',
      'latitude': _latitude ?? 12.9716,
      'longitude': _longitude ?? 77.5946,
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'bookingAnswers': isBuyCctvProducts ? <Map<String, dynamic>>[] : _bookingAnswers.entries.map((e) {
        final val = e.value;
        return {
          'question': e.key,
          'answer': val is List ? val.join(', ') : val.toString(),
        };
      }).toList(),
      'uploadedImages': isBuyCctvProducts ? <String>[] : _uploadedImages,
      'houseNumber': _houseNumberController.text.trim(),
      'street': _streetController.text.trim(),
      'area': _areaController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      if (isBuyCctvProducts) 'products': _selectedProductsList,
      'cctvDetails': {
        'category': {'name': 'CCTV', 'slug': 'cctv'},
        'subcategory': {'id': widget.subcategoryId, 'name': widget.serviceName, 'slug': widget.serviceSlug},
        'priceBreakdown': {
          'packageCost': _packageCost,
          'visitCharge': _visitCharge,
          'labourCost': _labourCost,
          'discount': _discount,
          'gst': _gst,
          'grandTotal': _grandTotal,
        },
        'notes': _notesController.text.trim(),
        if (isBuyCctvProducts) 'products': _selectedProductsList,
        if (!isBuyCctvProducts) ...{
          'propertyType': _cctvPropertyType,
          'cameraTypes': cameraTypesPayload,
          'installationRequired': _cctvInstallationRequired,
          'cableType': _cctvCableType,
          'cableLength': _cctvCableLength,
          'dvrRequired': _cctvDvrRequired,
          'nvrRequired': _cctvNvrRequired,
          'networkRack': _cctvNetworkRack,
          'monitorMounting': _cctvMonitorMounting,
          'sdCardRequired': _cctvSdCardEnabled,
          'sdCardCapacity': _cctvSdCardCapacity,
          'sdCardQuantity': _cctvSdCardQuantity
        }
      }
    };
  }

  void _handleSubmitBooking() async {
    setState(() => _isSubmitting = true);
    
    // Create address if needed first
    final client = ref.read(dioClientProvider);
    String? finalAddressId = _selectedAddressId != 'new' ? _selectedAddressId : null;

    if (_selectedAddressId == 'new') {
      try {
        final formattedAddress = '${_houseNumberController.text.trim()}, ${_streetController.text.trim()}, ${_areaController.text.trim()}, ${_landmarkController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim()} - ${_pincodeController.text.trim()}';
        
        final addrRes = await client.post('/api/user/address', data: {
          'houseNumber': _houseNumberController.text.trim(),
          'street': _streetController.text.trim(),
          'area': _areaController.text.trim(),
          'landmark': _landmarkController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'latitude': _latitude ?? 12.9716,
          'longitude': _longitude ?? 77.5946,
          'manualNotes': _notesController.text.trim(),
          'formattedAddress': formattedAddress,
          'isDefault': _savedAddresses.isEmpty,
        });

        if (addrRes.data != null && addrRes.data['success'] == true && addrRes.data['data'] != null) {
          finalAddressId = addrRes.data['data']['_id'];
        }
      } catch (e) {
        debugPrint('Address creation failed, continuing with manual address: $e');
      }
    }

    final payload = _buildBookingPayload();
    if (finalAddressId != null) {
      payload['addressId'] = finalAddressId;
    }

    if (PaymentConfig.isTestMode) {
      payload['totalAmount'] = 2.0;
    }

    try {
      if (_paymentMethod == 'online') {
        // Razorpay integration
        final orderResponse = await client.post(ApiConfig.createOrder, data: {'bookingPayload': payload});
        if (orderResponse.data != null) {
          final orderData = orderResponse.data;
          
          final options = {
            'key': orderData['keyId'] ?? orderData['key'] ?? '',
            'amount': orderData['amount'],
            'currency': orderData['currency'] ?? 'INR',
            'name': 'Techbes Security',
            'description': widget.serviceSlug == 'buy-cctv-products' ? 'Payment for CCTV Products Order' : 'Booking advance payment for CCTV installation',
            'order_id': orderData['orderId'] ?? orderData['id'] ?? '',
            'prefill': {
              'name': _customerName.isNotEmpty ? _customerName : 'Techbes User',
              'contact': _customerPhone.isNotEmpty ? _customerPhone : '9900012345'
            },
            'timeout': 300,
          };
          _razorpay.open(options);
        } else {
          throw Exception('Failed to initiate Razorpay order on backend');
        }
      } else if (_paymentMethod == 'wallet') {
        // Direct Wallet deduction
        if (_walletBalance < _grandTotal) {
          throw Exception('Insufficient wallet balance. Please add funds or pay online.');
        }

        // 1. Create booking
        final bookingRes = await client.post('/api/v2/bookings/create', data: payload);
        if (bookingRes.data != null && bookingRes.data['success'] == true) {
          final job = bookingRes.data['data'] ?? bookingRes.data['job'];
          final jobId = job['_id'] ?? job['id'];
          
          // 2. Pay using wallet balance
          final payRes = await client.post('/api/v2/wallet/pay-booking', data: {
            'jobId': jobId,
            'amount': _grandTotal,
          });

          if (payRes.data != null && payRes.data['success'] == true) {
            _showSuccessDialog();
          } else {
            throw Exception(payRes.data['message'] ?? 'Wallet deduction failed.');
          }
        } else {
          throw Exception('Booking creation failed');
        }
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
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

      if (verifyResponse.data != null && verifyResponse.data['success'] == true && mounted) {
        _showSuccessDialog();
      } else {
        throw Exception('Signature verification failed on server');
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Verification error: ${e.toString()}';
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment failed: ${response.code} - ${response.message}');
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Payment failed: ${response.message ?? 'Cancelled by user'}';
      });
    }
  }

  void _showSuccessDialog() {
    final isBuyCctvProducts = widget.serviceSlug == 'buy-cctv-products';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFD1FAE5),
                child: Icon(Icons.check, color: Color(0xFF10B981), size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                isBuyCctvProducts ? 'Order Confirmed!' : 'Booking Confirmed!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                isBuyCctvProducts
                    ? 'Your CCTV products purchase order is confirmed and will be shipped to your delivery address.'
                    : 'Your CCTV installation appointment is scheduled. We have verified your deposit and assigned a certified technician.',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close bottom sheet
                  context.go('/'); // Back to home
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goNext() {
    final isBuy = widget.serviceSlug == 'buy-cctv-products';
    final isInstallation = widget.serviceSlug == 'install-new-cctv' || widget.serviceSlug.contains('install');
    if (_step == 1) {
      if (isBuy) {
        if (_selectedProductsList.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one product to continue')),
          );
          return;
        }
      } else {
        // Validate required dynamic questions
        for (var q in _bookingQuestions) {
          final qText = q['question'] as String? ?? '';
          final isRequired = q['required'] as bool? ?? false;
          final answer = _bookingAnswers[qText];
          if (isRequired) {
            if (answer == null || 
                (answer is String && answer.trim().isEmpty) ||
                (answer is List && answer.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please answer: $qText')),
              );
              return;
            }
          }
        }

        if (isInstallation) {
          final hasActive = _cctvSelectedCameraTypes.values.any((v) => v);
          if (!hasActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select at least one camera type to continue')),
            );
            return;
          }
        }
      }
    } else if (_step == 2) {
      if (!isBuy && _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a scheduled date to continue')),
        );
        return;
      }
    } else if (_step == 3) {
      if (isBuy && _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a delivery date to continue')),
        );
        return;
      }
    } else if (_step == 4) {
      if (_houseNumberController.text.trim().isEmpty || 
          _streetController.text.trim().isEmpty || 
          _pincodeController.text.trim().isEmpty ||
          _areaController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _stateController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required address fields')),
        );
        return;
      }
    }
    
    if (_step < 6) {
      setState(() {
        _step++;
        _errorMessage = null;
      });
    } else {
      _handleSubmitBooking();
    }
  }

  void _goPrev() {
    if (_step > 1) {
      setState(() {
        _step--;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return SizedBox(
        height: 350,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Failed to Load Details',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                _errorText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchCctvMetadata,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const SizedBox(
        height: 350,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    final theme = Theme.of(context);
    final isLastStep = _step == 6;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Indicator handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.serviceSlug == 'buy-cctv-products' ? 'Purchase CCTV Products' : 'Book CCTV Installation',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.serviceSlug == 'buy-cctv-products'
                            ? 'Select the equipment modules to deliver to your address'
                            : 'Complete the steps to schedule your setup rollout',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => context.pop()),
              ],
            ),
          ),
          const Divider(height: 1),

          // Horizontal Stepper Progress Bar
          _buildStepperBar(),

          // Main Step Wizard Form View
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _buildCurrentStepContent(),
              ),
            ),
          ),

          // Sticky pricing summary / checkout feedback bar
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.red.shade50,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

          _buildBottomActionButtons(theme, isLastStep),
        ],
      ),
    );
  }

  Widget _buildStepperBar() {
    final stepLabels = widget.serviceSlug == 'buy-cctv-products'
        ? ['Products', 'Variants', 'Delivery', 'Address', 'Cart', 'Checkout']
        : ['Details', 'Schedule', 'Images', 'Location', 'Estimate', 'Checkout'];
    return Container(
      color: const Color(0xFFF8FAFC), // Slate 50
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(stepLabels.length, (idx) {
            final active = (idx + 1) == _step;
            final done = (idx + 1) < _step;
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: active 
                      ? AppTheme.primaryColor 
                      : (done ? const Color(0xFFD1FAE5) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active 
                        ? AppTheme.primaryColor 
                        : (done ? const Color(0xFF34D399) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (done) 
                        const Icon(Icons.check, size: 10, color: Color(0xFF065F46))
                      else
                        Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: active ? Colors.white : AppTheme.textSecondaryColor,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        stepLabels[idx],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: active 
                            ? Colors.white 
                            : (done ? const Color(0xFF065F46) : AppTheme.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < stepLabels.length - 1)
                  Container(
                    width: 14,
                    height: 1.5,
                    color: done ? const Color(0xFF34D399) : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    if (widget.serviceSlug == 'buy-cctv-products') {
      switch (_step) {
        case 1:
          return _buildStep1SelectProducts();
        case 2:
          return _buildStep2QuantityVariants();
        case 3:
          return _buildStep3DeliveryDate();
        case 4:
          return _buildStep4Location();
        case 5:
          return _buildStep5CartReview();
        case 6:
          return _buildStep6CheckoutPay();
        default:
          return const SizedBox();
      }
    }
    switch (_step) {
      case 1:
        return _buildStep1Details();
      case 2:
        return _buildStep2DateTime();
      case 3:
        return _buildStep3UploadImages();
      case 4:
        return _buildStep4Location();
      case 5:
        return _buildStep5Estimate();
      case 6:
        return _buildStep6CheckoutPay();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Details() {
    final isInstallation = widget.serviceSlug == 'install-new-cctv' || widget.serviceSlug.contains('install');
    
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Dynamic Booking Questions
        if (_bookingQuestions.isNotEmpty) ...[
          ..._bookingQuestions.map((q) {
            final qText = q['question'] as String? ?? '';
            final qType = q['type'] as String? ?? 'text';
            final options = (q['options'] as List?)?.map((o) => o.toString()).toList() ?? [];
            final isRequired = q['required'] as bool? ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          qText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimaryColor),
                        ),
                      ),
                      if (isRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Required', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (qType == 'select') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _bookingAnswers[qText]?.toString().isEmpty == false ? _bookingAnswers[qText] : null,
                          hint: const Text('Choose option...', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          items: options.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt,
                              child: Text(opt, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _bookingAnswers[qText] = val;
                              if (qText == 'Select Property Type') {
                                _cctvPropertyType = val ?? 'Home';
                              }
                            });
                            _calculateEstimatePrice();
                          },
                        ),
                      ),
                    ),
                  ] else if (qType == 'multiselect') ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.map((opt) {
                        final selectedList = List<String>.from(_bookingAnswers[qText] as List? ?? []);
                        final isSelected = selectedList.contains(opt);
                        return ChoiceChip(
                          label: Text(opt),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedList.add(opt);
                              } else {
                                selectedList.remove(opt);
                              }
                              _bookingAnswers[qText] = selectedList;
                            });
                            _calculateEstimatePrice();
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.08),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                          ),
                          side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    TextField(
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Enter details...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _bookingAnswers[qText] = val;
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ] else if (!isInstallation) ...[
          const SizedBox(height: 20),
          const Center(child: Text('No details questions required. Please tap Continue.', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13))),
          const SizedBox(height: 20),
        ],

        // 2. Hardware selection (only for installation setups)
        if (isInstallation) ...[
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          const Text('Choose Cameras to Install', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 4),
          const Text('Select one or more camera types and configure their models & quantities.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 12),
          ..._cameraTypesList.map((type) {
            final isSelected = _cctvSelectedCameraTypes[type] ?? false;
            final qty = _cctvCameraQuantities[type] ?? 1;
            final activeBrand = _cctvCameraBrands[type] ?? '';
            final activeModel = _cctvCameraModels[type] ?? '';

            final typeModels = _cctvAllModels.where((m) => m['cameraType'] == type).toList();
            final brandModels = typeModels.where((m) => m['brandId']?['_id'] == activeBrand || m['brandId'] == activeBrand).toList();

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                _cctvSelectedCameraTypes[type] = val ?? false;
                                if (val == true && !_cctvCameraQuantities.containsKey(type)) {
                                  _cctvCameraQuantities[type] = 1;
                                }
                              });
                              _calculateEstimatePrice();
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
                        const Spacer(),
                        if (isSelected)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.primaryColor),
                                onPressed: qty > 1 ? () {
                                  setState(() => _cctvCameraQuantities[type] = qty - 1);
                                  _calculateEstimatePrice();
                                } : null,
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryColor),
                                onPressed: () {
                                  setState(() => _cctvCameraQuantities[type] = qty + 1);
                                  _calculateEstimatePrice();
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Brand', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: activeBrand.isNotEmpty ? activeBrand : null,
                                      hint: const Text('Brand', style: TextStyle(fontSize: 11)),
                                      items: _cctvBrands.map((b) {
                                        return DropdownMenuItem<String>(
                                          value: b['_id'],
                                          child: Text(b['name'] ?? '', style: const TextStyle(fontSize: 12)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _cctvCameraBrands[type] = val ?? '';
                                          final matchingModel = _cctvAllModels.firstWhere(
                                            (m) => m['cameraType'] == type && (m['brandId']?['_id'] == val || m['brandId'] == val),
                                            orElse: () => _cctvAllModels.firstWhere((m) => m['cameraType'] == type, orElse: () => null),
                                          );
                                          if (matchingModel != null) {
                                            _cctvCameraModels[type] = matchingModel['_id'];
                                          }
                                        });
                                        _calculateEstimatePrice();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Resolution / Model', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: activeModel.isNotEmpty ? activeModel : null,
                                      hint: const Text('Model', style: TextStyle(fontSize: 11)),
                                      items: (activeBrand.isNotEmpty ? brandModels : typeModels).map((m) {
                                        final mPrice = (m['price'] as num).toDouble();
                                        return DropdownMenuItem<String>(
                                          value: m['_id'],
                                          child: Text('${m['resolution'] ?? ''} ${m['name'] ?? ''} (₹${mPrice.round()})', style: const TextStyle(fontSize: 10)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _cctvCameraModels[type] = val ?? '';
                                        });
                                        _calculateEstimatePrice();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 8),

          // Cable configurations
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Installation Cabling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
                      Switch(
                        value: _cctvInstallationRequired,
                        onChanged: (val) {
                          setState(() => _cctvInstallationRequired = val);
                          _calculateEstimatePrice();
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  if (_cctvInstallationRequired) ...[
                    const Divider(height: 12),
                    Row(
                      children: [
                        const Text('Cable Type', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _cctvCableType,
                          items: _cableTypesList.map((t) {
                            return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _cctvCableType = val!);
                            _calculateEstimatePrice();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Estimated Length', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                        const Spacer(),
                        Text('$_cctvCableLength m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Slider(
                      value: _cctvCableLength.toDouble(),
                      min: 0,
                      max: 200,
                      divisions: 40,
                      label: '$_cctvCableLength meters',
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setState(() => _cctvCableLength = val.round());
                      },
                      onChangeEnd: (val) {
                        _calculateEstimatePrice();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Recorder and mounts
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recorders & Mount Addons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('CCTV DVR Installation Required', style: TextStyle(fontSize: 12)),
                    value: _cctvDvrRequired,
                    onChanged: (val) {
                      setState(() => _cctvDvrRequired = val ?? false);
                      _calculateEstimatePrice();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('CCTV NVR Installation Required', style: TextStyle(fontSize: 12)),
                    value: _cctvNvrRequired,
                    onChanged: (val) {
                      setState(() => _cctvNvrRequired = val ?? false);
                      _calculateEstimatePrice();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('Include Server Network Rack / Casing', style: TextStyle(fontSize: 12)),
                    value: _cctvNetworkRack,
                    onChanged: (val) {
                      setState(() => _cctvNetworkRack = val ?? false);
                      _calculateEstimatePrice();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('Add Monitor Wall Mounting Bracket', style: TextStyle(fontSize: 12)),
                    value: _cctvMonitorMounting,
                    onChanged: (val) {
                      setState(() => _cctvMonitorMounting = val ?? false);
                      _calculateEstimatePrice();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Storage / SD card configuration
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Memory Cards (Storage)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
                      Switch(
                        value: _cctvSdCardEnabled,
                        onChanged: (val) {
                          setState(() => _cctvSdCardEnabled = val);
                          _calculateEstimatePrice();
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  if (_cctvSdCardEnabled) ...[
                    const Divider(height: 12),
                    Row(
                      children: [
                        const Text('SD Card Capacity', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _cctvSdCardCapacity,
                          items: _sdCardCapacities.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _cctvSdCardCapacity = val!);
                            _calculateEstimatePrice();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Quantity', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.primaryColor),
                          onPressed: _cctvSdCardQuantity > 1 ? () {
                            setState(() => _cctvSdCardQuantity--);
                            _calculateEstimatePrice();
                          } : null,
                        ),
                        Text('$_cctvSdCardQuantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryColor),
                          onPressed: () {
                            setState(() => _cctvSdCardQuantity++);
                            _calculateEstimatePrice();
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2DateTime() {
    final formattedDate = _selectedDate != null 
        ? DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!) 
        : 'Pick preferred schedule date';

    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Schedule Appointment Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          title: Text(
            formattedDate,
            style: TextStyle(
              fontSize: 13,
              fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
              color: _selectedDate != null ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
              firstDate: now.add(const Duration(days: 1)),
              lastDate: now.add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
        ),
        const SizedBox(height: 24),
        const Text('Choose Arrival Time Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Select an operational window for our technician to arrive.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 12),
        ..._timeSlots.map((slot) {
          final isSelected = _selectedTimeSlot == slot;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
            ),
            child: RadioListTile<String>(
              value: slot,
              groupValue: _selectedTimeSlot,
              title: Text(slot, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              onChanged: (val) {
                setState(() => _selectedTimeSlot = val!);
              },
              activeColor: AppTheme.primaryColor,
              dense: true,
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        const Text('Special Directives / Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Enter floor number, gate restrictions, or structural safety instructions here...',
          ),
        ),
      ],
    );
  }

  Widget _buildStep3UploadImages() {
    return Column(
      key: const ValueKey('step_3'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Upload Site Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Attach pictures of camera mounting walls or DVR storage locations. Helps our engineer plan ahead.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 16),
        
        if (_uploadedImages.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _uploadedImages.length,
            itemBuilder: (context, idx) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _uploadedImages[idx],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.blueGrey.shade50,
                          child: const Icon(Icons.image, color: Colors.blueGrey),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 10, color: Colors.white),
                        onPressed: () => setState(() => _uploadedImages.removeAt(idx)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: InkWell(
            onTap: _isSimulatingUpload ? null : _simulateImageUpload,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              child: Column(
                children: [
                  _isSimulatingUpload 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                      : const Icon(Icons.cloud_upload_outlined, size: 40, color: AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    _isSimulatingUpload ? 'Uploading picture...' : 'Choose or Take Photo',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text('Supports JPG, PNG formats up to 5MB', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Location() {
    return Column(
      key: const ValueKey('step_4'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Service Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        if (_savedAddresses.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedAddressId,
                items: [
                  ..._savedAddresses.map((a) {
                    final display = a['formattedAddress'] ?? '${a['houseNumber']}, ${a['street']}, ${a['city']}';
                    return DropdownMenuItem(
                      value: a['_id'] as String,
                      child: Text(display, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                    );
                  }),
                  const DropdownMenuItem(
                    value: 'new',
                    child: Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 12.5)),
                  ),
                ],
                onChanged: (val) {
                  if (val == 'new') {
                    _resetAddressForm();
                  } else {
                    final addr = _savedAddresses.firstWhere((a) => a['_id'] == val);
                    _selectSavedAddress(addr);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_latitude != null && _longitude != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5), // Emerald 50
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    const Text('Location Coordinates Pinned', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 12.5)),
                    const Spacer(),
                    TextButton(
                      onPressed: _openMapPicker,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text('Re-Pin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                if (_fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_fullAddress, style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857), height: 1.45)),
                ],
              ],
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              onTap: _openMapPicker,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Column(
                  children: [
                    Icon(Icons.map_outlined, size: 36, color: AppTheme.primaryColor),
                    SizedBox(height: 10),
                    Text('Pin Location on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('Coordinates are verified for technician travel eligibility', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),

        // Text Fields
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _houseNumberController,
                decoration: const InputDecoration(labelText: 'House / Flat No.*', hintText: 'Flat 402'),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode*', hintText: '560001'),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _streetController,
          decoration: const InputDecoration(labelText: 'Street Name / Apartment Name*', hintText: 'Green Glen Layout Road'),
          style: const TextStyle(fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _areaController,
          decoration: const InputDecoration(labelText: 'Area / Landmark*', hintText: 'Behind Techbes Office'),
          style: const TextStyle(fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City*', hintText: 'Bengaluru'),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State*', hintText: 'Karnataka'),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep5Estimate() {
    return Column(
      key: const ValueKey('step_5'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Review Estimate Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        
        Card(
          color: const Color(0xFFF8FAFC), // Slate 50
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service package cost', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                    Text('Rs. ${_packageCost.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Technician visitation fee', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                    Text('Rs. ${_visitCharge.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                  ],
                ),
                if (_labourCost > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Labor / Cabling & Hardware', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                      Text('Rs. ${_labourCost.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GST (18%)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                    Text('Rs. ${_gst.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFCBD5E1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                    _isCalculatingPrice
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                        : Text(
                            'Rs. ${_grandTotal.round().toLocaleString()}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB), // Amber 50
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prices cover baseline technician service & travel fees. Spare components or additional camera lengths recommended on-site will be billed separately by the engineer.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.45, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep6CheckoutPay() {
    return Column(
      key: const ValueKey('step_6'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Choose Payment Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Select a secure settlement method for the order deposit', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 16),

        // Pay Online option
        InkWell(
          onTap: () => setState(() => _paymentMethod = 'online'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _paymentMethod == 'online' ? AppTheme.primaryColor.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _paymentMethod == 'online' ? AppTheme.primaryColor : const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: Row(
              children: [
                Radio<String>(
                  value: 'online',
                  groupValue: _paymentMethod,
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay Online (Razorpay)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _paymentMethod == 'online' ? AppTheme.primaryColor : AppTheme.textPrimaryColor),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Secure checkout supporting credit cards, debit cards, UPI, and net banking.',
                        style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pay from Wallet option
        InkWell(
          onTap: _walletBalance >= _grandTotal 
              ? () => setState(() => _paymentMethod = 'wallet')
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: _walletBalance >= _grandTotal ? 1.0 : 0.6,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _paymentMethod == 'wallet' ? AppTheme.primaryColor.withOpacity(0.04) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _paymentMethod == 'wallet' ? AppTheme.primaryColor : const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'wallet',
                    groupValue: _paymentMethod,
                    onChanged: _walletBalance >= _grandTotal 
                        ? (val) => setState(() => _paymentMethod = val!)
                        : null,
                    activeColor: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TechBes Wallet Balance',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _paymentMethod == 'wallet' ? AppTheme.primaryColor : AppTheme.textPrimaryColor),
                            ),
                            Text(
                              'Available: ₹${_walletBalance.round()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Deduct the grand total directly from your registered Techbes wallet balance.',
                          style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryColor),
                        ),
                        if (_walletBalance < _grandTotal) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Insufficient balance. Need ₹${(_grandTotal - _walletBalance).round()} more.',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons(ThemeData theme, bool isLastStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 1)
            OutlinedButton(
              onPressed: _isSubmitting ? null : _goPrev,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: const Text('Back', style: TextStyle(fontSize: 12)),
            )
          else
            const SizedBox(),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _goNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastStep ? const Color(0xFF10B981) : AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isSubmitting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    isLastStep ? 'Confirm & Pay ₹${_grandTotal.round()}' : 'Continue',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  void _toggleProductSelection(String prodName) {
    setState(() {
      final wasChecked = _selectedProductsCheckboxes[prodName] ?? false;
      final isChecked = !wasChecked;
      _selectedProductsCheckboxes[prodName] = isChecked;
      if (isChecked) {
        _selectedProductQuantities[prodName] = 1;
        final dbProd = _availableProducts.firstWhere(
          (p) => p['name'] == prodName,
          orElse: () => null,
        );
        if (dbProd != null && dbProd['variants'] != null && (dbProd['variants'] as List).isNotEmpty) {
          _selectedProductVariants[prodName] = dbProd['variants'][0]['name'];
        }
      }
    });
    _calculateEstimatePrice();
  }

  List<Map<String, dynamic>> get _selectedProductsList {
    final List<Map<String, dynamic>> list = [];
    
    _selectedProductsCheckboxes.forEach((prodName, checked) {
      if (!checked) return;
      
      final quantity = _selectedProductQuantities[prodName] ?? 1;
      final variantName = _selectedProductVariants[prodName] ?? "";
      
      final dbProd = _availableProducts.firstWhere(
        (p) => p['name'] == prodName,
        orElse: () => null,
      );
      
      double unitPrice = dbProd != null ? (dbProd['price'] as num).toDouble() : 800.0;
      String finalVariant = "";
      
      if (dbProd != null && dbProd['variants'] != null && (dbProd['variants'] as List).isNotEmpty) {
        final variantsList = dbProd['variants'] as List;
        final variantObj = variantsList.firstWhere(
          (v) => v['name'] == variantName,
          orElse: () => variantsList[0],
        );
        if (variantObj != null) {
          unitPrice = (variantObj['price'] as num).toDouble();
          finalVariant = variantObj['name'] ?? "";
        }
      }
      
      list.add({
        'product': prodName,
        if (finalVariant.isNotEmpty) 'variant': finalVariant,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': unitPrice * quantity,
      });
    });
    
    return list;
  }

  Widget _buildStep1SelectProducts() {
    final list = ["Camera", "DVR", "NVR", "Hard Disk", "Cable", "Connector", "Power Supply", "Accessories", "Complete CCTV Kit"];
    return Column(
      key: const ValueKey('step_1_products'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Select CCTV Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Choose multiple products to add to your purchase order', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 16),
        ...list.map((prodName) {
          final isSelected = _selectedProductsCheckboxes[prodName] ?? false;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
            ),
            child: CheckboxListTile(
              value: isSelected,
              title: Text(prodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
              onChanged: (val) {
                _toggleProductSelection(prodName);
              },
              activeColor: AppTheme.primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep2QuantityVariants() {
    final selectedList = _selectedProductsList;
    if (selectedList.isEmpty) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40),
          Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.blueGrey),
          SizedBox(height: 12),
          Text('No products selected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 4),
          Text('Please go back and select at least one product.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          SizedBox(height: 40),
        ],
      );
    }

    return Column(
      key: const ValueKey('step_2_variants'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Choose Quantity & Variants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Specify order volume and technical options for your selected products', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 16),
        ...selectedList.map((item) {
          final prodName = item['product'] as String;
          final qty = item['quantity'] as int;
          final selectedVariant = item['variant'] as String?;
          
          final dbProd = _availableProducts.firstWhere(
            (p) => p['name'] == prodName,
            orElse: () => null,
          );
          final hasVariants = dbProd != null && dbProd['variants'] != null && (dbProd['variants'] as List).isNotEmpty;
          final variantsList = hasVariants ? dbProd['variants'] as List : [];

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(prodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor)),
                      
                      // Quantity selector
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 22, color: AppTheme.primaryColor),
                            onPressed: qty > 1 ? () {
                              setState(() => _selectedProductQuantities[prodName] = qty - 1);
                              _calculateEstimatePrice();
                            } : null,
                          ),
                          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 22, color: AppTheme.primaryColor),
                            onPressed: () {
                              setState(() => _selectedProductQuantities[prodName] = qty + 1);
                              _calculateEstimatePrice();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (hasVariants) ...[
                    const SizedBox(height: 10),
                    const Text('Type / Capacity', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: variantsList.map<Widget>((vObj) {
                        final vName = vObj['name'] as String;
                        final vPrice = (vObj['price'] as num).toDouble();
                        final isSelected = selectedVariant == vName;
                        return ChoiceChip(
                          label: Text('$vName (₹${vPrice.round()})'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedProductVariants[prodName] = vName);
                              _calculateEstimatePrice();
                            }
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.08),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                          ),
                          side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep3DeliveryDate() {
    final formattedDate = _selectedDate != null 
        ? DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!) 
        : 'Select delivery date...';
    return Column(
      key: const ValueKey('step_3_delivery_date'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Select Delivery Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Pick your preferred date for product shipment & delivery.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 16),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          leading: const Icon(Icons.local_shipping_outlined, color: AppTheme.primaryColor),
          title: Text(
            formattedDate,
            style: TextStyle(
              fontSize: 13,
              fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
              color: _selectedDate != null ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? now.add(const Duration(days: 2)),
              firstDate: now.add(const Duration(days: 1)),
              lastDate: now.add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
        ),
        const SizedBox(height: 24),
        const Text('Delivery Instructions / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Enter gate instructions, contact person, or preferred delivery timing notes here...',
          ),
        ),
      ],
    );
  }

  Widget _buildStep5CartReview() {
    final selectedList = _selectedProductsList;
    return Column(
      key: const ValueKey('step_5_cart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Review Cart & Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Review your products order items and delivery cost breakdown', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 16),
        
        ...selectedList.map((item) {
          final prodName = item['product'] as String;
          final variant = item['variant'] as String?;
          final qty = item['quantity'] as int;
          final total = item['total'] as double;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prodName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor),
                      ),
                      if (variant != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          variant,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        'Qty: $qty × ₹${(item['unitPrice'] as double).round()}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${total.round()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor),
                ),
              ],
            ),
          );
        }).toList(),
        
        const Divider(height: 24, color: Color(0xFFE2E8F0)),

        Card(
          color: const Color(0xFFF8FAFC), // Slate 50
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Products Total', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                    Text('₹${_packageCost.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Charge', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                    Text('₹${_visitCharge.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GST (18%)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                    Text('₹${_gst.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFCBD5E1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                    Text(
                      '₹${_grandTotal.round().toLocaleString()}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
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
}

extension NumberFormatting on int {
  String toLocaleString() {
    return NumberFormat('#,##,###', 'en_IN').format(this);
  }
}
