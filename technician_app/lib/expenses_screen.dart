import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'models.dart';
import 'widgets.dart';
import 'services/api_service.dart';
import 'services/connectivity_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedProjectId;
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  List<Expense> _expenses = [];
  List<Job> _myJobs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final rawExpenses = await api.getExpenses();
      
      final parsedExpenses = rawExpenses.map((e) {
        final amountNum = (e['amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = e['createdAt'] != null
            ? DateTime.tryParse(e['createdAt'].toString())?.toLocal().toString().split(' ')[0] ?? 'Recent'
            : 'Recent';

        return Expense(
          id: (e['_id'] ?? e['id'] ?? '').toString(),
          description: (e['description'] ?? '').toString(),
          amount: amountNum,
          date: createdAt,
          status: (e['status'] ?? 'pending').toString(),
          receiptUrl: e['receiptUrl']?.toString(),
          projectId: e['jobId']?['_id']?.toString() ?? e['jobId']?.toString(),
          technicianId: e['technicianId']?['_id']?.toString() ?? e['technicianId']?.toString(),
        );
      }).toList();

      List<Job> jobs = [];
      try {
        jobs = await api.getJobs();
      } catch (_) {
        // Non-critical if jobs fail to load for dropdown
      }

      if (mounted) {
        setState(() {
          _expenses = parsedExpenses;
          _myJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showAddExpenseSheet() {
    _pickedFile = null;
    _amountController.clear();
    _descController.clear();
    _selectedProjectId = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text('LOG EXPENSE', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              const Text('Add work-related cost', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 24),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Amount (INR)',
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                  hintText: '0.00',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Category / Purpose',
                  hintText: 'e.g. Fuel, Cable Connectors, Parking',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 18),
              _buildProjectDropdown(setModalState),
              const SizedBox(height: 20),
              _buildImagePickerPlaceholder(() async {
                final result = await FilePicker.platform.pickFiles(type: FileType.image);
                if (result != null) {
                  setModalState(() => _pickedFile = result.files.first);
                }
              }),
              const SizedBox(height: 32),
              _isUploading 
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    label: 'SUBMIT EXPENSE CLAIM',
                    onPressed: () => _saveExpense(context),
                    color: const Color(0xFF1E3A8A),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectDropdown(StateSetter setModalState) {
    return DropdownButtonFormField<String>(
      value: _selectedProjectId,
      decoration: InputDecoration(
        labelText: 'Link to Project / Job (Optional)',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('General Field Expense (No Job Link)', style: TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        ..._myJobs.map((j) => DropdownMenuItem(
          value: j.id,
          child: Text('#${j.id} - ${j.serviceName}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
        )),
      ],
      onChanged: (val) => setModalState(() => _selectedProjectId = val),
    );
  }

  Future<void> _saveExpense(BuildContext context) async {
    final rawAmount = _amountController.text.trim();
    final description = _descController.text.trim();

    // 1. Strict Validation
    if (rawAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expense amount'), backgroundColor: Colors.red),
      );
      return;
    }

    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than ₹0'), backgroundColor: Colors.red),
      );
      return;
    }

    if (amount > 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum single claim limit is ₹50,000'), backgroundColor: Colors.red),
      );
      return;
    }

    if (description.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must be at least 3 characters long'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Connectivity check
    final conn = ref.read(connectivityProvider);
    if (conn == ConnectivityStatus.isDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Please reconnect to submit expenses.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      String? receiptUrl;

      if (_pickedFile != null && _pickedFile!.path != null) {
        try {
          final refStorage = FirebaseStorage.instance
              .ref()
              .child('receipts/${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}');
          await refStorage.putFile(File(_pickedFile!.path!));
          receiptUrl = await refStorage.getDownloadURL();
        } catch (storageErr) {
          debugPrint('Receipt image upload to storage failed, proceeding without receipt: $storageErr');
        }
      }

      final api = ref.read(apiServiceProvider);
      await api.submitExpense(
        amount,
        description,
        jobId: _selectedProjectId,
        receiptUrl: receiptUrl,
      );

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense submitted successfully for manager approval!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildImagePickerPlaceholder(VoidCallback onPick) {
    if (_pickedFile != null) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              const SizedBox(height: 6),
              Text(_pickedFile!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), overflow: TextOverflow.ellipsis),
              TextButton(onPressed: onPick, child: const Text("Change Receipt Photo", style: TextStyle(fontSize: 12))),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.add_a_photo_rounded, size: 28, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('Upload Receipt Photo (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectivityProvider);
    final isOffline = conn == ConnectivityStatus.isDisconnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('EXPENSES & REIMBURSEMENTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ADD EXPENSE', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade800,
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline Mode – Expense claims will require internet connection to submit.',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _expenses.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF1E3A8A)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Expenses Claimed',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Log fuel, materials, parking or toll costs incurred during field jobs.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _expenses.length,
                              itemBuilder: (context, index) {
                                final expense = _expenses[index];
                                final statusColor = _getStatusColor(expense.status);

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.receipt_outlined, color: Color(0xFF1E3A8A), size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                expense.description,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Claimed on ${expense.date}',
                                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₹${expense.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                expense.status.toUpperCase(),
                                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
