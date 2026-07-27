import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/techbes_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  
  String _selectedTab = 'email'; // 'email' or 'mobile'
  bool _rememberMe = true;
  bool _otpSent = false;
  int _otpTimer = 0;
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).login(email, password);
    if (success && mounted) {
      context.go('/');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleSendOtp() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10 || int.tryParse(mobile) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    // Simulate sending OTP as the backend primarily supports email OTP for verification
    await Future.delayed(const Duration(seconds: 1.5));
    if (mounted) {
      setState(() {
        _isSendingOtp = false;
        _otpSent = true;
        _otpTimer = 60;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully (Simulated)')),
      );
    }
  }

  void _handleVerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP')),
      );
      return;
    }
    
    // Fallback info: mobile OTP login requires active database registration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Passwordless OTP login is a mockup. Please use Email Login.'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.heroGradient,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Official TechBes Logo Header
                const Center(
                  child: TechBesLogo(
                    size: 48.0,
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Sign in to manage your IT service bookings.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tab Switcher matching the web app styling
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Slate 100
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
                  ),
                  child: Row(
                    children: [
                      // Email Tab
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 'email'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 'email' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 'email'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                  color: _selectedTab == 'email' ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Email Login',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 'email' ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Mobile OTP Tab
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 'mobile'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 'mobile' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 'mobile'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: _selectedTab == 'mobile' ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Mobile OTP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 'mobile' ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Form Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _selectedTab == 'email' 
                        ? Column(
                            key: const ValueKey('email_form'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                                  hintText: 'Enter your email',
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline, size: 18),
                                  hintText: 'Enter password',
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                          activeColor: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('Remember me', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/forgot-password'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: authState.status == AuthStatus.loading ? null : _handleLogin,
                                child: authState.status == AuthStatus.loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Sign In'),
                              ),
                            ],
                          )
                        : Column(
                            key: const ValueKey('mobile_form'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _mobileController,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number',
                                  prefixIcon: Icon(Icons.phone_android_outlined, size: 18),
                                  hintText: 'Enter 10-digit number',
                                ),
                                keyboardType: TextInputType.phone,
                                readOnly: _otpSent,
                              ),
                              if (_otpSent) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _otpController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter OTP Code',
                                    prefixIcon: Icon(Icons.security_outlined, size: 18),
                                    hintText: 'Enter 6-digit OTP',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                              const SizedBox(height: 20),
                              if (!_otpSent)
                                ElevatedButton(
                                  onPressed: _isSendingOtp ? null : _handleSendOtp,
                                  child: _isSendingOtp
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Send OTP'),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      onPressed: _handleVerifyOtp,
                                      child: const Text('Verify & Sign In'),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Didn\'t receive OTP? ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                                        TextButton(
                                          onPressed: _handleSendOtp,
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                          child: const Text('Resend OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?', style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Sign Up', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
