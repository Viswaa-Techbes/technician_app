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
  bool _isLoading = true;
  String? _errorMessage;

  // Configurations loaded from backend
  List<dynamic> _serviceTypes = [];
  List<dynamic> _materials = [];
  Map<String, dynamic> _pricingRules = {};

  // Form selections
  int _currentStep = 1;
  String _selectedServiceType = '';
  final Map<String, int> _selectedMaterials = {}; // ID -> Qty
  
  // Location
  String _mapLink = '';
  double? _latitude;
  double? _longitude;
  String _pincode = '';
  String _fullAddress = '';
  String _city = '';
  String _stateName = '';

  // Schedule
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Notes
  final _notesController = TextEditingController();

  // Price calculation results
  double _baseFee = 0;
  double _materialsCost = 0;
  double _labourCost = 0;
  double _grandTotal = 0;

  @override
  void initState() {
    super.initState();
    _fetchServiceConfig();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('${ApiConfig.serviceConfig}/${widget.serviceSlug}/config');
      
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _serviceTypes = data['serviceTypes'] ?? [];
          _materials = data['materials'] ?? [];
          _pricingRules = data['pricingRules'] ?? {};
          
          // Initialise defaults
          if (_serviceTypes.isNotEmpty) {
            _selectedServiceType = _serviceTypes[0]['name'] ?? '';
          } else {
            _selectedServiceType = widget.serviceName;
          }
          _isLoading = false;
        });
        _calculatePrice();
      } else {
        throw Exception('Failed to load dynamic configurations');
      }
    } catch (e) {
      debugPrint('Error fetching service config: $e');
      // Set fallbacks for CCTV Installation
      setState(() {
        _errorMessage = 'Using offline default configurations.';
        _serviceTypes = [
          {'name': 'Wired Camera Installation', 'price': 499},
          {'name': 'Wireless Camera Installation', 'price': 599},
          {'name': 'Dome Camera Installation', 'price': 549},
          {'name': 'Bullet Camera Installation', 'price': 529},
          {'name': 'PTZ Camera Installation', 'price': 1299},
          {'name': 'DVR Installation', 'price': 799},
          {'name': 'NVR Installation', 'price': 899},
          {'name': 'CCTV Repair', 'price': 399},
          {'name': 'CCTV Maintenance', 'price': 299},
        ];
        _materials = [
          {'id': 'cable_3p1', 'name': '3+1 Cable', 'unit': 'meter', 'price': 18, 'isLabour': false},
          {'id': 'cat6', 'name': 'CAT6 Cable', 'unit': 'meter', 'price': 40, 'isLabour': false},
          {'id': 'labour', 'name': 'Installation Labour', 'unit': 'meter', 'price': 15, 'isLabour': true},
          {'id': 'box_5x5', 'name': 'Camera Box 5x5', 'unit': 'each', 'price': 60, 'isLabour': false},
          {'id': 'junction_box', 'name': 'Junction Box', 'unit': 'each', 'price': 220, 'isLabour': false},
          {'id': 'power_supply', 'name': 'Power Supply', 'unit': 'each', 'price': 450, 'isLabour': false},
          {'id': 'smps', 'name': 'SMPS', 'unit': 'each', 'price': 650, 'isLabour': false},
          {'id': 'hard_disk', 'name': 'Hard Disk', 'unit': 'each', 'price': 3800, 'isLabour': false},
        ];
        _selectedServiceType = _serviceTypes[0]['name'];
        _isLoading = false;
      });
      _calculatePrice();
    }
  }

  void _calculatePrice() {
    double base = widget.defaultPrice;
    if (_serviceTypes.isNotEmpty) {
      final type = _serviceTypes.firstWhere(
        (t) => t['name'] == _selectedServiceType,
        orElse: () => null,
      );
      if (type != null) {
        base = (type['price'] as num).toDouble();
      }
    }

    double matCost = 0;
    double labCost = 0;

    _selectedMaterials.forEach((id, qty) {
      final mat = _materials.firstWhere(
        (m) => m['id'] == id || m['slug'] == id,
        orElse: () => null,
      );
      if (mat != null) {
        final price = (mat['price'] as num).toDouble();
        final total = price * qty;
        final isLabour = mat['isLabour'] == true || id == 'labour';
        if (isLabour) {
          labCost += total;
        } else {
          matCost += total;
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

  void _toggleMaterial(String id) {
    setState(() {
      if (_selectedMaterials.containsKey(id)) {
        _selectedMaterials.remove(id);
      } else {
        _selectedMaterials[id] = 1;
      }
    });
    _calculatePrice();
  }

  void _setMaterialQty(String id, int qty) {
    if (qty <= 0) {
      setState(() {
        _selectedMaterials.remove(id);
      });
    } else {
      setState(() {
        _selectedMaterials[id] = qty;
      });
    }
    _calculatePrice();
  }

  List<String> _getSteps() {
    return [
      'Type',
      'Materials',
      'Location',
      'Schedule',
      'Notes',
    ];
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 1:
        return _selectedServiceType.isNotEmpty;
      case 2:
        return true; // Materials are optional
      case 3:
        return _latitude != null && _longitude != null && _fullAddress.isNotEmpty;
      case 4:
        return _selectedDate != null && _selectedTime != null;
      case 5:
        return true; // Notes are optional
      default:
        return false;
    }
  }

  Map<String, dynamic> _buildConfigurationPayload() {
    final List<Map<String, dynamic>> materialsList = [];
    _selectedMaterials.forEach((id, qty) {
      final mat = _materials.firstWhere(
        (m) => m['id'] == id || m['slug'] == id,
        orElse: () => null,
      );
      if (mat != null) {
        final price = (mat['price'] as num).toDouble();
        materialsList.add({
          'id': id,
          'name': mat['name'] ?? id,
          'unit': mat['unit'] ?? 'each',
          'qty': qty,
          'unitPrice': price,
          'total': price * qty,
        });
      }
    });

    final String dateString = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '';
    final String timeString = _selectedTime != null ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' : '';

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
      'date': dateString,
      'time': timeString,
      'notes': _notesController.text.trim(),
      'isMaterialsRequired': _materials.isNotEmpty,
      'priceBreakdown': {
        'baseCharge': _baseFee,
        'materialsTotal': _materialsCost,
        'labourTotal': _labourCost,
        'grandTotal': _grandTotal,
      }
    };
  }

  void _dispatchAddToCart() {
    if (!_isStepValid() || _latitude == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the current configuration step')),
      );
      return;
    }

    final config = _buildConfigurationPayload();
    
    // Add to cart notifier
    final uniqueId = '${widget.serviceSlug}-${DateTime.now().millisecondsSinceEpoch}';
    final item = CartItem(
      id: uniqueId,
      serviceId: int.tryParse(widget.subcategoryId) ?? 1000,
      slug: widget.serviceSlug,
      title: widget.serviceName,
      priceValue: _grandTotal,
      qty: 1,
      config: config,
    );

    ref.read(cartProvider.notifier).addItem(item);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${widget.serviceName} to your cart!'),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            context.pop();
            context.push('/cart');
          },
        ),
      ),
    );
    context.pop();
  }

  void _dispatchBookNow() {
    if (!_isStepValid() || _latitude == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all scheduling and location steps before checking out')),
      );
      return;
    }

    final config = _buildConfigurationPayload();
    final uniqueId = '${widget.serviceSlug}-${DateTime.now().millisecondsSinceEpoch}';
    final item = CartItem(
      id: uniqueId,
      serviceId: int.tryParse(widget.subcategoryId) ?? 1000,
      slug: widget.serviceSlug,
      title: widget.serviceName,
      priceValue: _grandTotal,
      qty: 1,
      config: config,
    );

    // Clear cart and add this single item to check out directly
    ref.read(cartProvider.notifier).clearCart();
    ref.read(cartProvider.notifier).addItem(item);

    context.pop();
    context.push('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _getSteps();

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configure ${widget.serviceName}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Stepper Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.slate.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(steps.length, (index) {
                  final stepNum = index + 1;
                  final isActive = stepNum == _currentStep;
                  final isDone = stepNum < _currentStep;

                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (stepNum < _currentStep) {
                            setState(() => _currentStep = stepNum);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primaryColor
                                : (isDone ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.primaryColor
                                  : (isDone ? Colors.transparent : Colors.slate.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: isActive ? Colors.white : (isDone ? AppTheme.primaryColor : Colors.slate.shade400),
                                child: isDone
                                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                                    : Text(
                                        '$stepNum',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? AppTheme.primaryColor : Colors.white,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                steps[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : (isDone ? AppTheme.primaryColor : AppTheme.textSecondaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Container(
                          width: 20,
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: isDone ? AppTheme.primaryColor : Colors.slate.shade300,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step Contents
                  if (_currentStep == 1) _buildStep1Type(),
                  if (_currentStep == 2) _buildStep2Materials(),
                  if (_currentStep == 3) _buildStep3Location(),
                  if (_currentStep == 4) _buildStep4Schedule(),
                  if (_currentStep == 5) _buildStep5Notes(),
                  
                  const SizedBox(height: 24),
                  _buildPriceBreakdownCard(),
                ],
              ),
            ),
          ),

          // Bottom CTA Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back'),
                    ),
                  ),
                Expanded(
                  child: _currentStep < steps.length
                      ? ElevatedButton(
                          onPressed: _isStepValid()
                              ? () => setState(() => _currentStep++)
                              : null,
                          child: const Text('Next Step'),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isStepValid() ? _dispatchAddToCart : null,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 18),
                                    SizedBox(width: 6),
                                    Text('Add to Cart', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isStepValid() ? _dispatchBookNow : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_month, size: 18),
                                    SizedBox(width: 6),
                                    Text('Book Now', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Type() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Service/Camera Type',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._serviceTypes.map((type) {
          final isSelected = _selectedServiceType == type['name'];
          final price = (type['price'] as num).toDouble();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: RadioListTile<String>(
              value: type['name'] ?? '',
              groupValue: _selectedServiceType,
              title: Text(
                type['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: type['description'] != null
                  ? Text(
                      type['description'],
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    )
                  : null,
              secondary: Text(
                '₹${price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.extrabold,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                  fontSize: 15,
                ),
              ),
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedServiceType = val);
                  _calculatePrice();
                }
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep2Materials() {
    final theme = Theme.of(context);
    if (_materials.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No extra materials config needed for this service.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Accessories & Materials (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Check materials needed for installation. Cable and labour quantities are calculated per meter.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        ..._materials.map((mat) {
          final id = mat['id'] ?? mat['slug'];
          final isSelected = _selectedMaterials.containsKey(id);
          final price = (mat['price'] as num).toDouble();
          final unit = mat['unit'] ?? 'each';
          final hasQty = unit != 'none' && unit != 'checkbox';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (_) => _toggleMaterial(id),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mat['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      Text(
                        '₹${price.toStringAsFixed(0)} per $unit',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                if (isSelected && hasQty)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 22, color: AppTheme.textSecondaryColor),
                        onPressed: () {
                          final currentQty = _selectedMaterials[id] ?? 1;
                          _setMaterialQty(id, currentQty - 1);
                        },
                      ),
                      Text(
                        '${_selectedMaterials[id] ?? 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 22, color: AppTheme.primaryColor),
                        onPressed: () {
                          final currentQty = _selectedMaterials[id] ?? 1;
                          _setMaterialQty(id, currentQty + 1);
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3Location() {
    final theme = Theme.of(context);
    final hasLocation = _latitude != null && _longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Location',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (hasLocation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
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
                        'Location Confirmed',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fullAddress,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF047857), height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Change Location Pin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _openMapPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.map_outlined, size: 40, color: AppTheme.textSecondaryColor),
                  SizedBox(height: 12),
                  Text(
                    'Tap to Pick Location on Map',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Required to verify service availability in your area',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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

  Widget _buildStep4Schedule() {
    final theme = Theme.of(context);
    final formattedDate = _selectedDate != null 
        ? DateFormat('EEEE, d MMM yyyy').format(_selectedDate!) 
        : 'Select Date';
    final formattedTime = _selectedTime != null 
        ? _selectedTime!.format(context) 
        : 'Select Slot Time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Schedule',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Date selection button
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          tileColor: Colors.white,
          leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          title: const Text('Service Date', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          subtitle: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),

        // Time slot selection button
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          tileColor: Colors.white,
          leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
          title: const Text('Arrival Time Slot', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          subtitle: Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _pickTime,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Widget _buildStep5Notes() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Directives & Notes',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter specific requirements, device model details, issue descriptions, parking directives, or safety instructions...',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Optional. These notes will be attached to your service worksheet for the assigned technician.',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdownCard() {
    return Card(
      elevation: 0,
      color: Colors.slate.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.slate.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: AppTheme.textPrimaryColor, size: 18),
                SizedBox(width: 8),
                Text(
                  'Live Price Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPriceLine('Base Fee', _baseFee),
            if (_materialsCost > 0) _buildPriceLine('Materials / Add-ons', _materialsCost),
            if (_labourCost > 0) _buildPriceLine('Labour Charges', _labourCost),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text(
                  'Est. Total',
                  style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16, color: AppTheme.textPrimaryColor),
                ),
                Text(
                  '₹${_grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 18, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '18% GST will be computed and added in the checkout summary.',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
          Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }
}
