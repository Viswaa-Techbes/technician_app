import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/api_service.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _kycData;
  String _kycStatus = 'Pending';
  String _rejectionReason = '';

  // Form Controllers
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _accNameController = TextEditingController();
  final _accNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _skillsController = TextEditingController();

  // Images URLs or local paths
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;
  String? _panUrl;
  String? _signatureUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    setState(() => _isLoading = true);
    try {
      final session = ref.read(authProvider);
      if (session == null) throw Exception("Not logged in");

      final api = ref.read(apiServiceProvider);
      
      final url = Uri.parse('${api.baseUrl}/api/v2/kyc/me');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer ${session.token}',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _kycStatus = data['kycStatus'] ?? 'Pending';
          _rejectionReason = data['kycRejectionReason'] ?? '';
          _kycData = data['kycDetails'] ?? {};
          
          if (_kycData != null) {
            _aadhaarController.text = _kycData!['aadhaarNumber'] ?? '';
            _panController.text = _kycData!['panNumber'] ?? '';
            _aadhaarFrontUrl = _kycData!['aadhaarImageFront'];
            _aadhaarBackUrl = _kycData!['aadhaarImageBack'];
            _panUrl = _kycData!['panImage'];
            _signatureUrl = _kycData!['signatureImage'];
            
            final bank = _kycData!['bankDetails'] ?? {};
            _accNameController.text = bank['accountName'] ?? '';
            _accNoController.text = bank['accountNumber'] ?? '';
            _ifscController.text = bank['ifscCode'] ?? '';
            _bankNameController.text = bank['bankName'] ?? '';
          }
          
          final skills = data['skills'] as List<dynamic>? ?? [];
          _skillsController.text = skills.join(', ');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(String fieldName) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    setState(() => _isLoading = true);
    try {
      final session = ref.read(authProvider);
      final api = ref.read(apiServiceProvider);
      final request = http.MultipartRequest('POST', Uri.parse('${api.baseUrl}/api/v2/upload'));
      request.headers['Authorization'] = 'Bearer ${session!.token}';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['fileUrl'];
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: $e')));
      }
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitKyc() async {
    setState(() => _isLoading = true);
    try {
      final session = ref.read(authProvider);
      final api = ref.read(apiServiceProvider);
      final url = Uri.parse('${api.baseUrl}/api/v2/kyc/submit');

      final body = {
        "aadhaarNumber": _aadhaarController.text,
        "aadhaarImageFront": _aadhaarFrontUrl,
        "aadhaarImageBack": _aadhaarBackUrl,
        "panNumber": _panController.text,
        "panImage": _panUrl,
        "bankDetails": {
          "accountName": _accNameController.text,
          "accountNumber": _accNoController.text,
          "ifscCode": _ifscController.text,
          "bankName": _bankNameController.text
        },
        "signatureImage": _signatureUrl,
        "skills": _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
      };

      final response = await http.put(url, headers: {
        'Authorization': 'Bearer ${session!.token}',
        'Content-Type': 'application/json'
      }, body: json.encode(body));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Submitted Successfully')));
        }
        _fetchKycStatus();
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Submission failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImageUploader(String title, String? url, Function(String?) onUploaded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _kycStatus == 'Approved' || _kycStatus == 'Submitted' ? null : () async {
            final uploadedUrl = await _uploadImage(title);
            if (uploadedUrl != null) onUploaded(uploadedUrl);
          },
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50
            ),
            child: url != null && url.isNotEmpty
                ? Image.network(url, fit: BoxFit.contain)
                : const Center(child: Icon(Icons.upload_file, color: Colors.grey)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool readOnly = _kycStatus == 'Approved' || _kycStatus == 'Submitted';

    return Scaffold(
      appBar: AppBar(title: const Text('Technician KYC')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBanner(),
                const SizedBox(height: 24),
                
                const Text("Identity Documents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                TextField(controller: _aadhaarController, decoration: const InputDecoration(labelText: 'Aadhaar Number'), enabled: !readOnly),
                const SizedBox(height: 16),
                _buildImageUploader("Aadhaar Front Image", _aadhaarFrontUrl, (url) => setState(() => _aadhaarFrontUrl = url)),
                _buildImageUploader("Aadhaar Back Image", _aadhaarBackUrl, (url) => setState(() => _aadhaarBackUrl = url)),
                
                TextField(controller: _panController, decoration: const InputDecoration(labelText: 'PAN Number'), enabled: !readOnly),
                const SizedBox(height: 16),
                _buildImageUploader("PAN Card Image", _panUrl, (url) => setState(() => _panUrl = url)),
                
                const SizedBox(height: 24),
                const Text("Bank Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                TextField(controller: _accNameController, decoration: const InputDecoration(labelText: 'Account Name'), enabled: !readOnly),
                TextField(controller: _accNoController, decoration: const InputDecoration(labelText: 'Account Number'), enabled: !readOnly),
                TextField(controller: _ifscController, decoration: const InputDecoration(labelText: 'IFSC Code'), enabled: !readOnly),
                TextField(controller: _bankNameController, decoration: const InputDecoration(labelText: 'Bank Name'), enabled: !readOnly),
                
                const SizedBox(height: 24),
                const Text("Professional Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                TextField(
                  controller: _skillsController, 
                  decoration: const InputDecoration(labelText: 'Skills (comma separated)', hintText: 'CCTV, Networking, Intercom'), 
                  enabled: !readOnly
                ),
                const SizedBox(height: 16),
                _buildImageUploader("Digital Signature", _signatureUrl, (url) => setState(() => _signatureUrl = url)),
                
                const SizedBox(height: 32),
                if (!readOnly)
                  ElevatedButton(
                    onPressed: _submitKyc,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade700
                    ),
                    child: const Text('Submit KYC Documents', style: TextStyle(fontSize: 16, color: Colors.white)),
                  )
              ],
            ),
          ),
    );
  }

  Widget _buildStatusBanner() {
    Color bgColor;
    Color textColor;
    String text;
    
    switch (_kycStatus) {
      case 'Approved':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = "Your KYC is verified and approved.";
        break;
      case 'Submitted':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        text = "Your KYC is under review by admin.";
        break;
      case 'Rejected':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = "Your KYC was rejected: $_rejectionReason";
        break;
      default:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = "Please complete your KYC to receive jobs.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}
