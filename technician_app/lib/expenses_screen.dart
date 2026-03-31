import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'models.dart';
import 'widgets.dart';
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
              const SizedBox(height: 32),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Category / Purpose',
                  hintText: 'e.g. Fuel, Equipment',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 20),
              _buildProjectDropdown(setModalState),
              const SizedBox(height: 24),
              _buildImagePickerPlaceholder(() async {
                final result = await FilePicker.platform.pickFiles(type: FileType.image);
                if (result != null) {
                  setModalState(() => _pickedFile = result.files.first);
                }
              }),
              const SizedBox(height: 40),
              _isUploading 
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    label: 'CONFIRM & SAVE',
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
    final session = ref.read(authProvider);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects')
          .where('technicianId', isEqualTo: session?.id)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedProjectId,
          decoration: InputDecoration(
            labelText: 'Link to Project',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          items: docs.map((d) => DropdownMenuItem(
            value: d.id,
            child: Text(d['serviceName'] ?? 'Unnamed Project', style: const TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: (val) => setModalState(() => _selectedProjectId = val),
        );
      },
    );
  }

  Future<void> _saveExpense(BuildContext context) async {
    if (_amountController.text.isEmpty || _descController.text.isEmpty) return;
    
    setState(() => _isUploading = true);
    try {
      final session = ref.read(authProvider);
      String? downloadUrl;
      
      if (_pickedFile != null && _pickedFile!.path != null) {
        final ref = FirebaseStorage.instance.ref().child('receipts/${DateTime.now().millisecondsSinceEpoch}');
        await ref.putFile(File(_pickedFile!.path!));
        downloadUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('expenses').add({
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'description': _descController.text,
        'receiptUrl': downloadUrl,
        'projectId': _selectedProjectId,
        'technicianId': session?.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildImagePickerPlaceholder(VoidCallback onPick) {
    if (_pickedFile != null) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2563EB), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 32),
              const SizedBox(height: 8),
              Text(_pickedFile!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              TextButton(onPressed: onPick, child: const Text("Change Photo")),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.add_a_photo_rounded, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Upload Receipt Photo', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('EXPENSES')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('expenses')
            .where('technicianId', isEqualTo: session?.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No expenses logged yet."));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              final expense = Expense(
                id: docs[index].id,
                description: d['description'] ?? '',
                amount: (d['amount'] ?? 0.0).toDouble(),
                date: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : 'Just now',
                status: d['status'] ?? 'pending',
                receiptUrl: d['receiptUrl'],
                projectId: d['projectId'],
                technicianId: d['technicianId'],
              );
              return _buildProductionExpenseCard(expense, index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("NEW EXPENSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildProductionExpenseCard(Expense expense, int index) {
    Color statusColor = const Color(0xFFF59E0B);
    if (expense.status == 'approved') statusColor = const Color(0xFF2563EB);
    if (expense.status == 'paid') statusColor = const Color(0xFF10B981);
    if (expense.status == 'rejected') statusColor = const Color(0xFFF43F5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.receipt_rounded, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(expense.date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(expense.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
