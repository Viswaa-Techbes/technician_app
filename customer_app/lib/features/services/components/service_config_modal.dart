import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../cart/providers/cart_provider.dart';
import '../../checkout/components/map_location_picker.dart';

class ServiceConfigModal extends ConsumerStatefulWidget {
  final String serviceSlug;
  final String serviceName;
  final String categoryId;
  final String subcategoryId;
  final double defaultPrice;

  const ServiceConfigModal({
    super.key,
    required this.serviceSlug,
    required this.serviceName,
    required this.categoryId,
    required this.subcategoryId,
    required this.defaultPrice,
  });

  @override
  ConsumerState<ServiceConfigModal> createState() => _ServiceConfigModalState();
}

class _MainCCTVConfig {
  String propertyType = 'Home';
  Map<String, bool> selectedCameraTypes = {}; // type -> true
  Map<String, int> cameraQuantities = {}; // type -> qty
  Map<String, String> cameraBrands = {}; // type -> brandId
  Map<String, String> cameraModels = {}; // type -> modelId
  
  bool installationRequired = true;
  String cableType = 'Cat6';
  int cableLength = 20;
  bool dvrRequired = false;
  bool nvrRequired = false;
  bool networkRack = false;
  bool monitorMounting = false;
  bool sdCardEnabled = false;
  String sdCardCapacity = '64GB';
  int sdCardQuantity = 1;
}

class _ServiceConfigModalState extends ConsumerState<ServiceConfigModal> {
  bool _isLoading = true;
  String? _errorMessage;
  int _currentStep = 1;

  // General service configs
  List<dynamic> _serviceTypes = [];
  List<dynamic> _materials = [];
  Map<String, dynamic> _pricingRules = {};

  // CCTV-specific selections & metadata tables
  final _cctv = _MainCCTVConfig();
  List<dynamic> _cctvBrands = [];
  List<dynamic> _cctvModels = [];
  List<dynamic> _cctvSdCards = [];
  List<dynamic> _cctvCables = [];
  List<dynamic> _cctvInstallationCharges = [];
  List<dynamic> _cctvAccessories = [];

  // General selections
  String _selectedServiceType = '';
  final Map<String, int> _selectedMaterials = {}; // ID -> Qty

  // Address
  String _mapLink = '';
  double? _latitude;
  double? _longitude;
  String _pincode = '';
  String _fullAddress = '';
  String _city = '';
  String _stateName = '';

  // Schedule & Directives
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();

  // Price calculations
  double _baseFee = 0;
  double _materialsCost = 0;
  double _labourCost = 0;
  double _grandTotal = 0;
  bool _calculatingCctvPrice = false;

  bool get _isCctv => widget.serviceSlug == 'install-new-cctv';

  @override
  void initState() {
    super.initState();
    _fetchServiceConfigs();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceConfigs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      
      if (_isCctv) {
        // CCTV Metadata Concurrent Fetch
        final results = await Future.wait([
          client.get('/api/v2/cctv/brands'),
          client.get('/api/v2/cctv/models'),
          client.get('/api/v2/cctv/sd-cards'),
          client.get('/api/v2/cctv/cable-pricings'),
          client.get('/api/v2/cctv/installation-charges'),
          client.get('/api/v2/cctv/accessories'),
        ]);

        setState(() {
          _cctvBrands = results[0].data['data'] ?? [];
          _cctvModels = results[1].data['data'] ?? [];
          _cctvSdCards = results[2].data['data'] ?? [];
          _cctvCables = results[3].data['data'] ?? [];
          _cctvInstallationCharges = results[4].data['data'] ?? [];
          _cctvAccessories = results[5].data['data'] ?? [];
          
          // Initialise default camera setups
          _cctv.selectedCameraTypes = {'IP Camera': true};
          _cctv.cameraQuantities = {'IP Camera': 2};
          if (_cctvBrands.isNotEmpty) {
            _cctv.cameraBrands = {'IP Camera': _cctvBrands[0]['_id']};
            final firstModel = _cctvModels.firstWhere(
              (m) => m['cameraType'] == 'IP Camera' && m['brandId']?['_id'] == _cctvBrands[0]['_id'],
              orElse: () => null,
            );
            if (firstModel != null) {
              _cctv.cameraModels = {'IP Camera': firstModel['_id']};
            }
          }
          
          _isLoading = false;
        });
        _calculateCctvPrice();
      } else {
        // General category configurations
        final response = await client.get('${ApiConfig.serviceConfig}/${widget.serviceSlug}/config');
        if (response.data != null && response.data['success'] == true) {
          final data = response.data['data'];
          setState(() {
            _serviceTypes = data['serviceTypes'] ?? [];
            _materials = data['materials'] ?? [];
            _pricingRules = data['pricingRules'] ?? {};
            if (_serviceTypes.isNotEmpty) {
              _selectedServiceType = _serviceTypes[0]['name'] ?? '';
            } else {
              _selectedServiceType = widget.serviceName;
            }
            _isLoading = false;
          });
          _calculateGeneralPrice();
        } else {
          throw Exception();
        }
      }
    } catch (e) {
      debugPrint('Error loading configs: $e');
      setState(() {
        _isLoading = false;
        if (_isCctv) {
          // Hardcoded CCTV parameters fallback for local dev offline
          _cctvBrands = [
            {'_id': 'b1', 'name': 'Hikvision'},
            {'_id': 'b2', 'name': 'CP Plus'},
            {'_id': 'b3', 'name': 'Dahua'}
          ];
          _cctvModels = [
            {'_id': 'm1', 'name': '2MP Fixed Dome IP', 'cameraType': 'IP Camera', 'brandId': {'_id': 'b1'}, 'price': 1200},
            {'_id': 'm2', 'name': '4MP Smart IP Bullet', 'cameraType': 'IP Camera', 'brandId': {'_id': 'b1'}, 'price': 2200},
          ];
          _cctvSdCards = [
            {'_id': 'sd1', 'capacity': '64GB', 'price': 450},
            {'_id': 'sd2', 'capacity': '128GB', 'price': 850}
          ];
          _cctv.selectedCameraTypes = {'IP Camera': true};
          _cctv.cameraQuantities = {'IP Camera': 2};
          _cctv.cameraBrands = {'IP Camera': 'b1'};
          _cctv.cameraModels = {'IP Camera': 'm1'};
        } else {
          _serviceTypes = [
            {'name': 'Wired Service Repair', 'price': 499},
            {'name': 'Device Diagnostic Visit', 'price': 299}
          ];
          _selectedServiceType = _serviceTypes[0]['name'];
        }
      });
      if (_isCctv) _calculateCctvPrice(); else _calculateGeneralPrice();
    }
  }

  // Dynamic CCTV Pricing Call
  Future<void> _calculateCctvPrice() async {
    final hasCamera = _cctv.selectedCameraTypes.values.any((v) => v == true);
    if (!hasCamera) return;

    setState(() => _calculatingCctvPrice = true);

    final List<Map<String, dynamic>> cameraTypesPayload = [];
    _cctv.selectedCameraTypes.forEach((type, selected) {
      if (selected) {
        cameraTypesPayload.add({
          'type': type,
          'brandId': _cctv.cameraBrands[type] ?? '',
          'modelId': _cctv.cameraModels[type] ?? '',
          'quantity': _cctv.cameraQuantities[type] ?? 1,
        });
      }
    });

    final payload = {
      'subcategoryId': widget.subcategoryId,
      'subcategorySlug': widget.serviceSlug,
      'propertyType': _cctv.propertyType,
      'cameraTypes': cameraTypesPayload,
      'installationRequired': _cctv.installationRequired,
      'cableType': _cctv.cableType,
      'cableLength': _cctv.cableLength,
      'dvrRequired': _cctv.dvrRequired,
      'nvrRequired': _cctv.nvrRequired,
      'networkRack': _cctv.networkRack,
      'monitorMounting': _cctv.monitorMounting,
      'sdCardRequired': _cctv.sdCardEnabled,
      'sdCardCapacity': _cctv.sdCardCapacity,
      'sdCardQuantity': _cctv.sdCardQuantity,
    };

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.post('/api/v2/cctv/calculate-price', data: payload);
      
      if (response.data != null && response.data['success'] == true) {
        final breakdown = response.data['data']['priceBreakdown'];
        setState(() {
          _baseFee = (breakdown['baseCharge'] as num).toDouble();
          _materialsCost = (breakdown['cameraTotal'] as num).toDouble();
          _labourCost = (breakdown['addonsTotal'] as num).toDouble();
          _grandTotal = (breakdown['grandTotal'] as num).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Price calculation failed: $e');
      // Offline fallback simple pricing logic
      double camSum = 0;
      _cctv.selectedCameraTypes.forEach((type, sel) {
        if (sel) {
          final mod = _cctvModels.firstWhere((m) => m['_id'] == _cctv.cameraModels[type], orElse: () => null);
          final price = (mod?['price'] as num?)?.toDouble() ?? 1200.0;
          camSum += price * (_cctv.cameraQuantities[type] ?? 1);
        }
      });
      double addonsSum = _cctv.cableLength * (_cctv.cableType == 'Cat6' ? 45.0 : 35.0);
      if (_cctv.sdCardEnabled) addonsSum += _cctv.sdCardQuantity * 450.0;
      
      setState(() {
        _baseFee = widget.defaultPrice;
        _materialsCost = camSum;
        _labourCost = addonsSum;
        _grandTotal = _baseFee + _materialsCost + _labourCost;
      });
    } finally {
      setState(() => _calculatingCctvPrice = false);
    }
  }

  void _calculateGeneralPrice() {
    double base = widget.defaultPrice;
    if (_serviceTypes.isNotEmpty) {
      final type = _serviceTypes.firstWhere((t) => t['name'] == _selectedServiceType, orElse: () => null);
      if (type != null) {
        base = (type['price'] as num).toDouble();
      }
    }

    double matCost = 0;
    double labCost = 0;
    _selectedMaterials.forEach((id, qty) {
      final mat = _materials.firstWhere((m) => m['id'] == id || m['slug'] == id, orElse: () => null);
      if (mat != null) {
        final price = (mat['price'] as num).toDouble();
        if (mat['isLabour'] == true || id == 'labour') {
          labCost += price * qty;
        } else {
          matCost += price * qty;
        }
      }
    });

    setState(() {
      _baseFee = _pricingRules['baseCharge'] != null 
          ? (_pricingRules['baseCharge'] as num).toDouble() 
          : base;
      _materialsCost = matCost;
      _labourCost = labCost;
      _grandTotal = _baseFee + _materialsCost + _labourCost;
    });
  }

  List<String> _getSteps() {
    if (_isCctv) {
      return ['Setup Details', 'Add-ons & Parts', 'Location', 'Schedule', 'Summary'];
    }
    return ['Type Selection', 'Materials', 'Location', 'Schedule', 'Summary'];
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 1:
        if (_isCctv) {
          return _cctv.selectedCameraTypes.values.any((v) => v == true);
        }
        return _selectedServiceType.isNotEmpty;
      case 2:
        return true;
      case 3:
        return _latitude != null && _longitude != null && _fullAddress.isNotEmpty;
      case 4:
        return _selectedDate != null && _selectedTime != null;
      case 5:
        return true;
      default:
        return false;
    }
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
                    _fullAddress = data.address;
                    _city = data.city;
                    _stateName = data.state;
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
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Map<String, dynamic> _buildConfigurationPayload() {
    final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '';
    final timeStr = _selectedTime != null 
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' 
        : '';

    if (_isCctv) {
      final List<Map<String, dynamic>> materialsList = [];
      _cctv.selectedCameraTypes.forEach((type, sel) {
        if (sel) {
          final mod = _cctvModels.firstWhere((m) => m['_id'] == _cctv.cameraModels[type], orElse: () => null);
          materialsList.add({
            'id': _cctv.cameraModels[type] ?? '',
            'name': '$type (${mod?['name'] ?? 'Generic'})',
            'unit': 'each',
            'qty': _cctv.cameraQuantities[type] ?? 1,
            'total': ((mod?['price'] ?? 1200) * (_cctv.cameraQuantities[type] ?? 1)).toDouble(),
          });
        }
      });
      
      // Add cable
      materialsList.add({
        'id': 'cable',
        'name': '${_cctv.cableType} Cable',
        'unit': 'meter',
        'qty': _cctv.cableLength,
        'total': (_cctv.cableLength * (_cctv.cableType == 'Cat6' ? 45.0 : 35.0)),
      });

      return {
        'serviceType': 'CCTV Setup Rollout',
        'materials': materialsList,
        'mapLink': _mapLink,
        'latitude': _latitude,
        'longitude': _longitude,
        'pincode': _pincode,
        'fullAddress': _fullAddress,
        'city': _city,
        'state': _stateName,
        'date': dateStr,
        'time': timeStr,
        'notes': _notesController.text.trim(),
        'priceBreakdown': {
          'baseCharge': _baseFee,
          'materialsTotal': _materialsCost,
          'labourTotal': _labourCost,
          'grandTotal': _grandTotal,
        }
      };
    } else {
      // General service payload
      final List<Map<String, dynamic>> materialsList = [];
      _selectedMaterials.forEach((id, qty) {
        final mat = _materials.firstWhere((m) => m['id'] == id || m['slug'] == id, orElse: () => null);
        if (mat != null) {
          final price = (mat['price'] as num).toDouble();
          materialsList.add({
            'id': id,
            'name': mat['name'] ?? id,
            'unit': mat['unit'] ?? 'each',
            'qty': qty,
            'total': price * qty,
          });
        }
      });

      return {
        'serviceType': _selectedServiceType,
        'materials': materialsList,
        'mapLink': _mapLink,
        'latitude': _latitude,
        'longitude': _longitude,
        'pincode': _pincode,
        'fullAddress': _fullAddress,
        'city': _city,
        'state': _stateName,
        'date': dateStr,
        'time': timeStr,
        'notes': _notesController.text.trim(),
        'priceBreakdown': {
          'baseCharge': _baseFee,
          'materialsTotal': _materialsCost,
          'labourTotal': _labourCost,
          'grandTotal': _grandTotal,
        }
      };
    }
  }

  void _dispatchBookNow() {
    final payload = _buildConfigurationPayload();
    final item = CartItem(
      id: '${widget.serviceSlug}-${DateTime.now().millisecondsSinceEpoch}',
      serviceId: int.tryParse(widget.subcategoryId) ?? 1000,
      slug: widget.serviceSlug,
      title: widget.serviceName,
      priceValue: _grandTotal,
      qty: 1,
      config: payload,
    );

    // Clear cart and push
    ref.read(cartProvider.notifier).clearCart();
    ref.read(cartProvider.notifier).addItem(item);

    context.pop();
    context.push('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    final steps = _getSteps();
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Title header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Configure ${widget.serviceName}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => context.pop()),
              ],
            ),
          ),
          const Divider(height: 1),

          // Stepper bar
          Container(
            color: Colors.blueGrey.shade50,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(steps.length, (idx) {
                  final sNum = idx + 1;
                  final active = sNum == _currentStep;
                  final done = sNum < _currentStep;
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primaryColor : (done ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: active ? AppTheme.primaryColor : Colors.blueGrey.shade200),
                        ),
                        child: Text(
                          steps[idx],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: active ? Colors.white : (done ? AppTheme.primaryColor : AppTheme.textSecondaryColor),
                          ),
                        ),
                      ),
                      if (idx < steps.length - 1)
                        Container(width: 15, height: 1, color: done ? AppTheme.primaryColor : Colors.blueGrey.shade200, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    ],
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),

          // Content body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentStep == 1) (_isCctv ? _buildCctvStep1() : _buildGeneralStep1()),
                  if (_currentStep == 2) (_isCctv ? _buildCctvStep2() : _buildGeneralStep2()),
                  if (_currentStep == 3) _buildLocationStep(),
                  if (_currentStep == 4) _buildScheduleStep(),
                  if (_currentStep == 5) _buildSummaryStep(),
                ],
              ),
            ),
          ),

          // Footer actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_currentStep > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back'),
                    ),
                  ),
                Expanded(
                  child: _currentStep < steps.length
                      ? ElevatedButton(
                          onPressed: _isStepValid() ? () => setState(() => _currentStep++) : null,
                          child: const Text('Next Step'),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isStepValid() ? _dispatchBookNow : null,
                          icon: const Icon(Icons.flash_on, size: 18),
                          label: const Text('Book Schedule & Checkout'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // General Setup Step Content
  Widget _buildGeneralStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Service Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ..._serviceTypes.map((type) {
          final active = _selectedServiceType == type['name'];
          final price = (type['price'] as num).toDouble();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: active ? AppTheme.primaryColor : AppTheme.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RadioListTile<String>(
              value: type['name'],
              groupValue: _selectedServiceType,
              activeColor: AppTheme.primaryColor,
              title: Text(type['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              secondary: Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedServiceType = val);
                  _calculateGeneralPrice();
                }
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGeneralStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Accessories Required (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        if (_materials.isEmpty)
          const Text('No dynamic materials configured.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor))
        else
          ..._materials.map((mat) {
            final id = mat['id'] ?? mat['slug'];
            final isSel = _selectedMaterials.containsKey(id);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(border: Border.all(color: isSel ? AppTheme.primaryColor : AppTheme.borderColor), borderRadius: BorderRadius.circular(12)),
              child: CheckboxListTile(
                value: isSel,
                activeColor: AppTheme.primaryColor,
                title: Text(mat['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text('₹${mat['price']} per unit'),
                onChanged: (_) {
                  setState(() {
                    if (isSel) {
                      _selectedMaterials.remove(id);
                    } else {
                      _selectedMaterials[id] = 1;
                    }
                  });
                  _calculateGeneralPrice();
                },
              ),
            );
          }),
      ],
    );
  }

  // CCTV Setup Step Content
  Widget _buildCctvStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Property Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _cctv.propertyType,
          decoration: const InputDecoration(labelText: 'Property Type'),
          items: ['Home', 'Office', 'Shop', 'Apartment', 'Warehouse', 'Factory', 'Other']
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _cctv.propertyType = val);
              _calculateCctvPrice();
            }
          },
        ),
        const SizedBox(height: 16),
        const Text('Camera Types Selection (Multiple Allowed)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...['IP Camera', 'Analog Camera', 'WiFi Indoor Camera', 'WiFi Outdoor Camera', '4G Camera', 'Solar Camera'].map((type) {
          final sel = _cctv.selectedCameraTypes[type] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: sel ? AppTheme.primaryColor : AppTheme.borderColor),
              borderRadius: BorderRadius.circular(12),
              color: sel ? AppTheme.primaryColor.withOpacity(0.02) : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: sel,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setState(() {
                          _cctv.selectedCameraTypes[type] = val ?? false;
                          if (val == true && !_cctv.cameraQuantities.containsKey(type)) {
                            _cctv.cameraQuantities[type] = 1;
                            if (_cctvBrands.isNotEmpty) {
                              _cctv.cameraBrands[type] = _cctvBrands[0]['_id'];
                              final mods = _cctvModels.where((m) => m['cameraType'] == type && m['brandId']?['_id'] == _cctvBrands[0]['_id']).toList();
                              if (mods.isNotEmpty) _cctv.cameraModels[type] = mods[0]['_id'];
                            }
                          }
                        });
                        _calculateCctvPrice();
                      },
                    ),
                    Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ],
                ),
                if (sel) ...[
                  const Divider(height: 12),
                  Row(
                    children: [
                      // Brand
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _cctv.cameraBrands[type],
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), labelText: 'Brand'),
                          items: _cctvBrands.map((b) => DropdownMenuItem<String>(value: b['_id'], child: Text(b['name']))).toList(),
                          onChanged: (brandVal) {
                            if (brandVal != null) {
                              setState(() {
                                _cctv.cameraBrands[type] = brandVal;
                                final mods = _cctvModels.where((m) => m['cameraType'] == type && m['brandId']?['_id'] == brandVal).toList();
                                if (mods.isNotEmpty) {
                                  _cctv.cameraModels[type] = mods[0]['_id'];
                                } else {
                                  _cctv.cameraModels.remove(type);
                                }
                              });
                              _calculateCctvPrice();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Model
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _cctv.cameraModels[type],
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), labelText: 'Model'),
                          items: _cctvModels
                              .where((m) => m['cameraType'] == type && m['brandId']?['_id'] == _cctv.cameraBrands[type])
                              .map((m) => DropdownMenuItem<String>(value: m['_id'], child: Text(m['name'])))
                              .toList(),
                          onChanged: (modVal) {
                            if (modVal != null) {
                              setState(() => _cctv.cameraModels[type] = modVal);
                              _calculateCctvPrice();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () {
                              final q = _cctv.cameraQuantities[type] ?? 1;
                              if (q > 1) {
                                setState(() => _cctv.cameraQuantities[type] = q - 1);
                                _calculateCctvPrice();
                              }
                            },
                          ),
                          Text('${_cctv.cameraQuantities[type] ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryColor),
                            onPressed: () {
                              final q = _cctv.cameraQuantities[type] ?? 1;
                              setState(() => _cctv.cameraQuantities[type] = q + 1);
                              _calculateCctvPrice();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCctvStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cabling Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _cctv.cableType,
          decoration: const InputDecoration(labelText: 'Cable Type'),
          items: ['Cat6', '3+1 Cable', 'Cat6 Premium'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _cctv.cableType = val);
              _calculateCctvPrice();
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cable Length: ${_cctv.cableLength} meters'),
          ],
        ),
        Slider(
          value: _cctv.cableLength.toDouble(),
          min: 10,
          max: 180,
          divisions: 17,
          activeColor: AppTheme.primaryColor,
          onChanged: (val) {
            setState(() => _cctv.cableLength = val.round());
          },
          onChangeEnd: (_) => _calculateCctvPrice(),
        ),
        const SizedBox(height: 16),
        const Text('Recorders & Add-ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _cctv.dvrRequired,
          activeColor: AppTheme.primaryColor,
          title: const Text('DVR Required (Analog Setup)', style: TextStyle(fontSize: 13)),
          onChanged: (val) {
            setState(() {
              _cctv.dvrRequired = val ?? false;
              if (val == true) _cctv.nvrRequired = false;
            });
            _calculateCctvPrice();
          },
        ),
        CheckboxListTile(
          value: _cctv.nvrRequired,
          activeColor: AppTheme.primaryColor,
          title: const Text('NVR Required (IP Setup)', style: TextStyle(fontSize: 13)),
          onChanged: (val) {
            setState(() {
              _cctv.nvrRequired = val ?? false;
              if (val == true) _cctv.dvrRequired = false;
            });
            _calculateCctvPrice();
          },
        ),
        CheckboxListTile(
          value: _cctv.sdCardEnabled,
          activeColor: AppTheme.primaryColor,
          title: const Text('SD Card Required (WiFi Cameras)', style: TextStyle(fontSize: 13)),
          onChanged: (val) {
            setState(() => _cctv.sdCardEnabled = val ?? false);
            _calculateCctvPrice();
          },
        ),
        if (_cctv.sdCardEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: _cctv.sdCardCapacity,
              decoration: const InputDecoration(labelText: 'SD Card Capacity'),
              items: ['32GB', '64GB', '128GB', '256GB'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _cctv.sdCardCapacity = val);
                  _calculateCctvPrice();
                }
              },
            ),
          ),
        ],
        CheckboxListTile(
          value: _cctv.networkRack,
          activeColor: AppTheme.primaryColor,
          title: const Text('Include Network Rack casing', style: TextStyle(fontSize: 13)),
          onChanged: (val) {
            setState(() => _cctv.networkRack = val ?? false);
            _calculateCctvPrice();
          },
        ),
        CheckboxListTile(
          value: _cctv.monitorMounting,
          activeColor: AppTheme.primaryColor,
          title: const Text('Monitor wall mounting bracket', style: TextStyle(fontSize: 13)),
          onChanged: (val) {
            setState(() => _cctv.monitorMounting = val ?? false);
            _calculateCctvPrice();
          },
        ),
      ],
    );
  }

  // Location Step
  Widget _buildLocationStep() {
    final hasLoc = _latitude != null && _longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        if (hasLoc)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text('Location Confirmed', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_fullAddress, style: const TextStyle(fontSize: 12.5, color: Color(0xFF047857), height: 1.4)),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _openMapPicker,
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor, padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('Change Location Pin', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.borderColor)),
            child: InkWell(
              onTap: _openMapPicker,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.map_outlined, size: 36, color: AppTheme.textSecondaryColor),
                      SizedBox(height: 10),
                      Text('Pin Location on Map', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('We use pin location to verify technicians coverage.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Schedule Step
  Widget _buildScheduleStep() {
    final fDate = _selectedDate != null ? DateFormat('EEEE, d MMM yyyy').format(_selectedDate!) : 'Select Date';
    final fTime = _selectedTime != null ? _selectedTime!.format(context) : 'Select Arrival Slot';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule Arrival Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.borderColor)),
          leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          title: const Text('Preferred Date', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          subtitle: Text(fDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.borderColor)),
          leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
          title: const Text('Time Slot', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          subtitle: Text(fTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _pickTime,
        ),
        const SizedBox(height: 16),
        const Text('Special Directives', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter specific requirements, safety instructions or device details...'),
        ),
      ],
    );
  }

  // Summary Step
  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Configuration Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        
        // Dynamic estimate summary card
        Card(
          color: Colors.blueGrey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blueGrey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, size: 18),
                    SizedBox(width: 8),
                    Text('Live Pricing Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceRow('Base Service Fee', _baseFee),
                _buildPriceRow('Equipments / Add-ons', _materialsCost),
                _buildPriceRow('Labour / Cable routing', _labourCost),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    _calculatingCctvPrice
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                        : Text('₹${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Taxes computed on checkout sheet.', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Site layout instructions and address verification details are linked and will be processed immediately upon booking.', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor, height: 1.4)),
      ],
    );
  }

  Widget _buildPriceRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor)),
          Text('₹${val.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }
}
