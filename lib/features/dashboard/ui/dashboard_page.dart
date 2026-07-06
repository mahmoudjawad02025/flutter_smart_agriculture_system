import 'package:firebase_database/firebase_database.dart';
import '../../../core/constants/sensor_units.dart';
import '../../../core/utils/firebase_parsers.dart';
import '../../../core/services/firebase_streams.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/pump_log_parser.dart';
import 'package:flutter/material.dart';

import 'logs_history_page.dart';
import 'widgets/pump_log_widgets.dart';

// use centralized app icon from AppStrings

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  late final Stream<DatabaseEvent> _dataStream;
  late final Stream<DatabaseEvent> _leafStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _dataStream = FirebaseStreams.rootStream;
    _leafStream = FirebaseStreams.leafStream;
  }

  Widget _buildLeafHeaderCard(DatabaseEvent? event) {
    final Map<String, dynamic> leaf = _toMap(event?.snapshot.value);
    final String leafLastUpdated = '${leaf['last_updated'] ?? ''}';
    final String lastUpdated = leafLastUpdated.isNotEmpty
        ? _formatDashboardTime(leafLastUpdated)
        : '-';
    final String leafStatus = _displayLeafStatus('${leaf['status'] ?? '-'}');
    final bool needsFix = leaf['needs_fix'] == true;
    final String reuploadAt = '${leaf['reupload_at'] ?? ''}';

    return _HeaderCard(
      lastUpdated: lastUpdated,
      leafStatus: leafStatus,
      needsFix: needsFix,
      reuploadAt: reuploadAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: StreamBuilder<DatabaseEvent>(
        stream: _dataStream,
        initialData: FirebaseStreams.lastRootEvent,
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
          final Map<String, dynamic> config = _toMap(data['config']);
          final Map<String, dynamic> tanks = _toMap(config['tanks']);

          return ListView(
            key: const PageStorageKey<String>('dashboard_scroll'),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              StreamBuilder<DatabaseEvent>(
                stream: _leafStream,
                initialData: FirebaseStreams.lastLeafEvent,
                builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> leafSnapshot) {
                  return _buildLeafHeaderCard(leafSnapshot.data);
                },
              ),
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
                    title: 'رطوبة التربة (${SensorUnits.percent})',
                    value: SensorUnits.formatValue(
                      source['moist']?.toString(),
                      unit: SensorUnits.percent,
                    ),
                    icon: Icons.water_drop_outlined,
                    color: const Color(0xFF1E88E5),
                  ),
                  _MetricCard(
                    title: 'درجة الحرارة (${SensorUnits.celsius})',
                    value: SensorUnits.formatValue(
                      source['temp']?.toString(),
                      unit: SensorUnits.celsius,
                    ),
                    icon: Icons.thermostat_outlined,
                    color: const Color(0xFFE53935),
                  ),
                  _MetricCard(
                    title: 'رطوبة الهواء (${SensorUnits.percent})',
                    value: SensorUnits.formatValue(
                      source['hum']?.toString(),
                      unit: SensorUnits.percent,
                    ),
                    icon: Icons.air_outlined,
                    color: const Color(0xFF00ACC1),
                  ),
                  _MetricCard(
                    title: 'النيتروجين (N) — ${SensorUnits.mgPerKg}',
                    value: SensorUnits.formatValue(
                      source['n']?.toString(),
                      unit: SensorUnits.mgPerKg,
                    ),
                    icon: Icons.grass_outlined,
                    color: const Color(0xFF43A047),
                  ),
                  _MetricCard(
                    title: 'الفوسفور (P) — ${SensorUnits.mgPerKg}',
                    value: SensorUnits.formatValue(
                      source['p']?.toString(),
                      unit: SensorUnits.mgPerKg,
                    ),
                    icon: Icons.spa_outlined,
                    color: const Color(0xFF8E24AA),
                  ),
                  _MetricCard(
                    title: 'البوتاسيوم (K) — ${SensorUnits.mgPerKg}',
                    value: SensorUnits.formatValue(
                      source['k']?.toString(),
                      unit: SensorUnits.mgPerKg,
                    ),
                    icon: Icons.eco_outlined,
                    color: const Color(0xFFFB8C00),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _TanksCapacityCard(tanks: tanks),
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
      initialData: FirebaseStreams.lastLogsEvent,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const SizedBox.shrink();
        }

        final Map<String, dynamic> logsData = _toMap(
          snapshot.data?.snapshot.value,
        );

        final List<PumpLogEntry> allLogs = PumpLogParser.parseLogsNode(logsData);

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
                    children: allLogs.take(5).map((PumpLogEntry log) {
                      return PumpLogEntryCard(log: log, compact: true);
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PumpsSnapshot extends StatelessWidget {
  const _PumpsSnapshot({required this.database});
  final FirebaseDatabase database;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseStreams.pumpsStream,
      initialData: FirebaseStreams.lastPumpsEvent,
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

  // Keep the Z/offset so UTC timestamps convert correctly to local time.
  final DateTime? parsed = DateTime.tryParse(rawTime.trim());
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
    required this.lastUpdated,
    required this.leafStatus,
    required this.needsFix,
    required this.reuploadAt,
  });

  final String lastUpdated;
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
          Text(
            'آخر تحديث للورقة: $lastUpdated',
            style: const TextStyle(color: Colors.white),
          ),
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
              'موعد إعادة الرفع: ${_formatDashboardTime(reuploadAt)}',
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
    required this.color,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TanksCapacityCard extends StatelessWidget {
  const _TanksCapacityCard({required this.tanks});

  final Map<String, dynamic> tanks;

  static const List<_TankDefinition> _definitions = <_TankDefinition>[
    _TankDefinition(
      key: 'water_tank',
      label: 'خزان المياه',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF1E88E5),
      defaultCapacity: 5000,
    ),
    _TankDefinition(
      key: 'fert1_tank',
      label: AppStrings.fert1TankLabel,
      icon: Icons.science_rounded,
      color: Color(0xFF43A047),
      defaultCapacity: 2000,
    ),
    _TankDefinition(
      key: 'fert2_tank',
      label: AppStrings.fert2TankLabel,
      icon: Icons.biotech_rounded,
      color: Color(0xFFFB8C00),
      defaultCapacity: 2000,
    ),
  ];

  int _readCapacity(Map<String, dynamic> tankData, int fallback) =>
      parseFirebaseInt(tankData['capacity'], fallback: fallback);

  String _formatCapacity(int capacity) {
    if (capacity >= 1000) {
      final double liters = capacity / 1000;
      final String litersText = liters == liters.roundToDouble()
          ? liters.toStringAsFixed(0)
          : liters.toStringAsFixed(1);
      return '$litersText لتر';
    }
    return SensorUnits.attachUnit('$capacity', SensorUnits.milliliter);
  }

  @override
  Widget build(BuildContext context) {
    final List<_TankCapacityData> tankData = _definitions.map((
      _TankDefinition definition,
    ) {
      final Map<String, dynamic> tank = _toMap(tanks[definition.key]);
      final int capacity = _readCapacity(tank, definition.defaultCapacity);
      return _TankCapacityData(definition: definition, capacity: capacity);
    }).toList();

    final int totalCapacity = tankData.fold<int>(
      0,
      (int sum, _TankCapacityData item) => sum + item.capacity,
    );
    final int maxCapacity = tankData.fold<int>(
      1,
      (int max, _TankCapacityData item) =>
          item.capacity > max ? item.capacity : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.propane_tank_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'سعة الخزانات',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الإجمالي: ${_formatCapacity(totalCapacity)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: tankData.map((_TankCapacityData item) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _TankCapacityVisual(
                      label: item.definition.label,
                      icon: item.definition.icon,
                      color: item.definition.color,
                      capacity: item.capacity,
                      fillFraction: item.capacity / maxCapacity,
                      capacityLabel: _formatCapacity(item.capacity),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TankDefinition {
  const _TankDefinition({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.defaultCapacity,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final int defaultCapacity;
}

class _TankCapacityData {
  const _TankCapacityData({required this.definition, required this.capacity});

  final _TankDefinition definition;
  final int capacity;
}

class _TankCapacityVisual extends StatelessWidget {
  const _TankCapacityVisual({
    required this.label,
    required this.icon,
    required this.color,
    required this.capacity,
    required this.fillFraction,
    required this.capacityLabel,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int capacity;
  final double fillFraction;
  final String capacityLabel;

  @override
  Widget build(BuildContext context) {
    final double clampedFill = fillFraction.clamp(0.15, 1.0);

    return Column(
      children: <Widget>[
        Container(
          height: 118,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.18)),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: clampedFill,
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                color.withValues(alpha: 0.55),
                                color,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          capacityLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: 0.95),
          ),
        ),
      ],
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
                _StatusChip(label: AppStrings.fert1PumpLabel, active: fert1),
                _StatusChip(label: AppStrings.fert2PumpLabel, active: fert2),
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
