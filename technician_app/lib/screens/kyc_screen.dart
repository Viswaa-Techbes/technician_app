import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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

  // Document objects and URLs
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;
  String? _panUrl;
  String? _signatureUrl;
  String? _bankProofUrl;
  String? _selfieUrl;

  Map<String, dynamic>? _aadhaarFrontDoc;
  Map<String, dynamic>? _aadhaarBackDoc;
  Map<String, dynamic>? _panDoc;
  Map<String, dynamic>? _signatureDoc;
  Map<String, dynamic>? _bankProofDoc;
  Map<String, dynamic>? _selfieDoc;

  String _uploadProgressText = "";

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
          
          final kycDocs = data['kycDocuments'] ?? {};
          _aadhaarFrontDoc = kycDocs['aadhaarFront'];
          _aadhaarBackDoc = kycDocs['aadhaarBack'];
          _panDoc = kycDocs['panCard'];
          _signatureDoc = kycDocs['signature'];
          _bankProofDoc = kycDocs['bankProof'];
          _selfieDoc = kycDocs['selfie'];

          if (_kycData != null) {
            _aadhaarController.text = _kycData!['aadhaarNumber'] ?? '';
            _panController.text = _kycData!['panNumber'] ?? '';
            
            _aadhaarFrontUrl = _aadhaarFrontDoc?['url'] ?? _kycData!['aadhaarImageFront'];
            _aadhaarBackUrl = _aadhaarBackDoc?['url'] ?? _kycData!['aadhaarImageBack'];
            _panUrl = _panDoc?['url'] ?? _kycData!['panImage'];
            _signatureUrl = _signatureDoc?['url'] ?? _kycData!['signatureImage'];
            _bankProofUrl = _bankProofDoc?['url'];
            _selfieUrl = _selfieDoc?['url'];

            // Initialize Doc maps from legacy URLs if they are not yet set
            _aadhaarFrontDoc ??= _aadhaarFrontUrl != null ? {'url': _aadhaarFrontUrl, 'type': 'image'} : null;
            _aadhaarBackDoc ??= _aadhaarBackUrl != null ? {'url': _aadhaarBackUrl, 'type': 'image'} : null;
            _panDoc ??= _panUrl != null ? {'url': _panUrl, 'type': 'image'} : null;
            _signatureDoc ??= _signatureUrl != null ? {'url': _signatureUrl, 'type': 'image'} : null;
            _bankProofDoc ??= _bankProofUrl != null ? {'url': _bankProofUrl, 'type': 'image'} : null;
            _selfieDoc ??= _selfieUrl != null ? {'url': _selfieUrl, 'type': 'image'} : null;
            
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

  Future<Map<String, dynamic>?> _uploadDocument(String fieldName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;

      // Validate file size (10 MB limit)
      const int maxSizeBytes = 10 * 1024 * 1024;
      if (file.size > maxSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size exceeds the 10MB limit.')),
          );
        }
        return null;
      }

      final filePath = file.path;
      if (filePath == null) return null;

      final session = ref.read(authProvider);
      final api = ref.read(apiServiceProvider);
      final uploadUrl = Uri.parse('${api.baseUrl}/api/v2/upload');

      Map<String, dynamic>? finalResult;
      
      // Retry loop (3 attempts)
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          setState(() {
            _isLoading = true;
            _uploadProgressText = "Uploading $fieldName: 0%";
          });

          final request = TrackedMultipartRequest(
            'POST',
            uploadUrl,
            onProgress: (bytes, totalBytes) {
              if (totalBytes > 0) {
                final percentage = (bytes / totalBytes * 100).toInt();
                setState(() {
                  _uploadProgressText = "Uploading $fieldName: $percentage%";
                });
              }
            },
          );

          request.headers['Authorization'] = 'Bearer ${session!.token}';
          request.files.add(await http.MultipartFile.fromPath('file', filePath));

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 201 || response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success'] == true) {
              finalResult = {
                'url': data['url'] ?? data['fileUrl'],
                'publicId': data['publicId'] ?? data['public_id'],
                'type': data['type'] ?? (filePath.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image'),
                'uploadedAt': DateTime.now().toIso8601String(),
              };
              break; // Success! Break out of retry loop.
            }
          }
          throw Exception("Server returned status code ${response.statusCode}");
        } catch (e) {
          debugPrint("Upload attempt $attempt failed: $e");
          if (attempt == 3) {
            throw Exception("Failed to upload after 3 attempts: $e");
          }
          await Future.delayed(const Duration(seconds: 1)); // Delay before retry
        }
      }

      return finalResult;
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
    // Validate that all 6 required documents are uploaded
    if (_aadhaarFrontDoc == null ||
        _aadhaarBackDoc == null ||
        _panDoc == null ||
        _signatureDoc == null ||
        _bankProofDoc == null ||
        _selfieDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all 6 required KYC documents.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _uploadProgressText = "Submitting KYC...";
    try {
      final session = ref.read(authProvider);
      final api = ref.read(apiServiceProvider);
      final url = Uri.parse('${api.baseUrl}/api/v2/kyc/submit');

      final body = {
        "aadhaarNumber": _aadhaarController.text,
        "panNumber": _panController.text,
        "bankDetails": {
          "accountName": _accNameController.text,
          "accountNumber": _accNoController.text,
          "ifscCode": _ifscController.text,
          "bankName": _bankNameController.text
        },
        "skills": _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        "kycDocuments": {
          "aadhaarFront": _aadhaarFrontDoc,
          "aadhaarBack": _aadhaarBackDoc,
          "panCard": _panDoc,
          "signature": _signatureDoc,
          "bankProof": _bankProofDoc,
          "selfie": _selfieDoc
        }
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

  Widget _buildDocUploader(String title, Map<String, dynamic>? doc, Function(Map<String, dynamic>?) onUploaded) {
    final url = doc?['url'];
    final isPdf = doc?['type'] == 'pdf' || (url != null && url.toLowerCase().endsWith('.pdf'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _kycStatus == 'Approved' || _kycStatus == 'Submitted' ? null : () async {
            final uploadedDoc = await _uploadDocument(title);
            if (uploadedDoc != null) onUploaded(uploadedDoc);
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
                ? (isPdf 
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                            SizedBox(height: 4),
                            Text("PDF Document", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      )
                    : Image.network(url, fit: BoxFit.contain))
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
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _uploadProgressText.isNotEmpty ? _uploadProgressText : "Loading...", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ],
            ),
          )
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
                _buildDocUploader("Aadhaar Front Image / PDF", _aadhaarFrontDoc, (doc) => setState(() => _aadhaarFrontDoc = doc)),
                _buildDocUploader("Aadhaar Back Image / PDF", _aadhaarBackDoc, (doc) => setState(() => _aadhaarBackDoc = doc)),
                
                TextField(controller: _panController, decoration: const InputDecoration(labelText: 'PAN Number'), enabled: !readOnly),
                const SizedBox(height: 16),
                _buildDocUploader("PAN Card Image / PDF", _panDoc, (doc) => setState(() => _panDoc = doc)),
                
                const SizedBox(height: 24),
                const Text("Bank Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                TextField(controller: _accNameController, decoration: const InputDecoration(labelText: 'Account Name'), enabled: !readOnly),
                TextField(controller: _accNoController, decoration: const InputDecoration(labelText: 'Account Number'), enabled: !readOnly),
                TextField(controller: _ifscController, decoration: const InputDecoration(labelText: 'IFSC Code'), enabled: !readOnly),
                TextField(controller: _bankNameController, decoration: const InputDecoration(labelText: 'Bank Name'), enabled: !readOnly),
                const SizedBox(height: 16),
                _buildDocUploader("Bank Proof (Cancelled Cheque / Passbook)", _bankProofDoc, (doc) => setState(() => _bankProofDoc = doc)),
                
                const SizedBox(height: 24),
                const Text("Selfie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                _buildDocUploader("Selfie Image", _selfieDoc, (doc) => setState(() => _selfieDoc = doc)),
                
                const SizedBox(height: 24),
                const Text("Professional Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                TextField(
                  controller: _skillsController, 
                  decoration: const InputDecoration(labelText: 'Skills (comma separated)', hintText: 'CCTV, Networking, Intercom'), 
                  enabled: !readOnly
                ),
                const SizedBox(height: 16),
                _buildDocUploader("Digital Signature", _signatureDoc, (doc) => setState(() => _signatureDoc = doc)),
                
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

class TrackedMultipartRequest extends http.MultipartRequest {
  final void Function(int bytes, int totalBytes) onProgress;

  TrackedMultipartRequest(
    String method,
    Uri url, {
    required this.onProgress,
  }) : super(method, url);

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        onProgress(bytes, total);
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
