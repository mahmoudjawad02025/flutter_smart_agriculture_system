import 'package:firebase_database/firebase_database.dart';
import '../../../core/services/firebase_streams.dart';
import '../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';

import 'logs_history_page.dart';

// use centralized app icon from AppStrings

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final Stream<DatabaseEvent> _dataStream;

  @override
  void initState() {
    super.initState();
    _dataStream = FirebaseStreams.rootStream;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<DatabaseEvent>(
        stream: _dataStream,
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return _MessageView(
              icon: Icons.error_outline,
              title: 'فشل تحميل لوحة التحكم',
              subtitle: '${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dynamic raw = snapshot.data!.snapshot.value;
          if (raw is! Map) {
            return const _MessageView(
              icon: Icons.cloud_off_outlined,
              title: 'لا توجد بيانات Firebase بعد',
              subtitle: 'استخدم علامة Firebase لكتابة بيانات تجريبية أولًا.',
            );
          }

          final Map<String, dynamic> data = _toMap(raw);
          final Map<String, dynamic> live = _toMap(data['live']);
          final Map<String, dynamic> sensors = _toMap(data['sensors']);
          final Map<String, dynamic> source = live.isNotEmpty ? live : sensors;
          final Map<String, dynamic> leaf = _toMap(data['leaf']);

          final String rawTime = '${source['time'] ?? '-'}';
          final String time = _formatDashboardTime(rawTime);
          final String leafStatus = _displayLeafStatus(
            '${leaf['status'] ?? '-'}',
          );
          final bool needsFix = leaf['needs_fix'] == true;
          final String reuploadAt = '${leaf['reupload_at'] ?? ''}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _HeaderCard(
                time: time,
                leafStatus: leafStatus,
                needsFix: needsFix,
                reuploadAt: reuploadAt,
              ),
              const SizedBox(height: 14),
              const _DailyAverageCard(),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: <Widget>[
                  _MetricCard(
                    title: 'رطوبة التربة',
                    value: '${source['moist'] ?? '-'}%',
                    icon: Icons.water_drop_outlined,
                  ),
                  _MetricCard(
                    title: 'درجة الحرارة',
                    value: '${source['temp'] ?? '-'}°م',
                    icon: Icons.thermostat_outlined,
                  ),
                  _MetricCard(
                    title: 'الرطوبة',
                    value: '${source['hum'] ?? '-'}%',
                    icon: Icons.air_outlined,
                  ),
                  _MetricCard(
                    title: 'النيتروجين (N)',
                    value: '${source['n'] ?? '-'}',
                    icon: Icons.grass_outlined,
                  ),
                  _MetricCard(
                    title: 'الفوسفور (P)',
                    value: '${source['p'] ?? '-'}',
                    icon: Icons.spa_outlined,
                  ),
                  _MetricCard(
                    title: 'البوتاسيوم (K)',
                    value: '${source['k'] ?? '-'}',
                    icon: Icons.eco_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PumpsSnapshot(database: FirebaseDatabase.instance),
              const SizedBox(height: 14),
              _LogsSnapshot(database: FirebaseDatabase.instance),
            ],
          );
        },
      ),
    );
  }
}

class _LogsSnapshot extends StatelessWidget {
  const _LogsSnapshot({required this.database});
  final FirebaseDatabase database;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseStreams.logsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const SizedBox.shrink();
        }

        final Map<String, dynamic> logsData = _toMap(
          snapshot.data?.snapshot.value,
        );

        final List<_LogItem> allLogs = [];

        void addIfPumpLog(
          Map<String, dynamic> data, {
          bool isAuto = false,
          bool isManual = false,
        }) {
          if (data.isEmpty) return;
          if (data['debug'] == true) return;

          final String action = data['action']?.toString().toUpperCase() ?? '';
          final String pump = data['pump']?.toString() ?? '';
          if (action != 'ON' && action != 'OFF') return;

          final Map<String, dynamic> sensorsMap = _toMap(data['sensors']);
          final String? moist = sensorsMap['moist']?.toString();
          final String? temp = sensorsMap['temp']?.toString();
          final String? hum = sensorsMap['hum']?.toString();
          final String? n = sensorsMap['n']?.toString();
          final String? p = sensorsMap['p']?.toString();
          final String? k = sensorsMap['k']?.toString();
          final bool hasSensors = sensorsMap.isNotEmpty;

          String? leafStatus;
          if (data.containsKey('leaf_status')) {
            leafStatus = data['leaf_status']?.toString();
          } else if (data.containsKey('leaf')) {
            final dynamic leafVal = data['leaf'];
            if (leafVal is String) leafStatus = leafVal;
            if (leafVal is Map)
              leafStatus = _toMap(leafVal)['status']?.toString();
          }

          final String lowPump = pump.toLowerCase();
          IconData icon;
          String title;

          if (lowPump.contains('water') || pump.toUpperCase() == 'WATER') {
            icon = Icons.water_drop_outlined;
            title =
                '${isAuto ? 'ري تلقائي' : 'ري يدوي'} : ${AppStrings.displayAction(action)}';
          } else if (lowPump.contains('fert') ||
              pump.toUpperCase() == 'FERTILIZER') {
            icon = Icons.science_outlined;
            title =
                '${AppStrings.displayPumpName(pump)} ${isAuto ? 'تلقائي' : 'يدوي'} : ${AppStrings.displayAction(action)}';
          } else {
            icon = Icons.touch_app_outlined;
            title =
                '${AppStrings.displayPumpName(pump)} ${isAuto ? 'تلقائي' : 'يدوي'} : ${AppStrings.displayAction(action)}';
          }

          allLogs.add(
            _LogItem(
              time: _parseDate(data['time']),
              title: title,
              subtitle: '',
              icon: icon,
              isManual: isManual,
              hasSensors: hasSensors,
              n: n,
              p: p,
              k: k,
              moist: moist,
              temp: temp,
              hum: hum,
              leafStatus: leafStatus,
            ),
          );
        }

        // Auto logs
        final Map<String, dynamic> autoLogs = _toMap(logsData['auto_logs']);
        autoLogs.forEach((kind, entries) {
          final Map<String, dynamic> kindLogs = _toMap(entries);
          kindLogs.forEach((key, val) {
            final Map<String, dynamic> data = _toMap(val);
            addIfPumpLog(data, isAuto: true);
          });
        });

        // Manual logs
        final Map<String, dynamic> manualLogs = _toMap(logsData['manual_logs']);
        manualLogs.forEach((key, val) {
          final Map<String, dynamic> data = _toMap(val);
          addIfPumpLog(data, isManual: true);
        });

        allLogs.sort((a, b) => b.time.compareTo(a.time));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'النشاط الأخير',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.history_outlined,
                        size: 20,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const LogsHistoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (allLogs.isEmpty)
                  const Text(
                    'لا توجد سجلات.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Column(
                    children: allLogs.take(5).map((log) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          radius: 18,
                          child: Icon(
                            log.icon,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          log.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle:
                            (log.hasSensors ||
                                (log.leafStatus != null &&
                                    log.leafStatus!.isNotEmpty) ||
                                (log.subtitle != null &&
                                    log.subtitle!.isNotEmpty))
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (log.hasSensors)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            _MiniMetric(
                                              Icons.water_drop,
                                              '${log.moist ?? '-'}%',
                                            ),
                                            _MiniMetric(
                                              Icons.thermostat,
                                              '${log.temp ?? '-'}°م',
                                            ),
                                            _MiniMetric(
                                              Icons.air,
                                              '${log.hum ?? '-'}%',
                                            ),
                                            _MiniMetric(
                                              Icons.eco,
                                              '${log.n ?? '-'}',
                                            ),
                                            _MiniMetric(
                                              Icons.eco,
                                              '${log.p ?? '-'}',
                                            ),
                                            _MiniMetric(
                                              Icons.eco,
                                              '${log.k ?? '-'}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (log.subtitle != null &&
                                      log.subtitle!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        log.subtitle!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'الحالة: ${log.leafStatus != null ? AppStrings.displayLeafStatus(log.leafStatus!) : 'غير معروف'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                        trailing: Text(
                          '${log.time.day}/${log.time.month}/${log.time.year}\n${log.time.hour}:${log.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime _parseDate(dynamic val) {
    if (val is String) {
      try {
        return DateTime.parse(val).toLocal();
      } catch (_) {}
    }
    return DateTime.now();
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.icon, this.value);
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogItem {
  final DateTime time;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isManual;
  final bool hasSensors;
  final String? n, p, k, moist, temp, hum;
  final String? leafStatus;

  _LogItem({
    required this.time,
    required this.title,
    this.subtitle,
    required this.icon,
    this.isManual = false,
    this.hasSensors = false,
    this.n,
    this.p,
    this.k,
    this.moist,
    this.temp,
    this.hum,
    this.leafStatus,
  });
}

class _PumpsSnapshot extends StatelessWidget {
  const _PumpsSnapshot({required this.database});
  final FirebaseDatabase database;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseStreams.pumpsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final Map<String, dynamic> pumps = _toMap(
          snapshot.data?.snapshot.value,
        );
        return _PumpsCard(
          water: pumps['water'] == true,
          fert1: pumps['fert1'] == true,
          fert2: pumps['fert2'] == true,
          auto: pumps['auto'] == true,
        );
      },
    );
  }
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _formatDashboardTime(String rawTime) {
  if (rawTime.isEmpty || rawTime == '-') return rawTime;

  // Handle ISO format with T (e.g., 2026-06-01T11:45:57.719007Z)
  String cleanedTime = rawTime.replaceAll('T', ' ').replaceAll('Z', '').trim();

  final DateTime? parsed = DateTime.tryParse(cleanedTime);
  if (parsed != null) {
    final DateTime local = parsed.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final List<String> monthNames = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${local.day} ${monthNames[local.month - 1]} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
  return rawTime;
}

String _displayLeafStatus(String status) =>
    AppStrings.displayLeafStatus(status);

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.time,
    required this.leafStatus,
    required this.needsFix,
    required this.reuploadAt,
  });

  final String time;
  final String leafStatus;
  final bool needsFix;
  final String reuploadAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2E7D32), Color(0xFF558B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  AppStrings.appIconAsset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'لوحة تحكم المزرعة الحية',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('آخر تحديث: $time', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.health_and_safety_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'حالة الورقة: $leafStatus',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Chip(
                backgroundColor: Colors.white,
                label: Text(needsFix ? 'يحتاج إصلاح' : 'جيد'),
                avatar: Icon(
                  needsFix ? Icons.warning_amber_outlined : Icons.check_circle,
                  size: 18,
                ),
              ),
            ],
          ),
          if (needsFix && reuploadAt.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'التالية: ${_formatDashboardTime(reuploadAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _DailyAverageCard extends StatelessWidget {
  const _DailyAverageCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseStreams.dailyAveragesStream,
      builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'متوسط بيانات اليوم',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text('خطأ: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        final Map<String, dynamic> data = _toMap(snapshot.data?.snapshot.value);
        final Map<String, dynamic> tempEntry = _toMap(data['temp']);
        final Map<String, dynamic> humEntry = _toMap(data['hum']);
        final Map<String, dynamic> moistEntry = _toMap(data['moist']);
        final Map<String, dynamic> nEntry = _toMap(data['n']);
        final Map<String, dynamic> pEntry = _toMap(data['p']);
        final Map<String, dynamic> kEntry = _toMap(data['k']);

        int countOf(Map<String, dynamic> m) =>
            (m['count'] as num?)?.toInt() ?? 0;
        String avgOf(Map<String, dynamic> m) => m['avarage']?.toString() ?? '-';

        final int totalCount =
            countOf(tempEntry) +
            countOf(humEntry) +
            countOf(moistEntry) +
            countOf(nEntry) +
            countOf(pEntry) +
            countOf(kEntry);

        if (data.isEmpty || totalCount == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'متوسط بيانات اليوم',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text('سيبدأ تجميع القراءات بمجرد توفرها'),
                ],
              ),
            ),
          );
        }

        final String moistStr = avgOf(moistEntry);
        final String tempStr = avgOf(tempEntry);
        final String humStr = avgOf(humEntry);
        final String nStr = avgOf(nEntry);
        final String pStr = avgOf(pEntry);
        final String kStr = avgOf(kEntry);

        String formatValue(String value, {bool percent = false}) {
          if (value == '-') return '-';
          try {
            final double num = double.parse(value);
            if (percent) {
              return '${num.toStringAsFixed(1)}%';
            }
            return num.toStringAsFixed(1);
          } catch (_) {
            return '-';
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'متوسط بيانات اليوم',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _AverageChip(
                      label: 'رطوبة التربة',
                      value: formatValue(moistStr, percent: true),
                    ),
                    _AverageChip(
                      label: 'درجة الحرارة',
                      value: formatValue(tempStr),
                    ),
                    _AverageChip(
                      label: 'الرطوبة',
                      value: formatValue(humStr, percent: true),
                    ),
                    _AverageChip(label: 'النيتروجين', value: formatValue(nStr)),
                    _AverageChip(label: 'الفوسفور', value: formatValue(pStr)),
                    _AverageChip(label: 'البوتاسيوم', value: formatValue(kStr)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AverageChip extends StatelessWidget {
  const _AverageChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      label: Text('$label: $value'),
    );
  }
}

class _PumpsCard extends StatelessWidget {
  const _PumpsCard({
    required this.water,
    required this.fert1,
    required this.fert2,
    required this.auto,
  });
  final bool water, fert1, fert2, auto;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'التحكم بالمضخات',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _StatusChip(label: 'مضخة المياه', active: water),
                _StatusChip(label: 'مضخة السماد 1', active: fert1),
                _StatusChip(label: 'مضخة السماد 2', active: fert2),
                _StatusChip(label: 'الوضع التلقائي', active: auto),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.pause_circle_outline,
        size: 18,
      ),
      label: Text('$label: ${active ? AppStrings.on : AppStrings.off}'),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon == Icons.cloud_off_outlined)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  AppStrings.appIconAsset,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              )
            else
              Icon(icon, size: 52),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
