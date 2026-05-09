import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTranslations {
  static const String _kLanguageKey = "app_language";
  static String currentLanguage = "en";

  /// Initialize and load saved language
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    currentLanguage = prefs.getString(_kLanguageKey) ?? "en";
    languageNotifier.value = currentLanguage;
  }

  static final ValueNotifier<String> languageNotifier = ValueNotifier("en");

  /// Change language and save preference
  static Future<void> setLanguage(String langCode) async {
    if (!['en', 'hi', 'mr'].contains(langCode)) return;
    currentLanguage = langCode;
    languageNotifier.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, langCode);
  }

  /// Get translated string
  static String tr(String key) {
    if (!_localizedValues.containsKey(key)) return key;
    return _localizedValues[key]?[currentLanguage] ?? key;
  }

  // =========================
  // TRANSLATION DATA
  // =========================
  static const Map<String, Map<String, String>> _localizedValues = {
    // App Entry
    "select_language": {
      "en": "Select Language",
      "hi": "भाषा चुनें",
      "mr": "भाषा निवडा"
    },
    "continue": {
      "en": "Continue",
      "hi": "आगे बढ़ें",
      "mr": "पुढे जा"
    },
    
    // Auth
    "login_customer": {
      "en": "Customer Login",
      "hi": "ग्राहक लॉगिन",
      "mr": "ग्राहक लॉगिन"
    },
    "login_labour": {
      "en": "Login as Labour",
      "hi": "लेबर लॉगिन",
      "mr": "कामगार लॉगिन"
    },
    "login_admin": {
      "en": "Login as Admin",
      "hi": "एडमिन लॉगिन",
      "mr": "अडमिन लॉगिन"
    },

    // Customer Home
    "book_labour": {
      "en": "Book Labour",
      "hi": "लेबर बुक करें",
      "mr": "कामगार बुक करा"
    },
    "choose_work_type": {
      "en": "Choose work type & number of labours",
      "hi": "काम का प्रकार और लेबर संख्या चुनें",
      "mr": "कामाचा प्रकार आणि कामगार संख्या निवडा"
    },

    // Work Types
    "shifting": {"en": "Shifting", "hi": "शिफ्टिंग", "mr": "शिफ्टिंग"},
    "loading": {"en": "Loading", "hi": "लोडिंग", "mr": "लोडिंग"},
    "unloading": {"en": "Unloading", "hi": "अनलोडिंग", "mr": "अनलोडिंग"},
    "construction": {"en": "Construction", "hi": "निर्माण", "mr": "बांधकाम"},
    "stairs": {"en": "Stair Climbing", "hi": "सीढ़ियां चढ़ना", "mr": "पायऱ्या चढणे"},
    "heavy": {"en": "Heavy Item", "hi": "भारी सामान", "mr": "जड वस्तू"},
    "warehouse": {"en": "Warehouse", "hi": "गोदाम", "mr": "गोदाम"},
    "office": {"en": "Office Shifting", "hi": "ऑफिस शिफ्टिंग", "mr": "ऑफिस शिफ्टिंग"},
    "furniture": {"en": "Furniture", "hi": "फर्नीचर", "mr": "फर्निचर"},
    "event": {"en": "Event Setup", "hi": "इवेंट सेटअप", "mr": "इव्हेंट सेटअप"},
    
    // Common
    "create_job": {"en": "Create Job", "hi": "जॉब पोस्ट करें", "mr": "जॉब पोस्ट करा"},
    "my_requests": {"en": "My Requests", "hi": "मेरे अनुरोध", "mr": "माझ्या विनंत्या"},
    "account": {"en": "Account", "hi": "प्रोफाइल", "mr": "प्रोफाइल"},
    "logout": {"en": "Logout", "hi": "लॉग आउट", "mr": "लॉग आउट"},

    // Labour Dashboard
    "available_jobs": {"en": "Available Jobs", "hi": "उपलब्ध नौकरियां", "mr": "उपलब्ध कामे"},
    "my_jobs": {"en": "My Jobs", "hi": "मेरी नौकरियां", "mr": "माझी कामे"},
    "earnings": {"en": "Earnings", "hi": "कमाई", "mr": "कमाई"},
    "profile": {"en": "Profile", "hi": "प्रोफ़ाइल", "mr": "प्रोफाइल"},
    "net_earning": {"en": "Net Earning", "hi": "आपकी कमाई", "mr": "तुमची कमाई"},
    "slots": {"en": "Slots", "hi": "खाली जगह", "mr": "जागा"},
    "labours_required": {"en": "Labours Required", "hi": "लेबर की आवश्यकता", "mr": "कामगारांची आवश्यकता"},
    "open_maps": {"en": "Open in Maps", "hi": "मैप में खोलें", "mr": "नकाशा उघडा"},
    "status_updated": {"en": "Status Updated", "hi": "स्थिति अपडेट की गई", "mr": "स्थिती अपडेट केली"},
    
    // Verification
    "verification_required": {"en": "Verification Required", "hi": "सत्यापन आवश्यक है", "mr": "पडताळणी आवश्यक"},
    "verify_now": {"en": "Verify Now", "hi": "अभी सत्यापित करें", "mr": "आत्ता पडताळणी करा"},
    "later": {"en": "Later", "hi": "बाद में", "mr": "नंतर"},
    "verification_pending": {"en": "Complete verification to accept jobs.", "hi": "काम स्वीकार करने के लिए सत्यापन पूरा करें।", "mr": "कामे स्वीकारण्यासाठी पडताळणी पूर्ण करा."},
    "verification_rejected": {"en": "Verification Rejected. Update details.", "hi": "सत्यापन अस्वीकृत। विवरण अपडेट करें।", "mr": "पडताळणी नाकारली. माहिती अपडेट करा."},
    "restricted_access": {"en": "Access to Wallet/Earnings is restricted to verified partners.", "hi": "वॉलेट/कमाई तक पहुंच केवल सत्यापित भागीदारों के लिए है।", "mr": "वॉलेट/कमाई फक्त सत्यापित भागीदारांसाठी उपलब्ध आहे."},

    // Admin Dashboard
    "dashboard_overview": {"en": "Dashboard Overview", "hi": "डैशबोर्ड अवलोकन", "mr": "डॅशबोर्ड विहंगावलोकन"},
    "financial_overview": {"en": "Financial Overview", "hi": "वित्तीय अवलोकन", "mr": "वित्तीय विहंगावलोकन"},
    "total_collected": {"en": "Total Collected", "hi": "कुल संकलित", "mr": "एकूण गोळा केलेले"},
    "platform_earnings": {"en": "Platform Earnings", "hi": "प्लेटफॉर्म की कमाई", "mr": "प्लॅटफॉर्म कमाई"},
    "pending_payouts": {"en": "Pending Labour Payouts", "hi": "लंबित लेबर भुगतान", "mr": "प्रलंबित कामगार पेआउट"},
    "job_lifecycle": {"en": "Job Lifecycle (Today)", "hi": "जॉब लाइफसायकल (आज)", "mr": "जॉब लाइफसायकल (आज)"},
    "total_jobs": {"en": "Total Jobs", "hi": "कुल नौकरियां", "mr": "एकूण कामे"},
    "jobs_today": {"en": "Jobs Today", "hi": "आज की नौकरियां", "mr": "आजची कामे"},
    "active_jobs": {"en": "Active Jobs", "hi": "सक्रिय नौकरियां", "mr": "सक्रिय कामे"},
    "cancelled": {"en": "Cancelled", "hi": "रद्द", "mr": "रद्द"},
    "pending": {"en": "Pending", "hi": "लंबित", "mr": "प्रलंबित"},
    "labour_availability": {"en": "Labour Availability", "hi": "लेबर उपलब्धता", "mr": "कामगार उपलब्धता"},
    "registered": {"en": "Registered", "hi": "पंजीकृत", "mr": "नोंदणीकृत"},
    "verified": {"en": "Verified", "hi": "सत्यापित", "mr": "सत्यापित"},
    "available_now": {"en": "Available Now", "hi": "अभी उपलब्ध", "mr": "आता उपलब्ध"},
    "customer_activity": {"en": "Customer Activity", "hi": "ग्राहक गतिविधि", "mr": "ग्राहक क्रियाकलाप"},
    "total_customers": {"en": "Total Customers", "hi": "कुल ग्राहक", "mr": "एकूण ग्राहक"},
    "manage_labour": {"en": "Manage Labour", "hi": "लेबर प्रबंधित करें", "mr": "कामगार व्यवस्थापित करा"},

    // Lifecycle
    "accept": {"en": "ACCEPT", "hi": "स्वीकारें", "mr": "स्वीकारा"},
    "on_the_way": {"en": "ON THE WAY", "hi": "रास्ते में हूँ", "mr": "वाटेत आहे"},
    "reached": {"en": "REACHED", "hi": "पहुंच गया", "mr": "पोहोचलो"},
    "start_job": {"en": "START JOB", "hi": "काम शुरू करें", "mr": "काम सुरू करा"},
    "complete_job": {"en": "COMPLETE JOB", "hi": "काम पूरा करें", "mr": "काम पूर्ण करा"},
    "completed": {"en": "Completed", "hi": "पूरा हुआ", "mr": "पूर्ण झाले"},
    "ongoing": {"en": "Ongoing", "hi": "चल रहा है", "mr": "चालू आहे"},
    "history": {"en": "History", "hi": "इतिहास", "mr": "इतिहास"},
    "status": {"en": "Status", "hi": "स्थिति", "mr": "स्थिती"},
    "edit_profile": {"en": "Edit Profile", "hi": "प्रोफाइल बदलें", "mr": "प्रोफाइल बदला"},
    "unsubmitted": {"en": "Unsubmitted", "hi": "बिना जमा", "mr": "सबमिट केलेले नाही"},
    "rejected": {"en": "Rejected", "hi": "अस्वीकृत", "mr": "नाकारले"},
  };
}
