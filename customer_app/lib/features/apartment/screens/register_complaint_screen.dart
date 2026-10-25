import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/apartment_repository.dart';
import '../providers/apartment_provider.dart';

class RegisterComplaintScreen extends ConsumerStatefulWidget {
  const RegisterComplaintScreen({super.key});

  @override
  ConsumerState<RegisterComplaintScreen> createState() => _RegisterComplaintScreenState();
}

class _RegisterComplaintScreenState extends ConsumerState<RegisterComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customUrlController = TextEditingController();

  String _selectedCategory = 'Plumbing/Water';
  String _selectedPriority = 'Medium';
  final List<String> _uploadedPhotoUrls = [];
  bool _isUploadingPhoto = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Plumbing/Water',
    'Electrical',
    'Lift',
    'Security',
    'Cleaning',
    'Waste Management',
    'Internet',
    'Civil Maintenance',
    'Other',
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'Low', 'label': 'Low (Routine observation)'},
    {'value': 'Medium', 'label': 'Medium (Standard maintenance)'},
    {'value': 'High', 'label': 'High (Impacting daily flat use)'},
    {'value': 'Emergency', 'label': 'Emergency (Urgent safety or pipe burst)'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final repo = ref.read(apartmentRepositoryProvider);
      final photoUrl = await repo.uploadPhoto(picked);

      if (photoUrl.isNotEmpty && mounted) {
        setState(() {
          _uploadedPhotoUrls.add(photoUrl);
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showDirectUrlInputDialog('Photo upload encountered an issue. You can paste a direct photo link or try again.');
      }
    }
  }

  void _showDirectUrlInputDialog(String? notice) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Attach Photo URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notice != null) ...[
                Text(notice, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _customUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://images.unsplash.com/... or Cloudinary link',
                  labelText: 'Image Web Link',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () {
                final url = _customUrlController.text.trim();
                if (url.isNotEmpty) {
                  setState(() {
                    _uploadedPhotoUrls.add(url);
                    _customUrlController.clear();
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Attach', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final ticket = await ref.read(apartmentProvider.notifier).createComplaint(
            subject: _subjectController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            priority: _selectedPriority,
            attachments: _uploadedPhotoUrls,
          );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(ticket.ticketId, ticket.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final err = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String ticketId, String mongoId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Complaint Submitted!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ticket ID is #$ticketId.',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your apartment in-charge and maintenance staff have received this complaint. You will receive real-time status updates as it progresses.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.pushReplacement('/apartment/complaints/$mongoId');
              },
              child: const Text('Track Ticket Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apartmentProvider);
    final res = state.profileData?.resident;
    final apt = state.profileData?.apartment;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Register Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resident Flat Info Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_city_rounded, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt?.name ?? 'TechBes Demo Residency',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.primaryColor),
                          ),
                          Text(
                            'Flat ${res?.flatNumber ?? "A-101"} (${res?.block ?? "Block A"}) • Registered Resident',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Category dropdown
              const Text('Complaint Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Priority Selector
              const Text('Urgency Priority *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPriority,
                    isExpanded: true,
                    items: _priorities.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['value'],
                        child: Text(p['label']!, style: const TextStyle(fontSize: 13.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPriority = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Complaint Title / Subject
              const Text('Complaint Title / Subject *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'e.g. Master bathroom flush valve leakage',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a title for the complaint';
                  if (val.trim().length < 5) return 'Title must be at least 5 characters';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Detailed Description
              const Text('Detailed Description *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Explain the issue in detail, when it began, and any relevant details...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter description details';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Supporting Photos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Supporting Photos (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  TextButton.icon(
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Add Link', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showDirectUrlInputDialog(null),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Photo Picker Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Take Photo', style: TextStyle(fontSize: 12)),
                      onPressed: _isUploadingPhoto ? null : () => _pickAndUploadPhoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                      onPressed: _isUploadingPhoto ? null : () => _pickAndUploadPhoto(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

              if (_isUploadingPhoto) ...[
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Uploading photo to server...', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ],

              // Uploaded Photos Thumbnails
              if (_uploadedPhotoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _uploadedPhotoUrls.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final url = _uploadedPhotoUrls[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () {
                                setState(() => _uploadedPhotoUrls.removeAt(i));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting || _isUploadingPhoto ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Complaint to In-Charge',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
