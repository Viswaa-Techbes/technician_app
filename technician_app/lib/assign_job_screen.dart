import 'package:flutter/material.dart';
import 'widgets.dart';
import 'models.dart';
import 'demo_data.dart';

class AssignJobScreen extends StatefulWidget {
  const AssignJobScreen({super.key});

  @override
  State<AssignJobScreen> createState() => _AssignJobScreenState();
}

class _AssignJobScreenState extends State<AssignJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  String _selectedTech = "Alex Brown";
  final List<String> _technicians = ["Alex Brown", "Jamie Doe", "Chris Wong", "Sarah Miller"];

  @override
  void dispose() {
    _serviceNameController.dispose();
    _customerNameController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("ASSIGN NEW PROJECT")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("PROJECT DETAILS"),
              const SizedBox(height: 16),
              _buildTextField("Service Name", Icons.settings_suggest_rounded, "e.g., CCTV Installation", _serviceNameController),
              const SizedBox(height: 16),
              _buildTextField("Customer Name", Icons.person_outline_rounded, "e.g., John Doe", _customerNameController),
              const SizedBox(height: 16),
              _buildTextField("Site Address", Icons.location_on_outlined, "Full project location", _addressController),
              const SizedBox(height: 32),
              _buildSectionHeader("LOGISTICS"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField("Date", Icons.calendar_today_rounded, "YYYY-MM-DD", _dateController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("Time", Icons.access_time_rounded, "00:00 AM/PM", _timeController)),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionHeader("DISPATCH TO"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTech,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_circle_rounded, color: Color(0xFF1E3A8A)),
                    items: _technicians.map((String tech) {
                      return DropdownMenuItem(value: tech, child: Text(tech, style: const TextStyle(fontWeight: FontWeight.w700)));
                    }).toList(),
                    onChanged: (newValue) => setState(() => _selectedTech = newValue!),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                label: "CONFIRM ASSIGNMENT",
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newJob = Job(
                      id: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
                      serviceName: _serviceNameController.text.isNotEmpty ? _serviceNameController.text : "New Service",
                      customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : "Customer",
                      customerPhone: "555-000",
                      address: _addressController.text.isNotEmpty ? _addressController.text : "TBD",
                      time: _timeController.text.isNotEmpty ? _timeController.text : "TBD",
                      status: JobStatus.assigned,
                      technicianName: _selectedTech,
                      assignedBy: "Manager Mike",
                    );
                    DemoData.instance.addJob(newJob);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Project successfully assigned by Manager Mike")),
                    );
                    Navigator.pop(context);
                  }
                },
                color: const Color(0xFF1E3A8A),
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5));
  }

  Widget _buildTextField(String label, IconData icon, String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }
}
