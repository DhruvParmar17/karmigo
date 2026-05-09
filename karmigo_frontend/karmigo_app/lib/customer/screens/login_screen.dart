import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../core/auth_state.dart';
import 'customer_dashboard.dart';
import '../../widgets/logo_widget.dart';
import '../../labour/screens/labour_login.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // State
  bool isPhoneLogin = true; // Default to Phone Login
  bool isOtpSent = false;
  bool isLoading = false;
  int _timerSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid phone number")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await ApiService.sendOtpCustomer(phone);
      setState(() {
        isOtpSent = true;
        isLoading = false;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Sent!")),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loginOtp() async {
    final otp = otpController.text.trim();
    final phone = phoneController.text.trim(); // Ensure we use the phone number entered

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter 4-digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.loginOtpCustomer(phone, otp);
      _handleLoginSuccess(response);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loginEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email & password")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.login(email, password);
      _handleLoginSuccess(response);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _handleLoginSuccess(Map<String, dynamic> response) {
    // Save Auth Data
    AuthState.setAuthData(
      accessToken: response['access_token'],
      userRole: response['role'],
      id: (response['user_id'] ?? response['id']).toString(),
      userEmail: response['email'],
      userPhone: response['phone'],
      userName: response['name'] ?? response['full_name'] ?? "Customer",
    );

    // Navigate
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CustomerDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const LogoWidget(),
              const SizedBox(height: 20),

              // Toggle Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Phone Login"),
                    selected: isPhoneLogin,
                    onSelected: (val) {
                      if (val) setState(() {
                         isPhoneLogin = true;
                         isOtpSent = false;
                         phoneController.clear();
                         otpController.clear();
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Email Login"),
                    selected: !isPhoneLogin,
                    onSelected: (val) {
                      if (val) setState(() => isPhoneLogin = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (isPhoneLogin) ...[
                if (!isOtpSent) ...[
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixText: "+91 ",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _sendOtp,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Send OTP"),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter OTP",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _timerSeconds == 0 ? _sendOtp : null,
                        child: Text(_timerSeconds > 0
                            ? "Resend in ${_timerSeconds}s"
                            : "Resend OTP"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isOtpSent = false;
                            otpController.clear();
                          });
                        },
                        child: const Text("Change Number"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _loginOtp,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Login"),
                    ),
                  ),
                ],
              ] else ...[
                // Email Login Form
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _loginEmail,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Login"),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              
              const Divider(),
              
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LabourLogin(),
                    ),
                  );
                },
                child: const Text("Login as Labour"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/admin/login');
                },
                child: const Text("Login as Admin"),
              ),
              
              if (!isPhoneLogin)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignupScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
