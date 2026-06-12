import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/features/dashboard/models/dashboard_models.dart';
import 'package:customer_app/features/dashboard/providers/dashboard_provider.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  bool _isSaving = false;

  Future<void> _deleteAddress(String id) async {
    final repo = ref.read(dashboardRepositoryProvider);
    try {
      await repo.deleteAddress(id);
      ref.invalidate(dashboardDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete address: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddressDialog([UserAddress? address]) {
    final isEdit = address != null;
    final labelController = TextEditingController(text: address?.label ?? 'Home');
    final addressLineController = TextEditingController(text: address?.addressLine1 ?? '');
    final cityController = TextEditingController(text: address?.city ?? 'Bengaluru');
    final stateController = TextEditingController(text: address?.state ?? 'Karnataka');
    final pincodeController = TextEditingController(text: address?.pincode ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.slate900,
              title: Text(isEdit ? 'Edit Address' : 'Add Address', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Label (e.g. Home, Office)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressLineController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Address Line 1'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: stateController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'State'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pincodeController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pincode'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.slate400)),
                ),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setDialogState(() {
                            _isSaving = true;
                          });

                          try {
                            final repo = ref.read(dashboardRepositoryProvider);
                            final addr = UserAddress(
                              id: address?.id ?? '',
                              label: labelController.text.trim(),
                              addressLine1: addressLineController.text.trim(),
                              city: cityController.text.trim(),
                              state: stateController.text.trim(),
                              pincode: pincodeController.text.trim(),
                              latitude: address?.latitude ?? 12.9716,
                              longitude: address?.longitude ?? 77.5946,
                            );

                            if (isEdit) {
                              await repo.updateAddress(address.id, addr);
                            } else {
                              await repo.createAddress(addr);
                            }

                            ref.invalidate(dashboardDataProvider);

                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? 'Address updated' : 'Address saved')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save address: ${e.toString()}')),
                              );
                            }
                          } finally {
                            setDialogState(() {
                              _isSaving = false;
                            });
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: AppColors.slate950,
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardDataProvider.future),
          color: AppColors.emerald500,
          backgroundColor: AppColors.slate900,
          child: dashboardAsync.when(
            data: (data) => _buildAddressList(data.addresses),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald500)),
            error: (err, stack) => Center(child: Text('Error loading addresses: $err', style: const TextStyle(color: Colors.white60))),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressDialog(),
        backgroundColor: AppColors.emerald600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAddressList(List<UserAddress> addresses) {
    if (addresses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_outlined, size: 64, color: AppColors.slate600),
                const SizedBox(height: 16),
                const Text(
                  'No Saved Addresses',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add service addresses to speed up bookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate400, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return Card(
          color: AppColors.slate900,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.04)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(
              address.label.toLowerCase() == 'office' ? Icons.business_outlined : Icons.home_outlined,
              color: AppColors.emerald500,
              size: 28,
            ),
            title: Row(
              children: [
                Text(
                  address.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emerald600.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('DEFAULT', style: TextStyle(color: Colors.tealAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                '${address.addressLine1}, ${address.city}, ${address.state} - ${address.pincode}',
                style: TextStyle(color: AppColors.slate300, fontSize: 12, height: 1.4),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.slate400, size: 20),
                  onPressed: () => _showAddressDialog(address),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteAddress(address.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
