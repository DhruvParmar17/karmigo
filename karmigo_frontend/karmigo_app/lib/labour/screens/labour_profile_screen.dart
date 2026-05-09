import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_state.dart';
import '../../core/app_translations.dart';
import '../../theme/porter_theme.dart';
import '../../customer/screens/login_screen.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import 'labour_edit_profile_screen.dart';

class LabourProfileScreen extends StatefulWidget {
  const LabourProfileScreen({super.key});

  @override
  State<LabourProfileScreen> createState() => _LabourProfileScreenState();
}

class _LabourProfileScreenState extends State<LabourProfileScreen> {
  String _verificationStatus = "loading";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
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
      _applyDemoBypass();
    }
  }

  void _applyDemoBypass() {
    bool isDemoAccount = (AuthState.phone != null && AuthState.phone!.replaceAll(' ', '').endsWith("9892593525")) || 
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

  @override
  Widget build(BuildContext context) {
    // Listen to language changes
    Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.tr("profile"))),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: PorterTheme.primaryColor),
            accountName: Text(AuthState.name?.isNotEmpty == true ? AuthState.name! : "Labour Partner"),
            accountEmail: Text(AuthState.email?.isNotEmpty == true ? AuthState.email! : (AuthState.phone ?? "No contact details")),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.engineering, color: PorterTheme.primaryColor, size: 40),
            ),
          ),
          if (_verificationStatus != "loading")
            Container(
               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
               color: _verificationStatus == 'verified' 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.orange.withOpacity(0.1),
               child: Row(
                 children: [
                   Icon(
                     _verificationStatus == 'verified' ? Icons.verified : Icons.warning_amber_rounded,
                     color: _verificationStatus == 'verified' ? Colors.green : Colors.orange,
                   ),
                   const SizedBox(width: 8),
                   Text(
                     "${AppTranslations.tr("status")}: ${AppTranslations.tr(_verificationStatus).toUpperCase()}",
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       color: _verificationStatus == 'verified' ? Colors.green[800] : Colors.orange[800]
                     ),
                   )
                 ],
               ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(AppTranslations.tr("edit_profile")),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const LabourEditProfileScreen()),
               ).then((_) => setState((){}));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blue),
            title: Text(AppTranslations.tr("language")),
            trailing: Consumer<LocaleProvider>(
              builder: (context, provider, child) {
                return DropdownButton<Locale>(
                  value: provider.locale,
                  onChanged: (Locale? newLocale) {
                    if (newLocale != null) {
                      provider.setLocale(newLocale);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: Locale('en'), child: Text("English")),
                    DropdownMenuItem(value: Locale('hi'), child: Text("हिंदी")),
                    DropdownMenuItem(value: Locale('mr'), child: Text("मराठी")),
                  ],
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(AppTranslations.tr("logout"), style: const TextStyle(color: Colors.red)),
            onTap: () {
              AuthState.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
