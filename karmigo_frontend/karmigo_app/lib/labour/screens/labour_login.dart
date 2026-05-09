import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../core/auth_state.dart';
import 'labour_main_screen.dart';
import '../../customer/screens/login_screen.dart';
import '../../widgets/logo_widget.dart';
// import 'verification/verification_wrapper.dart'; // To be created

class LabourLogin extends StatefulWidget {
  const LabourLogin({super.key});

  @override
  State<LabourLogin> createState() => _LabourLoginState();
}

class _LabourLoginState extends State<LabourLogin> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPhoneLogin = true; // Toggle state
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
      await ApiService.sendOtp(phone);
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
      
      // Save Auth
      await AuthState.setAuthData(
        accessToken: response['access_token'],
        userRole: response['role'],
        id: (response['labour_id'] ?? response['user_id']).toString(),
        userEmail: response['email'],
        userPhone: response['phone'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LabourMainScreen()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _loginOtp() async {
    final phone = phoneController.text.trim();
    final otp = otpController.text.trim();

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter 4-digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.loginOtp(phone, otp);

      // Save Auth
      await AuthState.setAuthData(
        accessToken: response['access_token'],
        userRole: response['role'],
        id: (response['labour_id'] ?? response['user_id']).toString(), // Prefer labour_id
        userEmail: response['email'],
        userPhone: response['phone'],
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LabourMainScreen()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Labour Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView( // Added ScrollView
          child: Column(
            children: [
              const LogoWidget(),
              const SizedBox(height: 20),

              // Toggle
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
                  Text(
                    isOtpSent ? "Enter OTP sent to +91 ${phoneController.text}" : "Login with Phone Number",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
      
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
                        builder: (_) => LoginScreen(),
                      ),
                    );
                },
                child: const Text("Not a labour? Login as customer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
