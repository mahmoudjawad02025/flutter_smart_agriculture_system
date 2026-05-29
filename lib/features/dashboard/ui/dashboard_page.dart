import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import '../../../core/services/firebase_streams.dart';
import 'package:flutter/material.dart';

import 'logs_history_page.dart';
import '../../firebase_data/models/farm_payload.dart';

const String _appIconAsset = 'lib/core/media/icons/app/app.png';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DatabaseReference _dataRef;
  late final Stream<DatabaseEvent> _dataStream;
  final List<_SensorSample> _dailySensorSamples = <_SensorSample>[];
  final Map<String, dynamic> _latestSource = <String, dynamic>{};
  DateTime _currentDay = DateTime.now();
  DateTime? _lastSampleTimestamp;
  Timer? _sampleTimer;

  @override
  void initState() {
    super.initState();
    _dataRef = FarmPayload.rootRef(FirebaseDatabase.instance);
    _dataStream = FirebaseStreams.rootStream;
    _sampleTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _sampleCurrentSource(),
    );
  }

  @override
  void dispose() {
    _sampleTimer?.cancel();
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

          _resetDailySamplesIfNeeded(DateTime.now());
          _latestSource
            ..clear()
            ..addAll(source);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _submitInitialSampleIfNeeded();
          });

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
              _DailyAverageCard(samples: _dailySensorSamples),
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
                    value: '${source['temp'] ?? '-'} C',
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

  void _resetDailySamplesIfNeeded(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (!today.isSameDay(_currentDay)) {
      _dailySensorSamples.clear();
      _currentDay = today;
      _lastSampleTimestamp = null;
    }
  }

  void _submitInitialSampleIfNeeded() {
    if (_lastSampleTimestamp != null || _latestSource.isEmpty) return;
    _sampleCurrentSource();
  }

  void _sampleCurrentSource() {
    if (!mounted) return;
    final DateTime now = DateTime.now();
    _resetDailySamplesIfNeeded(now);
    if (_latestSource.isEmpty) return;
    if (_lastSampleTimestamp != null &&
        now.difference(_lastSampleTimestamp!).inMinutes < 30) {
      return;
    }

    final _SensorSample? sample = _SensorSample.fromMap(_latestSource, now);
    if (sample == null) return;

    setState(() {
      _dailySensorSamples.add(sample);
      _lastSampleTimestamp = now;
    });
  }
}

class _SensorSample {
  _SensorSample({
    required this.timestamp,
    required this.moist,
    required this.temp,
    required this.hum,
    required this.n,
    required this.p,
    required this.k,
  });

  final DateTime timestamp;
  final double? moist;
  final double? temp;
  final double? hum;
  final double? n;
  final double? p;
  final double? k;

  static _SensorSample? fromMap(Map<String, dynamic> map, DateTime timestamp) {
    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    final double? moist = parseDouble(map['moist']);
    final double? temp = parseDouble(map['temp']);
    final double? hum = parseDouble(map['hum']);
    final double? n = parseDouble(map['n']);
    final double? p = parseDouble(map['p']);
    final double? k = parseDouble(map['k']);

    if (moist == null &&
        temp == null &&
        hum == null &&
        n == null &&
        p == null &&
        k == null) {
      return null;
    }

    return _SensorSample(
      timestamp: timestamp,
      moist: moist,
      temp: temp,
      hum: hum,
      n: n,
      p: p,
      k: k,
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

        // Parse Fertilizer Logs
        _toMap(logsData['fert_log']).forEach((key, val) {
          final data = _toMap(val);
          allLogs.add(
            _LogItem(
              time: _parseDate(data['time']),
              title: 'الأسمدة: ${data['type'] ?? 'تطبيق'}',
              subtitle: 'القيمة: ${data['val'] ?? '-'}',
              icon: Icons.science_outlined,
            ),
          );
        });

        // Parse Water Logs
        _toMap(logsData['water_log']).forEach((key, val) {
          final data = _toMap(val);
          allLogs.add(
            _LogItem(
              time: _parseDate(data['time']),
              title: 'جلسة ري',
              subtitle: 'تم تشغيل مضخة الري',
              icon: Icons.water_drop_outlined,
            ),
          );
        });

        // Parse AI Upload Logs
        _toMap(logsData['upload_log']).forEach((key, val) {
          final data = _toMap(val);
          allLogs.add(
            _LogItem(
              time: _parseDate(data['time']),
              title: 'نتيجة فحص الذكاء الاصطناعي',
              subtitle: 'الكشف: ${data['res'] ?? 'Healthy'}',
              icon: Icons.auto_awesome_outlined,
            ),
          );
        });

        // Parse Manual Logs
        _toMap(logsData['manual_log']).forEach((key, val) {
          final data = _toMap(val);
          final state = _toMap(data['state']);
          allLogs.add(
            _LogItem(
              time: _parseDate(data['time']),
              title: 'يدوي ${data['pump']}: ${data['action']}',
              icon: Icons.touch_app_outlined,
              isManual: true,
              n: state['n']?.toString() ?? '?',
              p: state['p']?.toString() ?? '?',
              k: state['k']?.toString() ?? '?',
              moist: state['moist']?.toString() ?? '?',
              temp: state['temp']?.toString() ?? '?',
            ),
          );
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
                        subtitle: log.isManual
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _MiniMetric(Icons.water_drop, log.moist!),
                                      _MiniMetric(Icons.thermostat, log.temp!),
                                      _MiniMetric(Icons.grass, log.n!),
                                      _MiniMetric(Icons.spa, log.p!),
                                      _MiniMetric(Icons.eco, log.k!),
                                    ],
                                  ),
                                ),
                              )
                            : Text(
                                log.subtitle ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                        trailing: Text(
                          '${log.time.hour}:${log.time.minute.toString().padLeft(2, '0')}',
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
        return DateTime.parse(val);
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
  final String? n, p, k, moist, temp;

  _LogItem({
    required this.time,
    required this.title,
    this.subtitle,
    required this.icon,
    this.isManual = false,
    this.n,
    this.p,
    this.k,
    this.moist,
    this.temp,
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[local.month - 1]} ${local.day}, ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
  return rawTime;
}

extension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

String _displayLeafStatus(String status) {
  final String normalized = status.toLowerCase().replaceAll(
    RegExp(r'[_\s-]'),
    '',
  );

  switch (normalized) {
    case 'healthy':
      return 'سليم';
    case 'unknown':
      return 'غير معروف';
    case 'bacterialspot':
      return 'بقعة بكتيرية';
    case 'lateblight':
      return 'تعفن متأخر';
    case 'earlyblight':
      return 'تعفن مبكر';
    case 'yellowleafcurl':
      return 'لف الورقة الأصفر';
    case 'septoria':
      return 'سِبتوريا';
    case 'powderymildew':
      return 'سوس العفن';
    default:
      return status;
  }
}

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
                  _appIconAsset,
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
  const _DailyAverageCard({required this.samples});
  final List<_SensorSample> samples;

  String _averageValue(List<double?> values, {bool percent = false}) {
    final List<double> valid = values.whereType<double>().toList();
    if (valid.isEmpty) return '-';
    final double avg = valid.reduce((a, b) => a + b) / valid.length;
    if (percent) {
      return '${avg.toStringAsFixed(1)}%';
    }
    return avg.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
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
              const Text(
                'سيبدأ تجميع القراءات كل 30 دقيقة بمجرد مشاهدة لوحة التحكم.',
              ),
            ],
          ),
        ),
      );
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
                  value: _averageValue(
                    samples.map((e) => e.moist).toList(),
                    percent: true,
                  ),
                ),
                _AverageChip(
                  label: 'درجة الحرارة',
                  value: _averageValue(samples.map((e) => e.temp).toList()),
                ),
                _AverageChip(
                  label: 'الرطوبة',
                  value: _averageValue(
                    samples.map((e) => e.hum).toList(),
                    percent: true,
                  ),
                ),
                _AverageChip(
                  label: 'النيتروجين',
                  value: _averageValue(samples.map((e) => e.n).toList()),
                ),
                _AverageChip(
                  label: 'الفوسفور',
                  value: _averageValue(samples.map((e) => e.p).toList()),
                ),
                _AverageChip(
                  label: 'البوتاسيوم',
                  value: _averageValue(samples.map((e) => e.k).toList()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'نقاط التجميع اليوم: ${samples.length}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
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
      label: Text('$label: ${active ? 'ON' : 'OFF'}'),
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
                  _appIconAsset,
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
