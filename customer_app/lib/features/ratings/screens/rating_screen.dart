import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:customer_app/core/api/api_client.dart';
import 'package:customer_app/core/auth/auth_provider.dart';
import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/features/dashboard/providers/dashboard_provider.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const RatingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(String technicianId) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(dashboardRepositoryProvider);
      
      // We will perform POST to api/reviews
      // Wait, dashboard repo doesn't have createReview. Let's look at what we wrote in it.
      // Ah, in dashboard_repository.dart we only had address CRUD.
      // Let's add createReview to dashboard_repository.dart or make a direct POST using ApiClient inside our method.
      // Doing direct POST via ApiClient.instance is extremely clean and fast!
      
      final clientName = ref.read(authProvider).user?.name ?? 'Client';
      
      await ApiClient.instance.post(
        '/api/reviews',
        data: {
          'rating': _selectedRating,
          'comment': _commentController.text.trim(),
          'technicianId': technicianId,
          'jobId': widget.bookingId,
          'clientName': clientName,
        },
      );

      // Invalidate dashboard provider so that list is updated with rating
      ref.invalidate(dashboardDataProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your review has been submitted.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit review: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardData = ref.watch(dashboardDataProvider).value;
    final matchingBooking = dashboardData?.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => dashboardData.upcomingBookings.firstWhere(
        (b) => b.id == widget.bookingId,
        orElse: () => const MapEntry('id', null) as dynamic,
      ),
    );

    final technicianId = matchingBooking?.technicianId ?? 'dummy-technician-id';
    final technicianName = matchingBooking?.technicianName ?? 'Your Assigned Expert';
    final serviceTitle = matchingBooking?.serviceName ?? matchingBooking?.title ?? 'Service';

    return Scaffold(
      backgroundColor: AppColors.slate950,
      appBar: AppBar(
        title: const Text('Rate Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rate your experience with $technicianName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'For service: $serviceTitle',
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Visual Star Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  final isSelected = starNum <= _selectedRating;
                  return IconButton(
                    icon: Icon(
                      Icons.star_rounded,
                      color: isSelected ? Colors.amber : AppColors.slate700,
                      size: 48,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = starNum;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 32),

              const Text(
                'Review Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Share details of your experience (e.g. promptness, behavior, setup quality)...',
                ),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitReview(technicianId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
