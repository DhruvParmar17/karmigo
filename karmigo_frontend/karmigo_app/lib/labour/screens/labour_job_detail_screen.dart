import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:slide_to_act/slide_to_act.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import 'labour_payment_collection_screen.dart';
import '../../core/app_translations.dart';
import '../../providers/locale_provider.dart';

class LabourJobDetailScreen extends StatefulWidget {
  final dynamic job;
  const LabourJobDetailScreen({super.key, required this.job});

  @override
  State<LabourJobDetailScreen> createState() => _LabourJobDetailScreenState();
}

class _LabourJobDetailScreenState extends State<LabourJobDetailScreen> {
  late dynamic _job;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      if (status == 'assigned') {
        // Special case for accept, uses assign endpoint
        await ApiService.assignJobToLabour(_job['id'].toString());
      } else {
         // Generic status update
         await ApiService.updateJobStatus(jobId: _job['id'].toString(), status: status);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.tr("status_updated"))),
      );
      
      Navigator.pop(context, true); // Return true to trigger refresh

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openMap() async {
    // Assuming lat/lng or address
    final query = Uri.encodeComponent(_job['location'] ?? '');
    final googleUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Payment Logic
    final langCode = Provider.of<LocaleProvider>(context).locale.languageCode;

    final double? earning = (_job['per_labour_earning'] ?? _job['per_labour_net']) != null 
        ? ((_job['per_labour_earning'] ?? _job['per_labour_net']) as num).toDouble() 
        : null;
    final String earningText = earning != null ? "₹${earning.toStringAsFixed(0)}" : "Calculating...";

    final String status = _job['order_status'].toString().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Map Placeholder
                   Container(
                     height: 200,
                     width: double.infinity,
                     color: Colors.grey[300],
                     child: Stack(
                       children: [
                         const Center(child: Icon(Icons.map, size: 50, color: Colors.grey)),
                         Positioned(
                           bottom: 16,
                           right: 16,
                           child: FloatingActionButton.extended(
                             onPressed: _openMap,
                             icon: const Icon(Icons.directions),
                             label: Text(AppTranslations.tr("open_maps")),
                             backgroundColor: Colors.blue,
                             heroTag: "map_btn",
                           ),
                         )
                       ],
                     ),
                   ),
                   
                   Padding(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           _translate(_job['title'] ?? "Job", langCode),
                           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 8),
                         Row(
                           children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _getStatusColor(status)),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                                ),
                              ),
                           ],
                         ),
                         const SizedBox(height: 16),
                         
                         _buildDetailRow(Icons.location_on, "Location", _job['location'] ?? "Unknown"),
                         const Divider(height: 24),
                         
                         // Earnings
                         Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.green.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: Colors.green.shade200)
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(AppTranslations.tr("net_earning"), style: TextStyle(color: Colors.green[800])),
                                   Text(earningText, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800])),
                                 ],
                               ),
                               const Icon(Icons.account_balance_wallet, size: 32, color: Colors.green),
                             ],
                           ),
                         ),
                         const SizedBox(height: 24),

                         const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                          Text(
                            _translate(_job['description'] ?? "No description provided.", langCode),
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                         
                         const SizedBox(height: 24),
                         _buildDetailRow(Icons.group, AppTranslations.tr("labours_required"), "${_job['required_labours'] ?? 1}"),
                         
                       ],
                     ),
                   )
                ],
              ),
            ),
          ),
          
          // Bottom Action Bar
          _buildBottomAction(status),
        ],
      ),
    );
  }

  Widget _buildBottomAction(String status) {
    String? btnLabel;
    String? actionStatus;
    Color btnColor = PorterTheme.primaryColor;
    
    // Lifecycle Logic
    if (status == 'pending') {
      btnLabel = AppTranslations.tr("accept");
      actionStatus = 'assigned';
    } else if (status == 'assigned') {
      btnLabel = AppTranslations.tr("on_the_way");
      actionStatus = 'on_the_way';
    } else if (status == 'on_the_way') {
      btnLabel = AppTranslations.tr("reached");
      actionStatus = 'reached';
    } else if (status == 'reached') {
      btnLabel = AppTranslations.tr("start_job");
      actionStatus = 'started';
    } else if (status == 'started') {
      btnLabel = AppTranslations.tr("complete_job");
      actionStatus = 'completed';
      btnColor = Colors.green;
    } 

    if (btnLabel == null) return const SizedBox.shrink(); // Completed or Cancelled

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))
        ]
      ),
      child: actionStatus == 'completed'
        ? SlideAction(
            text: btnLabel.toUpperCase(),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            outerColor: Colors.green,
            innerColor: Colors.white,
            sliderButtonIcon: const Icon(Icons.check, color: Colors.green),
            sliderRotate: false,
            elevation: 2,
            onSubmit: () async {
              final double earning = (_job['per_labour_earning'] ?? _job['per_labour_net'] ?? 0.0) is String ? double.tryParse((_job['per_labour_earning'] ?? _job['per_labour_net']).toString()) ?? 0.0 : ((_job['per_labour_earning'] ?? _job['per_labour_net'] ?? 0.0) as num).toDouble();
              final double finalCollectAmount = (_job['total_amount'] ?? 0.0) is String ? double.tryParse(_job['total_amount'].toString()) ?? earning : ((_job['total_amount'] ?? earning) as num).toDouble();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LabourPaymentCollectionScreen(
                    jobId: _job['id'].toString(),
                    amountToCollect: finalCollectAmount,
                  )
                )
              );
              return null;
            },
          )
        : SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _updateStatus(actionStatus!),
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading 
             ? const CircularProgressIndicator(color: Colors.white)
             : Text(btnLabel.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        )
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'on_the_way': return Colors.indigo;
      case 'reached': return Colors.purple;
      case 'started': return Colors.deepOrange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _translate(String text, String langCode) {
    if (langCode == 'en') return text;
    
    // Simple dictionary for demonstration - "Controlled Language Translation"
    // This allows key terms to be translated without a full API dependency.
    Map<String, String> dictionary = {};
    
    if (langCode == 'hi') {
      dictionary = {
        'Lift': 'लिफ्ट', 'lift': 'लिफ्ट',
        'Floor': 'मंज़िल', 'floor': 'मंज़िल',
        'Third': 'तीसरी', 'third': 'तीसरी',
        'No': 'नहीं', 'no': 'नहीं',
        'Not': 'नहीं', 'not': 'नहीं',
        'Available': 'है', 'available': 'है',
        'Labour': 'मज़दूर', 'labour': 'मज़दूर',
        'Shifting': 'शिफ्टिंग', 'shifting': 'शिफ्टिंग',
        'Loading': 'लोडिंग', 'loading': 'लोडिंग',
        'Unloading': 'अनलोडिंग', 'unloading': 'अनलोडिंग',
        'Construction': 'निर्माण', 'construction': 'निर्माण',
        'Help': 'मदद', 'help': 'मदद',
        'Urgent': 'ज़रूरी', 'urgent': 'ज़रूरी',
        'Work': 'काम', 'work': 'काम',
        'Problem': 'दिक्कत', 'problem': 'दिक्कत',
        'Time': 'समय', 'time': 'समय',
      };
    } else if (langCode == 'mr') {
       dictionary = {
        'Lift': 'लिफ्ट', 'lift': 'लिफ्ट',
        'Floor': 'मजला', 'floor': 'मजला',
        'Third': 'तिसरा', 'third': 'तिसरा',
        'No': 'नाही', 'no': 'नाही',
        'Not': 'नाही', 'not': 'नाही',
        'Available': 'आहे', 'available': 'आहे',
        'Labour': 'कामगार', 'labour': 'कामगार',
        'Shifting': 'शिफ्टिंग', 'shifting': 'शिफ्टिंग',
        'Loading': 'लोडिंग', 'loading': 'लोडिंग',
        'Unloading': 'उतरवणे', 'unloading': 'उतरवणे',
        'Construction': 'बांधकाम', 'construction': 'बांधकाम',
        'Help': 'मदत', 'help': 'मदत',
        'Urgent': 'तातडीचे', 'urgent': 'तातडीचे',
        'Work': 'काम', 'work': 'काम',
      };
    }

    String translated = text;
    // Basic word replacement strategy
    dictionary.forEach((key, value) {
       // Replace whole words ideally, but simple replaceAll is okay for this scope
       translated = translated.replaceAll(RegExp(r'\b' + key + r'\b', caseSensitive: false), value);
    });

    return translated;
  }
}
