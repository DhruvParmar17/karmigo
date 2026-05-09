import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import '../../core/app_translations.dart';
import '../../core/auth_state.dart';
import 'labour_available_jobs_screen.dart';
import 'labour_my_jobs_screen.dart';
import 'labour_profile_screen.dart';
import 'labour_earnings_screen.dart';
import 'verification/verification_wrapper.dart';

class LabourMainScreen extends StatefulWidget {
  const LabourMainScreen({super.key});

  @override
  State<LabourMainScreen> createState() => _LabourMainScreenState();
}

class _LabourMainScreenState extends State<LabourMainScreen> {
  int _currentIndex = 0;
  String _verificationStatus = "loading"; // loading, verified, unsubmitted, pending, rejected

  @override
  void initState() {
    super.initState();
    _checkVerification();
    _applyDemoBypass();
  }

  void _applyDemoBypass() {
    bool isDemoAccount = (AuthState.phone != null && AuthState.phone!.endsWith("9892593525")) || 
                        AuthState.email == "dhurvparmar8@gmail.com" || 
                        AuthState.email == "dhruvparmar8@gmail.com";
    if (isDemoAccount) {
      if (mounted) {
        setState(() {
          _verificationStatus = "verified";
        });
      }
    }
  }

  Future<void> _checkVerification() async {
    try {
      final response = await ApiService.getVerificationStatus();
      if (mounted) {
        setState(() {
          _verificationStatus = response['status'] ?? "unsubmitted";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _verificationStatus = "unsubmitted");
    } finally {
      _applyDemoBypass(); // Re-apply bypass after network call finishes
    }
  }

  void _onTabTapped(int index) {
    bool isDemoAccount = (AuthState.phone != null && AuthState.phone!.replaceAll(' ', '').endsWith("9892593525")) || 
                        AuthState.email == "dhurvparmar8@gmail.com" || 
                        AuthState.email == "dhruvparmar8@gmail.com";
    
    // ABSOLUTE BYPASS FOR DEMO ACCOUNT
    if (isDemoAccount) {
      setState(() {
        _currentIndex = index;
      });
      return;
    }

    if (index == 2 && _verificationStatus != "verified") {
       _showVerificationDialog("Access to Wallet/Earnings is restricted to verified partners.");
       return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showVerificationDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTranslations.tr("verification_required")),
        content: Text(message == "Access to Wallet/Earnings is restricted to verified partners." ? AppTranslations.tr("restricted_access") : message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppTranslations.tr("later"))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationWrapper()));
            }, 
            child: Text(AppTranslations.tr("verify_now"))
          ),
        ],
      )
    );
  }

  // Use getter to ensure fresh list on rebuilds if needed, or just non-const
  List<Widget> get _screens => const [
    LabourAvailableJobsScreen(),
    LabourMyJobsScreen(),
    LabourEarningsScreen(),
    LabourProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen to language changes
    Provider.of<LocaleProvider>(context);

    bool isDemoAccount = (AuthState.phone != null && AuthState.phone!.replaceAll(' ', '').endsWith("9892593525")) || 
                        (AuthState.email?.trim() == "dhurvparmar8@gmail.com") || 
                        (AuthState.email?.trim() == "dhruvparmar8@gmail.com");
    
    // Allow access during loading for demo account
    bool showNotVerifiedBanner = (_verificationStatus != "verified" && _verificationStatus != "loading" && !isDemoAccount);
    
    return Scaffold(
      body: Column(
        children: [
          if (showNotVerifiedBanner)
            Container(
              color: _verificationStatus == "rejected" ? Colors.red : Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _verificationStatus == "rejected" 
                          ? AppTranslations.tr("verification_rejected") 
                          : AppTranslations.tr("verification_pending"),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationWrapper()));
                      },
                      style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                      child: Text(AppTranslations.tr("verify_now")),
                    )
                  ],
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed, // Needed for 4 items
        selectedItemColor: PorterTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.work_outline),
            label: AppTranslations.tr("available_jobs"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_turned_in),
            label: AppTranslations.tr("my_jobs"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: AppTranslations.tr("earnings"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppTranslations.tr("profile"),
          ),
        ],
      ),
    );
  }
}
