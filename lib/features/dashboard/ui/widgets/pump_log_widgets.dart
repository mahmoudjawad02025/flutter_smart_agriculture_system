import 'package:flutter/material.dart';

import '../../../../core/constants/sensor_units.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/pump_log_parser.dart';

class LogSensorChips extends StatelessWidget {
  const LogSensorChips({
    super.key,
    this.moist,
    this.temp,
    this.hum,
    this.n,
    this.p,
    this.k,
    this.tankCapacity,
  });

  final String? moist;
  final String? temp;
  final String? hum;
  final String? n;
  final String? p;
  final String? k;
  final String? tankCapacity;

  static const List<_SensorChipDef> _defs = <_SensorChipDef>[
    _SensorChipDef(
      icon: Icons.water_drop_outlined,
      color: Color(0xFF1E88E5),
      unit: SensorUnits.percent,
    ),
    _SensorChipDef(
      icon: Icons.thermostat_outlined,
      color: Color(0xFFE53935),
      unit: SensorUnits.celsius,
    ),
    _SensorChipDef(
      icon: Icons.air_outlined,
      color: Color(0xFF00ACC1),
      unit: SensorUnits.percent,
    ),
    _SensorChipDef(
      icon: Icons.grass_outlined,
      color: Color(0xFF43A047),
      unit: SensorUnits.mgPerKg,
      shortLabel: 'N',
    ),
    _SensorChipDef(
      icon: Icons.spa_outlined,
      color: Color(0xFF8E24AA),
      unit: SensorUnits.mgPerKg,
      shortLabel: 'P',
    ),
    _SensorChipDef(
      icon: Icons.eco_outlined,
      color: Color(0xFFFB8C00),
      unit: SensorUnits.mgPerKg,
      shortLabel: 'K',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<String?> values = <String?>[moist, temp, hum, n, p, k];
    final List<Widget> chips = <Widget>[];

    for (int i = 0; i < _defs.length; i++) {
      final String? raw = values[i];
      if (raw == null || raw.isEmpty) continue;

      final _SensorChipDef def = _defs[i];
      chips.add(
        _SensorChip(
          icon: def.icon,
          color: def.color,
          label: def.shortLabel,
          value: SensorUnits.formatValue(raw, unit: def.unit),
        ),
      );
    }

    if (tankCapacity != null && tankCapacity!.isNotEmpty) {
      chips.add(
        _SensorChip(
          icon: Icons.propane_tank_outlined,
          color: const Color(0xFF5E35B1),
          label: 'سعة',
          value: _formatTankCapacity(tankCapacity!),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  static String _formatTankCapacity(String raw) {
    final int? capacity = int.tryParse(raw.trim());
    if (capacity == null) {
      return SensorUnits.attachUnit(raw, SensorUnits.milliliter);
    }
    if (capacity >= 1000) {
      final double liters = capacity / 1000;
      final String litersText = liters == liters.roundToDouble()
          ? liters.toStringAsFixed(0)
          : liters.toStringAsFixed(1);
      return '$litersText لتر';
    }
    return SensorUnits.attachUnit('$capacity', SensorUnits.milliliter);
  }
}

class PumpLogEntryCard extends StatelessWidget {
  const PumpLogEntryCard({
    super.key,
    required this.log,
    this.highlightDisease = false,
    this.compact = false,
  });

  final PumpLogEntry log;
  final bool highlightDisease;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isDiseaseLog =
        log.leafStatus != null &&
        log.leafStatus!.isNotEmpty &&
        !log.leafStatus!.toLowerCase().contains('healthy') &&
        !log.leafStatus!.toLowerCase().contains('unknown');
    final bool showHighlight = highlightDisease && isDiseaseLog;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 8 : 0),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: showHighlight ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: showHighlight ? Colors.red.shade100 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  log.icon,
                  size: compact ? 18 : 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      log.title,
                      style: TextStyle(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: showHighlight ? Colors.red.shade800 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatLogTime(log.time),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (log.hasSensors || log.tankCapacity != null) ...<Widget>[
            const SizedBox(height: 10),
            LogSensorChips(
              moist: log.moist,
              temp: log.temp,
              hum: log.hum,
              n: log.n,
              p: log.p,
              k: log.k,
              tankCapacity: log.tankCapacity,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(Icons.eco_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'الحالة: ${log.leafStatus != null ? AppStrings.displayLeafStatus(log.leafStatus!) : 'غير معروف'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatLogTime(DateTime time) {
    final String day = time.day.toString().padLeft(2, '0');
    final String month = time.month.toString().padLeft(2, '0');
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$day/$month/${time.year}  $hour:$minute';
  }
}

class _SensorChip extends StatelessWidget {
  const _SensorChip({
    required this.icon,
    required this.color,
    required this.value,
    this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          if (label != null) ...<Widget>[
            const SizedBox(width: 3),
            Text(
              label!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorChipDef {
  const _SensorChipDef({
    required this.icon,
    required this.color,
    required this.unit,
    this.shortLabel,
  });

  final IconData icon;
  final Color color;
  final String unit;
  final String? shortLabel;
}
