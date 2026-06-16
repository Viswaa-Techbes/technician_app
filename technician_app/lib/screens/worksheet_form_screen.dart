import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../services/api_service.dart';

class WorksheetFormScreen extends ConsumerStatefulWidget {
  final Job job;

  const WorksheetFormScreen({super.key, required this.job});

  @override
  ConsumerState<WorksheetFormScreen> createState() => _WorksheetFormScreenState();
}

class _WorksheetFormScreenState extends ConsumerState<WorksheetFormScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSavingDraft = false;

  // Form Controllers
  final _workDescController = TextEditingController();
  final _observationsController = TextEditingController();
  final _commentsController = TextEditingController();
  final _labourCostController = TextEditingController(text: '0');
  final _otpController = TextEditingController();

  // Materials & Parts
  final List<Map<String, dynamic>> _materialsUsed = [];
  final List<String> _partsInstalled = [];

  // Photos List (Cloudinary URLs)
  final List<String> _beforePhotos = [];
  final List<String> _duringPhotos = [];
  final List<String> _afterPhotos = [];

  // Signatures
  String _customerSignatureUrl = '';
  String _technicianSignatureUrl = '';

  // Signature Pad State
  final List<Offset?> _sigPoints = [];
  final GlobalKey _sigKey = GlobalKey();
  bool _isSignatureCaptured = false;

  // OTP Verification State
  bool _completionOtpVerified = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _loadExistingWorksheet();
  }

  @override
  void dispose() {
    _workDescController.dispose();
    _observationsController.dispose();
    _commentsController.dispose();
    _labourCostController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingWorksheet() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getWorksheet(widget.job.id);
      
      if (data.isNotEmpty) {
        setState(() {
          _workDescController.text = data['requestedWorkDescription'] ?? '';
          _observationsController.text = data['technicianObservations'] ?? '';
          _commentsController.text = data['additionalComments'] ?? '';
          _labourCostController.text = (data['labourCost'] ?? 0).toString();
          
          if (data['materialsUsed'] != null) {
            _materialsUsed.clear();
            for (var m in data['materialsUsed']) {
              _materialsUsed.add({
                'name': m['name'] ?? '',
                'category': m['category'] ?? m['brand'] ?? '',
                'quantity': m['quantity'] ?? 1,
                'unit': m['unit'] ?? 'Piece',
                'unitPrice': (m['unitPrice'] ?? m['unitCost'] ?? 0).toDouble(),
                'total': (m['total'] ?? m['totalCost'] ?? 0).toDouble(),
                
                // Backwards compatibility legacy fields
                'brand': m['brand'] ?? '',
                'model': m['model'] ?? '',
                'serialNumber': m['serialNumber'] ?? '',
                'unitCost': (m['unitCost'] ?? m['unitPrice'] ?? 0).toDouble(),
                'totalCost': (m['totalCost'] ?? m['total'] ?? 0).toDouble(),
              });
            }
          }
          
          if (data['partsInstalled'] != null) {
            _partsInstalled.clear();
            _partsInstalled.addAll(List<String>.from(data['partsInstalled']));
          }

          if (data['beforePhotos'] != null) {
            _beforePhotos.clear();
            _beforePhotos.addAll(List<String>.from(data['beforePhotos']));
          }
          if (data['duringPhotos'] != null) {
            _duringPhotos.clear();
            _duringPhotos.addAll(List<String>.from(data['duringPhotos']));
          }
          if (data['afterPhotos'] != null) {
            _afterPhotos.clear();
            _afterPhotos.addAll(List<String>.from(data['afterPhotos']));
          }

          _customerSignatureUrl = data['customerSignatureUrl'] ?? '';
          _technicianSignatureUrl = data['technicianSignatureUrl'] ?? '';
          _completionOtpVerified = data['completionOtpVerified'] ?? false;
          if (_customerSignatureUrl.isNotEmpty) {
            _isSignatureCaptured = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading worksheet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestCompleteOtp() async {
    setState(() => _sendingOtp = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.requestCompleteOtp(widget.job.id);
      if (mounted) {
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'OTP sent to customer email.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyCompleteOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _verifyingOtp = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.verifyCompleteOtp(widget.job.id, otp);
      if (mounted) {
        setState(() {
          _completionOtpVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'OTP verified successfully! Signature unlocked.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isSavingDraft = true);
    try {
      final api = ref.read(apiServiceProvider);
      final payload = _buildPayload('in_progress');
      await api.updateWorksheet(widget.job.id, payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved successfully!'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSavingDraft = false);
    }
  }

  Map<String, dynamic> _buildPayload(String status) {
    return {
      'requestedWorkDescription': _workDescController.text.trim(),
      'technicianObservations': _observationsController.text.trim(),
      'additionalComments': _commentsController.text.trim(),
      'labourCost': double.tryParse(_labourCostController.text) ?? 0.0,
      'materialsUsed': _materialsUsed,
      'partsInstalled': _partsInstalled,
      'beforePhotos': _beforePhotos,
      'duringPhotos': _duringPhotos,
      'afterPhotos': _afterPhotos,
      'customerSignatureUrl': _customerSignatureUrl,
      'technicianSignatureUrl': _technicianSignatureUrl,
      'status': status,
    };
  }

  Future<void> _pickPhoto(String type) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo (Camera)'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      maxWidth: 1280, // Image Compression: Resize width to 1280px max
      imageQuality: 75, // Image Compression: Compress quality to 75%
    );

    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await image.readAsBytes();
      final api = ref.read(apiServiceProvider);
      final filename = '${type}_${widget.job.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final urls = await api.uploadFiles([{
        'bytes': bytes,
        'name': filename
      }]);

      if (urls.isNotEmpty) {
        setState(() {
          if (type == 'before') {
            _beforePhotos.add(urls[0]);
          } else if (type == 'during') {
            _duringPhotos.add(urls[0]);
          } else if (type == 'after') {
            _afterPhotos.add(urls[0]);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadSignature() async {
    try {
      final boundary = _sigKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final sigBytes = byteData?.buffer.asUint8List();

      if (sigBytes == null) return;

      setState(() => _isLoading = true);
      final api = ref.read(apiServiceProvider);
      final filename = 'sig_cust_${widget.job.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      
      final urls = await api.uploadFiles([{
        'bytes': sigBytes,
        'name': filename
      }]);

      if (urls.isNotEmpty) {
        setState(() {
          _customerSignatureUrl = urls[0];
          _isSignatureCaptured = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signature captured and uploaded!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signature upload failed: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitWorksheet() async {
    // Final Validations before submitting worksheet
    if (!_completionOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation error: Customer OTP verification is mandatory.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_beforePhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation error: Upload at least 1 Before photo.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_afterPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation error: Upload at least 1 After photo.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_isSignatureCaptured || _customerSignatureUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation error: Customer signature is required.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final payload = _buildPayload('submitted');
      
      // Submit worksheet
      await api.updateWorksheet(widget.job.id, payload);
      
      // Move Job status to work_uploaded
      await api.updateJobStatus(widget.job.id, 'work_uploaded');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worksheet submitted successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return to details screen and refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMaterialDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'Piece');
    final priceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Material Used', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name*')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity*')),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (e.g. Meter, Piece, Box)*')),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Price (INR)*')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              final qty = int.tryParse(qtyController.text) ?? 1;
              final price = double.tryParse(priceController.text) ?? 0.0;
              setState(() {
                _materialsUsed.add({
                  'name': nameController.text.trim(),
                  'category': categoryController.text.trim(),
                  'quantity': qty,
                  'unit': unitController.text.trim(),
                  'unitPrice': price,
                  'total': qty * price,
                  
                  // Legacy fields for compatibility
                  'brand': categoryController.text.trim(),
                  'model': '',
                  'serialNumber': '',
                  'unitCost': price,
                  'totalCost': qty * price,
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Digital Worksheet', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSavingDraft ? null : _saveDraft,
              icon: _isSavingDraft 
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCurrentStepContent(),
                ),
              ),
              _buildBottomNavBar()
            ],
          ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${_currentStep + 1} OF 7',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11, letterSpacing: 1.5),
              ),
              Text(
                _getStepTitle(_currentStep),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentStep + 1) / 7.0,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF2563EB),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          )
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Requested Work';
      case 1: return 'Findings & Observations';
      case 2: return 'Materials Used';
      case 3: return 'Labour Notes & Cost';
      case 4: return 'Work Photos';
      case 5: return 'Customer Signature';
      case 6: return 'Review & Submit';
      default: return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0: return _buildStepRequestedWork();
      case 1: return _buildStepObservations();
      case 2: return _buildStepMaterials();
      case 3: return _buildStepLabour();
      case 4: return _buildStepPhotos();
      case 5: return _buildStepSignature();
      case 6: return _buildStepReview();
      default: return const SizedBox();
    }
  }

  Widget _buildStepRequestedWork() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Requested Work Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        const Text('Detail the original work requested by the client or booking instructions.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        TextField(
          controller: _workDescController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Enter details here...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB))),
          ),
        ),
      ],
    );
  }

  Widget _buildStepObservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Diagnostic Findings & Observations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        const Text('Record your diagnosis, site status, and issues observed upon arrival.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        TextField(
          controller: _observationsController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Enter findings here...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB))),
          ),
        ),
      ],
    );
  }

  Widget _buildStepMaterials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Materials Used List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ElevatedButton.icon(
              onPressed: _addMaterialDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_materialsUsed.isEmpty)
          Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text('No materials added yet.', style: TextStyle(color: Color(0xFF94A3B8))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _materialsUsed.length,
            itemBuilder: (context, index) {
              final mat = _materialsUsed[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(mat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Qty: ${mat['quantity']} ${mat['unit'] ?? 'Piece'} | Price: INR ${mat['unitPrice'] ?? mat['unitCost'] ?? 0} (${mat['category'] ?? ''})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('₹${mat['total'] ?? mat['totalCost'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _materialsUsed.removeAt(index);
                          });
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStepLabour() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Labour Details & Cost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),
        TextField(
          controller: _labourCostController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Labour Cost (INR)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Additional Comments / Labour Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        TextField(
          controller: _commentsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter additional remarks...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  Widget _buildStepPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Job Photos Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        const Text('At least 1 Before and 1 After photo is mandatory.', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildPhotoCategory('BEFORE WORK PHOTOS*', _beforePhotos, 'before'),
        const SizedBox(height: 20),
        _buildPhotoCategory('DURING WORK PHOTOS', _duringPhotos, 'during'),
        const SizedBox(height: 20),
        _buildPhotoCategory('AFTER WORK PHOTOS*', _afterPhotos, 'after'),
      ],
    );
  }

  Widget _buildPhotoCategory(String title, List<String> list, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              onTap: () => _pickPhoto(type),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 70,
                child: list.isEmpty
                  ? Container(
                      alignment: Alignment.centerLeft,
                      child: const Text('No photos added', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      itemBuilder: (ctx, idx) => Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(image: NetworkImage(list[idx]), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 14,
                            child: GestureDetector(
                              onTap: () => setState(() => list.removeAt(idx)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildStepSignature() {
    if (!_completionOtpVerified) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer OTP Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text(
            'Before the customer can sign, please generate a completion OTP and verify it to confirm job details with the customer.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          if (!_otpSent) ...[
            Center(
              child: ElevatedButton.icon(
                onPressed: _sendingOtp ? null : _requestCompleteOtp,
                icon: _sendingOtp 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
                label: const Text('Generate & Send Completion OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter 6-Digit Completion OTP',
                hintText: 'xxxxxx',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2563EB))),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sendingOtp ? null : _requestCompleteOtp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _sendingOtp 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Resend OTP'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifyingOtp ? null : _verifyCompleteOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _verifyingOtp 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify OTP'),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Customer Signature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text('OTP Verified', style: TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Ask the customer to sign digitally in the box below.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: RepaintBoundary(
              key: _sigKey,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      _sigPoints.add(details.localPosition);
                    }
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _sigPoints.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _sigPoints.add(null);
                  });
                },
                child: CustomPaint(
                  painter: SignaturePainter(_sigPoints),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _sigPoints.clear();
                  _customerSignatureUrl = '';
                  _isSignatureCaptured = false;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Pad'),
            ),
            ElevatedButton.icon(
              onPressed: _uploadSignature,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Confirm & Upload Signature'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),

        if (_isSignatureCaptured) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 12),
                Text('Customer signature uploaded successfully!', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )
        ]
      ],
    );
  }

  Widget _buildStepReview() {
    double matTotal = 0;
    for (var m in _materialsUsed) {
      matTotal += ((m['total'] ?? m['totalCost'] ?? 0) as num).toDouble();
    }
    double labour = double.tryParse(_labourCostController.text) ?? 0.0;
    double grandTotal = matTotal + labour;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Service Worksheet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),
        _buildReviewRow('Requested Work:', _workDescController.text),
        _buildReviewRow('Observations:', _observationsController.text),
        _buildReviewRow('Materials Used:', '${_materialsUsed.length} item(s)'),
        _buildReviewRow('Labour Cost:', 'INR $labour'),
        _buildReviewRow('Materials Cost:', 'INR $matTotal'),
        _buildReviewRow('Grand Total:', 'INR $grandTotal', isBold: true),
        _buildReviewRow('Before Photos:', '${_beforePhotos.length} photo(s)'),
        _buildReviewRow('After Photos:', '${_afterPhotos.length} photo(s)'),
        _buildReviewRow('Signature:', _isSignatureCaptured ? 'Captured' : 'Awaiting', isAlert: !_isSignatureCaptured),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isBold = false, bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isAlert ? Colors.red : (isBold ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('BACK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep == 5) {
                  if (!_completionOtpVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please verify the Customer Completion OTP first.'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  if (!_isSignatureCaptured || _customerSignatureUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please capture and upload the Customer Signature first.'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                }
                if (_currentStep < 6) {
                  setState(() => _currentStep++);
                } else {
                  _submitWorksheet();
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentStep < 6 ? 'NEXT' : 'SUBMIT WORKSHEET',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => oldDelegate.points != points;
}
