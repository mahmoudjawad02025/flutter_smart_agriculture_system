import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/sensor_units.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/firebase_parsers.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../disease_detection/services/disease_detection_service.dart';
import '../../firebase_data/models/farm_payload.dart';
import '../../../core/services/firebase_streams.dart';
import '../../disease_detection/services/plant_classifier_service.dart';

class ConfigurationsPage extends StatefulWidget {
  const ConfigurationsPage({super.key});

  @override
  State<ConfigurationsPage> createState() => _ConfigurationsPageState();
}

class _ConfigurationsPageState extends State<ConfigurationsPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  void _showError(String message) {
    showLocalizedSnackBar(context, message, forceError: true);
  }

  void _showSuccess(String message) {
    showLocalizedSnackBar(context, message, forceError: false);
  }

  String _displayLeafStatus(String status) =>
      AppStrings.displayLeafStatus(status);

  String _displayDiseaseName(String name) => AppStrings.displayDiseaseName(name);

  String _resolveFert2DiseaseName(Map<String, dynamic> autoFert) {
    final String stored = '${autoFert['fert2_disease_name'] ?? ''}'.trim();
    if (stored.isNotEmpty &&
        PlantClassifierService.detectableDiseaseLabels.contains(stored)) {
      return stored;
    }
    return PlantClassifierService.defaultFert2DiseaseName;
  }

  Future<void> _editFert2Disease({required String currentDisease}) async {
    final String? selected = await _showFert2DiseaseDialog(
      currentDisease: currentDisease,
    );
    if (selected == null || selected == currentDisease) {
      return;
    }

    try {
      await _database.ref(FarmPayload.autoFertPath).update(
        <String, dynamic>{'fert2_disease_name': selected},
      );
      if (mounted) {
        _showSuccess(
          'تم اختيار مرض المعالجة: ${_displayDiseaseName(selected)}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('فشل حفظ مرض المعالجة: $e');
      }
    }
  }

  Future<String?> _showFert2DiseaseDialog({
    required String currentDisease,
  }) async {
    String selectedDisease = currentDisease;

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('اختيار مرض المعالجة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: PlantClassifierService.detectableDiseaseLabels
                    .map(
                      (String disease) => RadioListTile<String>(
                        title: Text(_displayDiseaseName(disease)),
                        subtitle: Text(disease),
                        value: disease,
                        groupValue: selectedDisease,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => selectedDisease = value);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedDisease);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int?> _showBoundedNumberDialog({
    required String title,
    required String label,
    required int initialValue,
    required int minAllowed,
    required int maxAllowed,
    String? hintText,
    String? helperText,
  }) {
    return showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _BoundedNumberDialog(
          title: title,
          label: label,
          initialValue: initialValue,
          minAllowed: minAllowed,
          maxAllowed: maxAllowed,
          hintText: hintText,
          helperText: helperText,
        );
      },
    );
  }

  Future<void> _editReuploadDelay() async {
    final int? value = await _showBoundedNumberDialog(
      title: 'تعديل مدة إعادة الرفع',
      label: 'أيام',
      initialValue: AppRuntimeConfig.diseaseReuploadDelayDays.value,
      minAllowed: 1,
      maxAllowed: 365,
      hintText: 'أدخل 1 إلى 365 يوم',
    );

    if (value == null) {
      return;
    }

    await AppRuntimeConfig.setDiseaseReuploadDelayDays(value);
    if (mounted) {
      setState(() {});
    }
  }

  int _readRefreshTimeMs(dynamic value) {
    return parseFirebaseInt(
      value,
      fallback: FarmPayload.defaultRefreshTimeMs,
    ).clamp(FarmPayload.minRefreshTimeMs, FarmPayload.maxRefreshTimeMs);
  }

  Future<void> _editRefreshTime({required int currentValue}) async {
    final int? value = await _showBoundedNumberDialog(
      title: 'زمن تحديث الحلقة',
      label: 'المدة (ms)',
      initialValue: currentValue,
      minAllowed: FarmPayload.minRefreshTimeMs,
      maxAllowed: FarmPayload.maxRefreshTimeMs,
      hintText:
          '${FarmPayload.minRefreshTimeMs} - ${FarmPayload.maxRefreshTimeMs} ms',
      helperText: 'الفترة بين كل دورة قراءة/تحكم على المتحكم الدقيق',
    );

    if (value == null || value == currentValue) {
      return;
    }

    try {
      await _database.ref(FarmPayload.refreshTimePath).set(value);
      if (mounted) {
        _showSuccess('تم حفظ زمن التحديث: $value ms');
      }
    } catch (e) {
      if (mounted) {
        _showError('فشل حفظ زمن التحديث: $e');
      }
    }
  }

  String _normalizeLeafStatusToken(String status) {
    const List<String> options = <String>[
      'Healthy',
      'LateBlight',
      'BacterialSpot',
    ];
    if (options.contains(status)) {
      return status;
    }

    final String normalized = status.toLowerCase().replaceAll(
      RegExp(r'[_\s-]'),
      '',
    );
    for (final String option in options) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }
    return 'Healthy';
  }

  Future<void> _editLeafStatus({required String currentStatus}) async {
    final String? status = await _showStatusDialog(
      currentStatus: currentStatus,
    );
    if (status == null) {
      return;
    }

    try {
      await DiseaseDetectionService.pushLeafFields(_database, status);
      if (mounted) {
        _showSuccess('تم تحديث حالة الورقة إلى: ${_displayLeafStatus(status)}');
      }
    } catch (e) {
      if (mounted) {
        _showError('فشل تحديث الحالة: $e');
      }
    }
  }

  Future<Map<String, int>?> _showMinMaxDialog({
    required String title,
    required String minLabel,
    required String maxLabel,
    required int currentMin,
    required int currentMax,
    required int allowedMin,
    required int allowedMax,
    String? unit,
  }) async {
    final TextEditingController minController = TextEditingController(
      text: currentMin.toString(),
    );
    final TextEditingController maxController = TextEditingController(
      text: currentMax.toString(),
    );
    String? errorMessage;

    final String rangeHint = unit == null
        ? '$allowedMin - $allowedMax'
        : '$allowedMin - $allowedMax $unit';
    final String unitSuffix = unit == null ? '' : ' $unit';

    return showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: minLabel,
                      hintText: rangeHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: maxLabel,
                      hintText: rangeHint,
                    ),
                  ),
                  if (errorMessage != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    final int? minValue = int.tryParse(
                      minController.text.trim(),
                    );
                    final int? maxValue = int.tryParse(
                      maxController.text.trim(),
                    );
                    if (minValue == null || maxValue == null) {
                      setState(() {
                        errorMessage = 'الرجاء إدخال أرقام صحيحة.';
                      });
                      return;
                    }
                    if (minValue < allowedMin || minValue > allowedMax) {
                      setState(() {
                        errorMessage =
                            'القيمة الدنيا يجب أن تكون بين $allowedMin و $allowedMax$unitSuffix.';
                      });
                      return;
                    }
                    if (maxValue < allowedMin || maxValue > allowedMax) {
                      setState(() {
                        errorMessage =
                            'القيمة القصوى يجب أن تكون بين $allowedMin و $allowedMax$unitSuffix.';
                      });
                      return;
                    }
                    if (minValue > maxValue) {
                      setState(() {
                        errorMessage =
                            'القيمة الدنيا يجب ألا تكون أكبر من القيمة القصوى.';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, <String, int>{
                      'min': minValue,
                      'max': maxValue,
                    });
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editConfigRange({
    required String section,
    required String title,
    required String minKey,
    required String maxKey,
    required int currentMin,
    required int currentMax,
    required int allowedMin,
    required int allowedMax,
    String? unit,
  }) async {
    final Map<String, int>? result = await _showMinMaxDialog(
      title: title,
      minLabel: unit == null ? 'الحد الأدنى' : 'الحد الأدنى ($unit)',
      maxLabel: unit == null ? 'الحد الأقصى' : 'الحد الأقصى ($unit)',
      currentMin: currentMin,
      currentMax: currentMax,
      allowedMin: allowedMin,
      allowedMax: allowedMax,
      unit: unit,
    );

    if (result == null) {
      return;
    }

    try {
      await _database.ref('${FarmPayload.configPath}/$section').update(
        <String, dynamic>{minKey: result['min'], maxKey: result['max']},
      );
      if (mounted) {
        _showSuccess('تم حفظ الإعدادات بنجاح.');
      }
    } catch (e) {
      if (mounted) {
        _showError('فشل حفظ الإعدادات: $e');
      }
    }
  }

  Widget _configRangeTile({
    required String label,
    required int minValue,
    required int maxValue,
    required VoidCallback onTap,
    String? unit,
  }) {
    final String subtitle = unit == null
        ? 'الحد الأدنى: $minValue  •  الحد الأقصى: $maxValue'
        : SensorUnits.rangeLabel(minValue, maxValue, unit);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.edit_outlined),
      onTap: onTap,
    );
  }

  Widget _configValueTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_outlined),
      onTap: onTap,
    );
  }

  Future<void> _editTankValue({
    required String tankKey,
    required String fieldKey,
    required String title,
    required String label,
    required int currentValue,
    required int minAllowed,
    required int maxAllowed,
    String? hintText,
    String? helperText,
  }) async {
    final int? value = await _showBoundedNumberDialog(
      title: title,
      label: label,
      initialValue: currentValue,
      minAllowed: minAllowed,
      maxAllowed: maxAllowed,
      hintText: hintText,
      helperText: helperText,
    );

    if (value == null) {
      return;
    }

    if (value < minAllowed || value > maxAllowed) {
      if (mounted) {
        _showError('يجب أن تكون القيمة بين $minAllowed و $maxAllowed.');
      }
      return;
    }

    try {
      await _database.ref('${FarmPayload.tanksPath}/$tankKey').update(
        <String, dynamic>{fieldKey: value},
      );
      if (mounted) {
        _showSuccess('تم حفظ إعدادات الخزان بنجاح.');
      }
    } catch (e) {
      if (mounted) {
        _showError('فشل حفظ إعدادات الخزان: $e');
      }
    }
  }

  Future<void> _editFert2Dose({
    required int currentValue,
    required int maxAllowed,
  }) async {
    if (maxAllowed < 1) {
      _showError('يرجى ضبط سعة خزان السماد 2 أولًا.');
      return;
    }

    final int? value = await _showBoundedNumberDialog(
      title: 'تعديل جرعة المعالجة',
      label: 'جرعة المعالجة (${SensorUnits.milliliter})',
      initialValue: currentValue,
      minAllowed: 1,
      maxAllowed: maxAllowed,
      hintText: '1 - $maxAllowed ${SensorUnits.milliliter}',
      helperText:
          'لا تتجاوز سعة خزان السماد 2 '
          '(${SensorUnits.attachUnit('$maxAllowed', SensorUnits.milliliter)})',
    );

    if (value == null) {
      return;
    }

    if (value < 1 || value > maxAllowed) {
      if (mounted) {
        _showError(
          'الجرعة يجب أن تكون من 1 إلى $maxAllowed ${SensorUnits.milliliter} '
          '(سعة الخزان).',
        );
      }
      return;
    }

    try {
      await _database.ref(FarmPayload.autoFertPath).update(
        <String, dynamic>{'fert2_dose_ml': value},
      );
      if (mounted) {
        _showSuccess('تم حفظ جرعة المعالجة بنجاح.');
      }
    } catch (e) {
      if (mounted) {
        _showError('فشل حفظ جرعة المعالجة: $e');
      }
    }
  }

  Widget _tankSubsectionHeader({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: color.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTankTiles({
    required Map<String, dynamic> tanks,
    required int fert2DoseMl,
    required String fert2DiseaseName,
  }) {
    const List<Map<String, dynamic>> tankDefinitions = <Map<String, dynamic>>[
      <String, dynamic>{
        'key': 'water_tank',
        'label': 'خزان المياه',
        'icon': Icons.water_drop_rounded,
        'color': Color(0xFF1E88E5),
        'defaultCapacity': 5000,
        'defaultSpeed': 100,
      },
      <String, dynamic>{
        'key': 'fert1_tank',
        'label': AppStrings.fert1TankLabel,
        'icon': Icons.science_rounded,
        'color': Color(0xFF43A047),
        'defaultCapacity': 2000,
        'defaultSpeed': 50,
      },
      <String, dynamic>{
        'key': 'fert2_tank',
        'label': AppStrings.fert2TankLabel,
        'icon': Icons.biotech_rounded,
        'color': Color(0xFFFB8C00),
        'defaultCapacity': 2000,
        'defaultSpeed': 50,
      },
    ];

    final List<Widget> tiles = <Widget>[];
    for (int i = 0; i < tankDefinitions.length; i++) {
      final Map<String, dynamic> definition = tankDefinitions[i];
      final String tankKey = definition['key'] as String;
      final String label = definition['label'] as String;
      final IconData icon = definition['icon'] as IconData;
      final Color color = definition['color'] as Color;
      final int defaultCapacity = definition['defaultCapacity'] as int;
      final int defaultSpeed = definition['defaultSpeed'] as int;
      final Map<String, dynamic> tank = _toMap(tanks[tankKey]);
      final int capacity = parseFirebaseInt(
        tank['capacity'],
        fallback: defaultCapacity,
      );
      final int speed = parseFirebaseInt(tank['speed'], fallback: defaultSpeed);
      final bool isFert2Tank = tankKey == 'fert2_tank';
      final int capacityMin = isFert2Tank
          ? (fert2DoseMl > 0 ? fert2DoseMl : 1)
          : 1;
      final String fert2DiseaseLabel = _displayDiseaseName(fert2DiseaseName);

      if (i > 0) {
        tiles.add(const SizedBox(height: 8));
      }

      tiles.add(_tankSubsectionHeader(label: label, icon: icon, color: color));
      tiles.add(
        _configValueTile(
          label: 'السعة (${SensorUnits.milliliter})',
          value: SensorUnits.attachUnit('$capacity', SensorUnits.milliliter),
          onTap: () => _editTankValue(
            tankKey: tankKey,
            fieldKey: 'capacity',
            title: 'تعديل سعة $label',
            label: 'السعة (${SensorUnits.milliliter})',
            currentValue: capacity,
            minAllowed: capacityMin,
            maxAllowed: 100000,
            hintText: isFert2Tank
                ? 'من $capacityMin إلى 100000 ${SensorUnits.milliliter}'
                : 'أدخل السعة بالمليلتر',
            helperText: isFert2Tank && fert2DoseMl > 0
                ? 'لا تقل عن جرعة معالجة $fert2DiseaseLabel '
                    '(${SensorUnits.attachUnit('$fert2DoseMl', SensorUnits.milliliter)})'
                : null,
          ),
        ),
      );
      tiles.add(
        _configValueTile(
          label: 'سرعة المضخة (${SensorUnits.milliliterPerSecond})',
          value: SensorUnits.attachUnit(
            '$speed',
            SensorUnits.milliliterPerSecond,
          ),
          onTap: () => _editTankValue(
            tankKey: tankKey,
            fieldKey: 'speed',
            title: 'تعديل سرعة مضخة $label',
            label: 'سرعة المضخة (${SensorUnits.milliliterPerSecond})',
            currentValue: speed,
            minAllowed: 1,
            maxAllowed: 10000,
            hintText: 'أدخل السرعة بالمليلتر في الثانية',
          ),
        ),
      );
    }

    return tiles;
  }

  Widget _buildFert2DoseSection({
    required Map<String, dynamic> autoFert,
    required int fert2TankCapacity,
  }) {
    final int doseMl = parseFirebaseInt(
      autoFert['fert2_dose_ml'],
      fallback: 400,
    );
    final int maxDose = fert2TankCapacity > 0 ? fert2TankCapacity : 0;
    final String diseaseName = _resolveFert2DiseaseName(autoFert);
    final String diseaseLabel = _displayDiseaseName(diseaseName);

    return _SectionCard(
      title: 'معالجة أمراض الأوراق',
      subtitle:
          'اضبط المرض الذي تُعالَج تلقائيًا بمضخة السماد 2 عند كشفه بالصورة',
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFB8C00).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFB8C00).withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.bug_report_outlined, color: Color(0xFFFB8C00)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  maxDose > 0
                      ? 'عند اكتشاف مرض في صورة الورقة، تُشغَّل مضخة السماد 2 بالجرعة المحددة أدناه. '
                          'الحد الأقصى للجرعة = سعة خزان السماد 2 '
                          '(${SensorUnits.attachUnit('$maxDose', SensorUnits.milliliter)}).'
                      : 'عند اكتشاف مرض في صورة الورقة، تُشغَّل مضخة السماد 2 بالجرعة المحددة. '
                          'يرجى ضبط سعة خزان السماد 2 أولًا قبل تحديد الجرعة.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _configValueTile(
          label: 'مرض المعالجة (الذكاء الاصطناعي)',
          value: diseaseLabel,
          onTap: () => _editFert2Disease(currentDisease: diseaseName),
        ),
        const Divider(),
        _configValueTile(
          label: 'جرعة المعالجة (${SensorUnits.milliliter})',
          value: SensorUnits.attachUnit('$doseMl', SensorUnits.milliliter),
          onTap: () => _editFert2Dose(
            currentValue: doseMl,
            maxAllowed: maxDose,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoWaterSection(Map<String, dynamic> config) {
    final Map<String, dynamic> autoWater = _toMap(config['auto_water']);

    return _SectionCard(
      title: 'إعدادات الري التلقائي',
      subtitle: 'حدود رطوبة التربة (${SensorUnits.percent})',
      children: <Widget>[
        _configRangeTile(
          label: 'رطوبة التربة (${SensorUnits.percent})',
          minValue: _toInt(autoWater['moist_min']),
          maxValue: _toInt(autoWater['moist_max']),
          unit: SensorUnits.percent,
          onTap: () => _editConfigRange(
            section: 'auto_water',
            title: 'تعديل حدود رطوبة التربة',
            minKey: 'moist_min',
            maxKey: 'moist_max',
            currentMin: _toInt(autoWater['moist_min'], 40),
            currentMax: _toInt(autoWater['moist_max'], 80),
            allowedMin: 0,
            allowedMax: 100,
            unit: SensorUnits.percent,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoFertSection(Map<String, dynamic> config) {
    final Map<String, dynamic> autoFert = _toMap(config['auto_fert']);

    return _SectionCard(
      title: 'إعدادات التسميد التلقائي',
      subtitle:
          'حدود النيتروجين والفوسفور والبوتاسيوم (${SensorUnits.mgPerKg})',
      children: <Widget>[
        _configRangeTile(
          label: 'نيتروجين (N) — ${SensorUnits.mgPerKg}',
          minValue: _toInt(autoFert['n_min']),
          maxValue: _toInt(autoFert['n_max']),
          unit: SensorUnits.mgPerKg,
          onTap: () => _editConfigRange(
            section: 'auto_fert',
            title: 'تعديل حدود النيتروجين',
            minKey: 'n_min',
            maxKey: 'n_max',
            currentMin: _toInt(autoFert['n_min'], 120),
            currentMax: _toInt(autoFert['n_max'], 220),
            allowedMin: 0,
            allowedMax: 20000,
            unit: SensorUnits.mgPerKg,
          ),
        ),
        const Divider(),
        _configRangeTile(
          label: 'فوسفور (P) — ${SensorUnits.mgPerKg}',
          minValue: _toInt(autoFert['p_min']),
          maxValue: _toInt(autoFert['p_max']),
          unit: SensorUnits.mgPerKg,
          onTap: () => _editConfigRange(
            section: 'auto_fert',
            title: 'تعديل حدود الفوسفور',
            minKey: 'p_min',
            maxKey: 'p_max',
            currentMin: _toInt(autoFert['p_min'], 40),
            currentMax: _toInt(autoFert['p_max'], 80),
            allowedMin: 0,
            allowedMax: 20000,
            unit: SensorUnits.mgPerKg,
          ),
        ),
        const Divider(),
        _configRangeTile(
          label: 'بوتاسيوم (K) — ${SensorUnits.mgPerKg}',
          minValue: _toInt(autoFert['k_min']),
          maxValue: _toInt(autoFert['k_max']),
          unit: SensorUnits.mgPerKg,
          onTap: () => _editConfigRange(
            section: 'auto_fert',
            title: 'تعديل حدود البوتاسيوم',
            minKey: 'k_min',
            maxKey: 'k_max',
            currentMin: _toInt(autoFert['k_min'], 150),
            currentMax: _toInt(autoFert['k_max'], 250),
            allowedMin: 0,
            allowedMax: 20000,
            unit: SensorUnits.mgPerKg,
          ),
        ),
      ],
    );
  }

  int _toInt(dynamic value, [int fallback = 0]) =>
      parseFirebaseInt(value, fallback: fallback);

  Widget _buildTanksSection(Map<String, dynamic> config) {
    final Map<String, dynamic> tanks = _toMap(config['tanks']);
    final Map<String, dynamic> autoFert = _toMap(
      config['auto_fert'],
    );
    final int fert2DoseMl = parseFirebaseInt(
      autoFert['fert2_dose_ml'],
      fallback: 400,
    );
    final String fert2DiseaseName = _resolveFert2DiseaseName(autoFert);

    return _SectionCard(
      title: 'إعدادات الخزانات المتقدمة',
      subtitle:
          'سعة الخزان (${SensorUnits.milliliter}) وسرعة المضخة (${SensorUnits.milliliterPerSecond})',
      children: _buildTankTiles(
        tanks: tanks,
        fert2DoseMl: fert2DoseMl,
        fert2DiseaseName: fert2DiseaseName,
      ),
    );
  }

  Widget _buildFert2DoseFromConfig(Map<String, dynamic> config) {
    final Map<String, dynamic> autoFert = _toMap(
      config['auto_fert'],
    );
    final Map<String, dynamic> fert2Tank = _toMap(
      _toMap(config['tanks'])['fert2_tank'],
    );
    final int fert2TankCapacity = parseFirebaseInt(
      fert2Tank['capacity'],
      fallback: 2000,
    );

    return _buildFert2DoseSection(
      autoFert: autoFert,
      fert2TankCapacity: fert2TankCapacity,
    );
  }

  Future<String?> _showStatusDialog({required String currentStatus}) async {
    String selectedStatus = _normalizeLeafStatusToken(currentStatus);

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تعديل حالة الورقة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile<String>(
                    title: const Text('سليم'),
                    value: 'Healthy',
                    groupValue: selectedStatus,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => selectedStatus = value);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('تعفن متأخر'),
                    value: 'LateBlight',
                    groupValue: selectedStatus,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => selectedStatus = value);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('بقعة بكتيرية'),
                    value: 'BacterialSpot',
                    groupValue: selectedStatus,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => selectedStatus = value);
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedStatus);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: AppRuntimeConfig.configSectionVisibilityListenables,
        builder: (context, _) {
          final bool showRefreshTime =
              AppRuntimeConfig.showConfigRefreshTime.value;
          final bool showAutoWater = AppRuntimeConfig.showConfigAutoWater.value;
          final bool showAutoFert = AppRuntimeConfig.showConfigAutoFert.value;
          final bool showTanks = AppRuntimeConfig.showConfigTanks.value;
          final bool showFert2Dose = AppRuntimeConfig.showConfigFert2Dose.value;
          final bool showDetectionRules =
              AppRuntimeConfig.showConfigDetectionRules.value;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              StreamBuilder<DatabaseEvent>(
                stream: FirebaseStreams.leafStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data?.snapshot.value == null) {
                    const String leafStatus = 'Healthy';
                    return _HeaderCard(
                      diseaseReuploadDays:
                          AppRuntimeConfig.diseaseReuploadDelayDays.value,
                      healthyKeywords: AppRuntimeConfig.healthyKeywords.value,
                      confirmedDiseaseLabels:
                          AppRuntimeConfig.confirmedDiseaseLabels.value,
                      leafStatus: leafStatus,
                      hasDisease: false,
                    );
                  }
                  final Map<String, dynamic> leaf = _toMap(
                    snapshot.data!.snapshot.value,
                  );
                  final String rawLeafStatus =
                      '${leaf['status'] ?? 'Healthy'}';
                  final String leafStatus = _displayLeafStatus(rawLeafStatus);
                  final bool hasDisease =
                      rawLeafStatus.toLowerCase() != 'healthy' &&
                      rawLeafStatus.isNotEmpty;
                  return _HeaderCard(
                    diseaseReuploadDays:
                        AppRuntimeConfig.diseaseReuploadDelayDays.value,
                    healthyKeywords: AppRuntimeConfig.healthyKeywords.value,
                    confirmedDiseaseLabels:
                        AppRuntimeConfig.confirmedDiseaseLabels.value,
                    leafStatus: leafStatus,
                    hasDisease: hasDisease,
                  );
                },
              ),
              if (showRefreshTime) ...<Widget>[
                const SizedBox(height: 12),
                StreamBuilder<DatabaseEvent>(
                  initialData: FirebaseStreams.lastRefreshTimeEvent,
                  stream: FirebaseStreams.refreshTimeStream,
                  builder: (context, snapshot) {
                    final int refreshTimeMs = _readRefreshTimeMs(
                      snapshot.data?.snapshot.value,
                    );
                    return _RefreshTimeCard(
                      refreshTimeMs: refreshTimeMs,
                      onTap: () =>
                          _editRefreshTime(currentValue: refreshTimeMs),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              StreamBuilder<DatabaseEvent>(
                stream: FirebaseStreams.configStream,
                builder: (context, snapshot) {
                  final Map<String, dynamic> config = _toMap(
                    snapshot.data?.snapshot.value,
                  );
                  return Column(
                    children: <Widget>[
                      if (showAutoWater) _buildAutoWaterSection(config),
                      if (showAutoWater && showAutoFert)
                        const SizedBox(height: 12),
                      if (showAutoFert) _buildAutoFertSection(config),
                      if (showAutoWater || showAutoFert)
                        const SizedBox(height: 12),
                      _PumpControlSection(database: _database),
                      if (showTanks) ...<Widget>[
                        const SizedBox(height: 12),
                        _buildTanksSection(config),
                      ],
                      if (showFert2Dose) ...<Widget>[
                        const SizedBox(height: 12),
                        _buildFert2DoseFromConfig(config),
                      ],
                    ],
                  );
                },
              ),
              if (showDetectionRules) ...<Widget>[
                const SizedBox(height: 12),
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseStreams.leafStream,
                  builder: (context, snapshot) {
                    final Map<String, dynamic> leaf = _toMap(
                      snapshot.data?.snapshot.value,
                    );
                    final String rawLeafStatus =
                        '${leaf['status'] ?? 'Healthy'}';
                    final String currentStatus =
                        _displayLeafStatus(rawLeafStatus);
                    return _SectionCard(
                      title: 'قواعد الكشف',
                      subtitle: 'عناصر تحكم واجهة المستخدم فقط',
                      children: <Widget>[
                        _EditableTile(
                          label: 'حالة الورقة',
                          value: currentStatus,
                          onTap: () =>
                              _editLeafStatus(currentStatus: rawLeafStatus),
                        ),
                        _EditableTile(
                          label: 'مدة إعادة رفع المرض',
                          value:
                              '${AppRuntimeConfig.diseaseReuploadDelayDays.value} أيام',
                          onTap: _editReuploadDelay,
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              _SectionCard(
                title: 'ما تحتاجه',
                subtitle: 'قائمة مرجعية أساسية لسير عمل مزرعة نظيفة',
                children: const <Widget>[
                  _ChecklistTile(
                    text: 'قاعدة بيانات Firebase في الوقت الفعلي متصلة',
                  ),
                  _ChecklistTile(
                    text: 'صور أوراق البندورة واضحة بما يكفي للذكاء الاصطناعي',
                  ),
                  _ChecklistTile(text: 'حدود المحصول الدنيا والقصوى صحيحة'),
                  _ChecklistTile(text: 'تم تفعيل الإشعارات لتنبيهات الأمراض'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PumpControlSection extends StatefulWidget {
  const _PumpControlSection({required this.database});
  final FirebaseDatabase database;

  @override
  State<_PumpControlSection> createState() => _PumpControlSectionState();
}

class _PumpControlSectionState extends State<_PumpControlSection> {
  late final Stream<DatabaseEvent> _pumpsStream = FirebaseStreams.pumpsStream;

  Future<void> _handleManualToggle(
    DatabaseReference pumpRef,
    bool newValue,
  ) async {
    try {
      await pumpRef.set(newValue);
    } catch (e) {
      debugPrint('Manual pump toggle failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _pumpsStream,
      builder: (context, snapshot) {
        final Map<String, dynamic> data = _toMap(snapshot.data?.snapshot.value);
        final bool isAuto = data['auto'] == true;
        final bool isWater = data['water'] == true;
        final bool isFert1 = data['fert1'] == true;
        final bool isFert2 = data['fert2'] == true;

        return _SectionCard(
          title: 'التحكم بالمضخة والوضع',
          subtitle: 'تجاوز الأنظمة التلقائية أو تبديل الحالة اليدوية',
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('وضع التحكم التلقائي'),
              subtitle: const Text('دع النظام يتحكم بالمضخات تلقائيًا'),
              value: isAuto,
              onChanged: (bool value) {
                widget.database.ref('${FarmPayload.pumpsPath}/auto').set(value);
              },
            ),
            const Divider(),
            Opacity(
              opacity: isAuto ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: isAuto,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('مضخة المياه'),
                      subtitle: const Text('تجاوز يدوي للري'),
                      value: isWater,
                      onChanged: (bool value) {
                        _handleManualToggle(
                          widget.database.ref('${FarmPayload.pumpsPath}/water'),
                          value,
                        );
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(AppStrings.fert1PumpLabel),
                      subtitle: const Text('تجاوز يدوي لعلاج نقص المعادن'),
                      value: isFert1,
                      onChanged: (bool value) {
                        _handleManualToggle(
                          widget.database.ref('${FarmPayload.pumpsPath}/fert1'),
                          value,
                        );
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(AppStrings.fert2PumpLabel),
                      subtitle: const Text('تجاوز يدوي لعلاج اكتشاف المرض'),
                      value: isFert2,
                      onChanged: (bool value) {
                        _handleManualToggle(
                          widget.database.ref('${FarmPayload.pumpsPath}/fert2'),
                          value,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.diseaseReuploadDays,
    required this.healthyKeywords,
    required this.confirmedDiseaseLabels,
    required this.leafStatus,
    required this.hasDisease,
  });

  final int diseaseReuploadDays;
  final List<String> healthyKeywords;
  final List<String> confirmedDiseaseLabels;
  final String leafStatus;
  final bool hasDisease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2E7D32), Color(0xFF7CB342)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'تكوينات المزرعة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضبط إعدادات الكشف وحدود المحصول من شاشة واحدة.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoChip(label: 'إعادة رفع', value: '$diseaseReuploadDays أيام'),
              _InfoChip(
                label: hasDisease ? 'المرض' : 'الحالة',
                value: leafStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RefreshTimeCard extends StatelessWidget {
  const _RefreshTimeCard({
    required this.refreshTimeMs,
    required this.onTap,
  });

  final int refreshTimeMs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF00897B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: <Color>[
                accent.withValues(alpha: 0.08),
                const Color(0xFF43A047).withValues(alpha: 0.06),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'زمن تحديث الحلقة',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'فترة انتظار المتحكم الدقيق بين كل دورة (${FarmPayload.minRefreshTimeMs}–${FarmPayload.maxRefreshTimeMs} ms)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '$refreshTimeMs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Text(
                      'ms',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_outlined, size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({
    required this.label,
    required this.value,
    this.icon = Icons.check_circle_outline,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _EditableTile extends StatelessWidget {
  const _EditableTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.edit_outlined),
      title: Text(label),
      subtitle: Text(value),
      trailing: Icon(trailingIcon),
      onTap: onTap,
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.check, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 12),
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _BoundedNumberDialog extends StatefulWidget {
  const _BoundedNumberDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.minAllowed,
    required this.maxAllowed,
    this.hintText,
    this.helperText,
  });

  final String title;
  final String label;
  final int initialValue;
  final int minAllowed;
  final int maxAllowed;
  final String? hintText;
  final String? helperText;

  @override
  State<_BoundedNumberDialog> createState() => _BoundedNumberDialogState();
}

class _BoundedNumberDialogState extends State<_BoundedNumberDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final int? value = int.tryParse(_controller.text.trim());
    if (value == null) {
      setState(() => _errorMessage = 'الرجاء إدخال رقم صحيح.');
      return;
    }
    if (value < widget.minAllowed || value > widget.maxAllowed) {
      setState(() {
        _errorMessage =
            'يجب أن تكون القيمة بين ${widget.minAllowed} و ${widget.maxAllowed}.';
      });
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(
            RegExp(widget.minAllowed < 0 ? r'^-?\d*$' : r'^\d*$'),
          ),
        ],
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText ?? '${widget.minAllowed} - ${widget.maxAllowed}',
          helperText:
              widget.helperText ??
              'المسموح: من ${widget.minAllowed} إلى ${widget.maxAllowed}',
          errorText: _errorMessage,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
