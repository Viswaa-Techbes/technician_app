import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../repositories/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/techbes_logo.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;

  void _handleVerify(Map<String, dynamic> extra) async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid OTP')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final email = extra['email'] as String;
      // 1. Verify OTP
      final verifyRes = await ref.read(authRepositoryProvider).verifyOtp(email, otp);
      if (verifyRes['success'] == true && verifyRes['data']?['emailVerificationToken'] != null) {
        final token = verifyRes['data']['emailVerificationToken'] as String;

        // 2. Register
        if (mounted) {
          final success = await ref.read(authProvider.notifier).register(
                name: extra['name'],
                email: email,
                password: extra['password'],
                phone: extra['phone'],
                token: token,
              );
          if (success && mounted) {
            context.go('/');
          } else if (mounted) {
            final error = ref.read(authProvider).errorMessage ?? 'Registration failed';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(verifyRes['message'] ?? 'Invalid OTP code')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read parameters passed in extra
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: AppTheme.heroGradient,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: TechBesLogo(
                    size: 44.0,
                    fontSize: 22.0,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Enter Verification Code',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                        ),
                    const SizedBox(height: 8),
                    Text(
                      'A verification OTP code was sent to ${extra['email'] ?? 'your email'}. Enter it below to complete signup.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'OTP Code',
                        prefixIcon: Icon(Icons.security_outlined, size: 20),
                        hintText: 'Enter 6-digit OTP',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : () => _handleVerify(extra),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify & Create Account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
