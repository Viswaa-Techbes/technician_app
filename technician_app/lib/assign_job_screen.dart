import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'services/mock_data_service.dart';
import 'widgets.dart';

class AssignJobScreen extends ConsumerStatefulWidget {
  const AssignJobScreen({super.key});

  @override
  ConsumerState<AssignJobScreen> createState() => _AssignJobScreenState();
}

class _AssignJobScreenState extends ConsumerState<AssignJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationLinkController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];
  
  List<Map<String, dynamic>> _technicians = [];
  String? _selectedTechId;
  String? _selectedTechName;
  final _techNameController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationLinkController.text = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
      });
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _fetchTechnicians() async {
    if (MockDataService.useMock) {
      final mockTechs = await MockDataService().getTechnicians();
      setState(() {
        _technicians = mockTechs.map((t) => {
          'id': t.id,
          'name': t.name,
          'email': t.email,
          'isOnline': t.isOnline,
          'status': t.status.name,
        }).toList();
        if (_technicians.isNotEmpty) {
          _selectedTechId = _technicians.first['id'];
          _selectedTechName = _technicians.first['name'];
        }
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'technician')
          .get();
      
      setState(() {
        _technicians = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Technician',
          'email': doc.data()['email'] ?? '',
          'isOnline': doc.data()['isOnline'] ?? false,
          'status': doc.data()['status'] ?? 'available',
        }).toList();
        
        if (_technicians.isNotEmpty) {
          _selectedTechId = _technicians.first['id'];
          _selectedTechName = _technicians.first['name'];
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_technicians.isEmpty && _techNameController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    final List<String> filePaths = _selectedFiles.map((f) => f.path ?? '').where((p) => p.isNotEmpty).toList();

    if (MockDataService.useMock) {
      final techId = _selectedTechId ?? 'mock_tech';
      final techName = _selectedTechName ?? _techNameController.text.trim();
      await MockDataService().assignJob('job_new_${DateTime.now().millisecondsSinceEpoch}', techId, techName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mock: Task assigned successfully!")));
        Navigator.pop(context);
      }
      return;
    }

    try {
        final locationInput = _locationLinkController.text.trim();
        String finalLocation = locationInput;
        // If user enters "lat,lng" instead of a link:
        if (RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$').hasMatch(locationInput)) {
          finalLocation = "https://www.google.com/maps?q=$locationInput";
        }
        
        await FirebaseFirestore.instance.collection('projects').add({
          'serviceName': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'address': _addressController.text.trim(),
          'technicianId': _selectedTechId ?? 'manual_${DateTime.now().millisecondsSinceEpoch}',
          'technicianName': _selectedTechName ?? _techNameController.text.trim(),
          'status': 'assigned',
          'createdAt': FieldValue.serverTimestamp(),
          'customerName': 'Assigned by Manager',
          'customerPhone': '',
          'time': 'Scheduled',
          'price': 0.0,
          'googleMapsLink': finalLocation,
          'fileAttachments': filePaths,
        });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task successfully assigned!"), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to assign: $e"), backgroundColor: const Color(0xFFF43F5E)),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _locationLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("ASSIGN NEW PROJECT")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("PROJECT DETAILS"),
                    const SizedBox(height: 16),
                    _buildTextField("Task Title", Icons.settings_suggest_rounded, "e.g., CCTV Installation", _titleController, required: true),
                    const SizedBox(height: 16),
                    _buildTextField("Site Address", Icons.location_on_outlined, "Full location details", _addressController, required: true),
                    const SizedBox(height: 16),
                    _buildTextField("Description", Icons.description_outlined, "Describe the task...", _descriptionController, maxLines: 3),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    _buildSectionHeader("GOOGLE MAPS LOCATION"),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Maps Link", Icons.map_rounded, "Paste Google Maps link here...", _locationLinkController)),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          tooltip: "Use My Location",
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader("PROJECT FILES"),
                    const SizedBox(height: 16),
                    _buildFilePicker(),
                    const SizedBox(height: 32),
                    _buildSectionHeader("DISPATCH TO"),
                    const SizedBox(height: 16),
                    _technicians.isEmpty
                        ? _buildTextField("Technician Name", Icons.person_rounded, "Target technician", _techNameController, required: true)
                        : _buildSearchableTechDropdown(),
                    const SizedBox(height: 48),
                    _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(label: "CONFIRM ASSIGNMENT", onPressed: _submitAssignment, color: const Color(0xFF1E3A8A), icon: Icons.check_circle_rounded),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchableTechDropdown() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => option['name'],
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return const Iterable<Map<String, dynamic>>.empty();
        return _technicians.where((tech) {
          final name = tech['name'].toString().toLowerCase();
          final online = tech['isOnline'] == true;
          final available = tech['status'] == 'available';
          return name.contains(textEditingValue.text.toLowerCase()) && (online || available);
        });
      },
      onSelected: (Map<String, dynamic> selection) {
        setState(() {
          _selectedTechId = selection['id'];
          _selectedTechName = selection['name'];
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return _buildTextField("Search Technician", Icons.person_search_rounded, "Type name...", controller, focusNode: focusNode);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final tech = options.elementAt(index);
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: tech['isOnline'] == true ? Colors.green.shade50 : Colors.blue.shade50, radius: 14, child: Icon(Icons.person, size: 14, color: tech['isOnline'] == true ? Colors.green : Colors.blue)),
                    title: Text(tech['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
                    subtitle: Text(tech['isOnline'] == true ? "ONLINE" : "AVAILABLE", style: TextStyle(color: tech['isOnline'] == true ? Colors.green : Colors.blue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                    onTap: () => onSelected(tech),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTechDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTechId,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_circle_rounded, color: Color(0xFF1E3A8A)),
          items: _technicians.map((tech) {
            return DropdownMenuItem<String>(
              value: tech['id'] as String?,
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Color(0xFFF0F7FF), shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tech['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(tech['email'], style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedTechId = newValue;
              _selectedTechName = _technicians.firstWhere((t) => t['id'] == newValue)['name'];
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(allowMultiple: true);
            if (result != null) {
              setState(() => _selectedFiles = result.files);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload_rounded, color: Color(0xFF6366F1)),
                const SizedBox(width: 12),
                Text(_selectedFiles.isEmpty ? "UPLOAD FILES" : "${_selectedFiles.length} FILES SELECTED", 
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569))),
              ],
            ),
          ),
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._selectedFiles.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(child: Text(f.name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5));
  }

  Widget _buildTextField(String label, IconData icon, String hint, TextEditingController controller, {bool required = false, int maxLines = 1, TextInputType? keyboardType, FocusNode? focusNode}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      focusNode: focusNode,
      validator: required ? (value) => (value == null || value.isEmpty) ? '$label is required' : null : null,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }
}
