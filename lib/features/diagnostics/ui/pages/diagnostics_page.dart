import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_smart_agriculture_system/features/dashboard/data/models/farm_payload_model.dart';
import 'package:flutter_smart_agriculture_system/features/dashboard/ui/bloc/dashboard_bloc.dart';
import 'package:flutter_smart_agriculture_system/features/dashboard/ui/bloc/dashboard_state.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Cloud Diagnostics'),
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: BlocConsumer<DashboardCubit, DashboardState>(
        listenWhen: (DashboardState previous, DashboardState current) {
          return previous.message != current.message && current.message != null;
        },
        listener: (BuildContext context, DashboardState state) {
          final String? message = state.message;
          if (message == null || message.isEmpty) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (BuildContext context, DashboardState state) {
          final cubit = context.read<DashboardCubit>();
          final isLoading = state.status == DashboardStatus.loading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(),
                const SizedBox(height: 24),
                _DataPathCard(path: FarmPayload.rootPath),
                const SizedBox(height: 12),
                const Text(
                  '⚠️ WARNING: Seeding sample data will OVERWRITE your entire database structure. This action is irreversible.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _ActionCard(
                  title: 'Data Initialization',
                  subtitle: 'Reset or seed the database with sample values',
                  icon: Icons.storage_rounded,
                  onPressed: isLoading ? null : cubit.writeSampleData,
                  label: 'Seed Sample Data',
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                _ActionCard(
                  title: 'Notification System',
                  subtitle: 'Push one disease alert to test sync',
                  icon: Icons.notifications_active_rounded,
                  onPressed: isLoading ? null : cubit.pushTestNotification,
                  label: 'Push Test Alert',
                  color: const Color(0xFFD32F2F),
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                _ActionCard(
                  title: 'Sensor Calibration',
                  subtitle: 'Read raw nitrogen levels once',
                  icon: Icons.shutter_speed_rounded,
                  onPressed: isLoading ? null : cubit.readNitrogenOnce,
                  label: 'Fetch N-Level',
                  color: const Color(0xFF2E7D32),
                  isLoading: isLoading,
                ),
                if (state.nitrogen != null) ...[
                  const SizedBox(height: 20),
                  _ResultDisplay(value: state.nitrogen.toString()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cloud Console',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage Realtime Database connectivity and testing.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ],
    );
  }
}

class _DataPathCard extends StatelessWidget {
  const _DataPathCard({required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Root Path: $path',
              style: const TextStyle(
                color: Colors.blue,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.color = Colors.white24,
    required this.isLoading,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final String label;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isSpecial = color != Colors.white24;
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSpecial ? color : Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isSpecial ? color : Colors.white10,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onPressed,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultDisplay extends StatelessWidget {
  const _ResultDisplay({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1B5E20).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
          const SizedBox(height: 12),
          const Text(
            'LATEST NITROGEN READ',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
