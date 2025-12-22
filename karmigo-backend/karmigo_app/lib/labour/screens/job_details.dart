import 'package:flutter/material.dart';

class JobDetails extends StatelessWidget {
  final String jobId;

  const JobDetails({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Job $jobId')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job information', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Description: placeholder'),
            const SizedBox(height: 8),
            const Text('Location: TBD'),
            const SizedBox(height: 8),
            const Text('Status: in-progress'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Mark Complete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Update Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

