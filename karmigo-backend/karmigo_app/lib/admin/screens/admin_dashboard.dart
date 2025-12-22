import 'package:flutter/material.dart';

import '../../core/app_router.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AdminCard(
                  title: 'Users',
                  subtitle: 'Manage all users',
                  icon: Icons.people,
                  onTap: () => Navigator.pushNamed(context, AppRouter.usersList),
                ),
                _AdminCard(
                  title: 'Labour',
                  subtitle: 'Onboard or update',
                  icon: Icons.handyman,
                  onTap: () => Navigator.pushNamed(context, AppRouter.labourList),
                ),
                _AdminCard(
                  title: 'Bookings',
                  subtitle: 'Track all jobs',
                  icon: Icons.event,
                  onTap: () => Navigator.pushNamed(context, AppRouter.bookingsList),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.timeline),
                    title: Text('System log ${index + 1}'),
                    subtitle: const Text('Placeholder event description'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

