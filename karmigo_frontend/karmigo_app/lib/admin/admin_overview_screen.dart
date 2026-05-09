import 'package:flutter/material.dart';
import 'package:karmigo_app/core/app_translations.dart';
import '../../services/api_service.dart';
import '../../widgets/language_switcher_button.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.getAdminDashboard();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error loading stats: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Extract Data mapping to New Backend Structure
    final financials = _stats['financial_overview'] as Map<String, dynamic>? ?? {};
    final jobs = _stats['job_lifecycle'] as Map<String, dynamic>? ?? {};
    final labour = _stats['labour_availability'] as Map<String, dynamic>? ?? {};
    final users = _stats['customer_activity']?['total_customers'] ?? 0;

    double safeDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr("dashboard_overview")), 
        automaticallyImplyLeading: false,
        actions: const [
          LanguageSwitcherButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // --- Financial Stats ---
               Text(AppTranslations.tr("financial_overview"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               Row(
                children: [
                   Expanded(child: _buildStatCard(AppTranslations.tr("total_collected"), "₹${safeDouble(financials['total_collected']).toStringAsFixed(0)}", Colors.green[700]!)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildStatCard(AppTranslations.tr("platform_earnings"), "₹${safeDouble(financials['platform_earnings']).toStringAsFixed(0)}", Colors.teal)),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatCard(AppTranslations.tr("pending_payouts"), "₹${safeDouble(financials['pending_payouts']).toStringAsFixed(0)}", Colors.orange[800]!),

              const SizedBox(height: 24),
              
              // --- Job Statistics ---
              Text(AppTranslations.tr("job_lifecycle"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                   _buildStatCard(AppTranslations.tr("total_jobs"), "${jobs['total_jobs'] ?? 0}", Colors.blueGrey),
                   _buildStatCard(AppTranslations.tr("jobs_today"), "${jobs['jobs_today'] ?? 0}", Colors.blue),
                   _buildStatCard(AppTranslations.tr("active_jobs"), "${jobs['active_jobs'] ?? 0}", Colors.indigo),
                   _buildStatCard(AppTranslations.tr("cancelled"), "${jobs['cancelled_jobs'] ?? 0}", Colors.redAccent),
                   _buildStatCard(AppTranslations.tr("pending"), "${jobs['pending_jobs'] ?? 0}", Colors.orange),
                   _buildStatCard(AppTranslations.tr("completed"), "${jobs['completed_jobs'] ?? 0}", Colors.green),
                ],
              ),

              const SizedBox(height: 24),

               // --- Labour Stats ---
               Text(AppTranslations.tr("labour_availability"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               Row(
                children: [
                   Expanded(child: _buildStatCard(AppTranslations.tr("registered"), "${labour['registered'] ?? 0}", Colors.grey[700]!)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildStatCard(AppTranslations.tr("verified"), "${labour['verified'] ?? 0}", Colors.blue[700]!)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildStatCard(AppTranslations.tr("available_now"), "${labour['available_now'] ?? 0}", Colors.green[700]!)),
                ],
              ),

              const SizedBox(height: 24),

              // --- Customer Activity ---
              Text(AppTranslations.tr("customer_activity"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildStatCard(AppTranslations.tr("total_customers"), "$users", Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: color
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13, 
                color: Colors.grey[700],
                fontWeight: FontWeight.w500
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

