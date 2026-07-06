import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/services/firebase_streams.dart';
import '../../../core/utils/pump_log_parser.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../../../features/firebase_data/models/farm_payload.dart';
import 'widgets/pump_log_widgets.dart';

class LogsHistoryPage extends StatelessWidget {
  const LogsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل نظام الأحداث'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {}, // StreamBuilder handles this
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'حذف الكل',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('حذف كل السجلات'),
                  content: const Text(
                    'هل تريد حذف جميع السجلات نهائياً؟ لا يمكن التراجع.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              final SnackBar loading = SnackBar(
                content: const Text('جارٍ حذف السجلات...'),
                duration: const Duration(days: 1),
              );
              scaffoldMessenger.showSnackBar(loading);
              try {
                await FirebaseDatabase.instance
                    .ref(FarmPayload.logsPath)
                    .remove();
                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('تم حذف السجلات.')),
                );
              } catch (e) {
                scaffoldMessenger.hideCurrentSnackBar();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('فشل حذف السجلات: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: AppRuntimeConfig.strongAlertMode,
        builder: (context, isStrongAlert, _) {
          return StreamBuilder<DatabaseEvent>(
            initialData: FirebaseStreams.lastLogsEvent,
            stream: FirebaseStreams.logsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('فشل تحميل السجلات: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const Center(child: Text('لا توجد سجلات.'));
              }
              final List<PumpLogEntry> logs = PumpLogParser.parseLogsNode(
                snapshot.data!.snapshot.value,
              );
              if (logs.isEmpty) {
                return const Center(child: Text('لا توجد سجلات.'));
              }
              return PaginatedListView(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final PumpLogEntry log = logs[index];
                  return Dismissible(
                    key: Key(log.dbPath ?? index.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(Icons.delete_outline, color: Colors.red[700]),
                    ),
                    confirmDismiss: (direction) async {
                      final bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('حذف السجل'),
                          content: const Text(
                            'هل تريد حذف هذا السجل نهائياً؟ لا يمكن التراجع.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );
                      return confirmed == true;
                    },
                    onDismissed: (direction) async {
                      if (log.dbPath == null) return;
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        await FirebaseDatabase.instance
                            .ref(log.dbPath!)
                            .remove();
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('تم حذف السجل.')),
                        );
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('فشل حذف السجل: $e')),
                        );
                      }
                    },
                    child: PumpLogEntryCard(
                      log: log,
                      highlightDisease: isStrongAlert,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
