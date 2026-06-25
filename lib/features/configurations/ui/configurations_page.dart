import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/sensor_units.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/firebase_parsers.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../firebase_data/models/farm_payload.dart';
import '../../../core/services/firebase_streams.dart';

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

  Future<int?> _showBoundedNumberDialog({
    required String title,
    required String label,
    required int initialValue,
    required int minAllowed,
    required int maxAllowed,
    String? hintText,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue.toString(),
    );

    return showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(
                RegExp(minAllowed < 0 ? r'^-?\d*$' : r'^\d*$'),
              ),
            ],
            decoration: InputDecoration(labelText: label, hintText: hintText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final int? value = int.tryParse(controller.text.trim());
                Navigator.pop(dialogContext, value);
              },
              child: const Text('حفظ'),
            ),
          ],
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

  Future<void> _editLeafStatus() async {
    final String? status = await _showStatusDialog();
    if (status == null) {
      return;
    }

    try {
      await _database.ref(FarmPayload.leafPath).update({'status': status});
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
  }) async {
    final int? value = await _showBoundedNumberDialog(
      title: title,
      label: label,
      initialValue: currentValue,
      minAllowed: minAllowed,
      maxAllowed: maxAllowed,
      hintText: hintText,
    );

    if (value == null) {
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

  List<Widget> _buildTankTiles(Map<String, dynamic> tanks) {
    const List<Map<String, dynamic>> tankDefinitions = <Map<String, dynamic>>[
      <String, dynamic>{
        'key': 'water_tank',
        'label': 'خزان المياه',
        'defaultCapacity': 5000,
        'defaultSpeed': 100,
      },
      <String, dynamic>{
        'key': 'fert1_tank',
        'label': 'خزان السماد 1',
        'defaultCapacity': 2000,
        'defaultSpeed': 50,
      },
      <String, dynamic>{
        'key': 'fert2_tank',
        'label': 'خزان السماد 2',
        'defaultCapacity': 2000,
        'defaultSpeed': 50,
      },
    ];

    final List<Widget> tiles = <Widget>[];
    for (int i = 0; i < tankDefinitions.length; i++) {
      final Map<String, dynamic> definition = tankDefinitions[i];
      final String tankKey = definition['key'] as String;
      final String label = definition['label'] as String;
      final int defaultCapacity = definition['defaultCapacity'] as int;
      final int defaultSpeed = definition['defaultSpeed'] as int;
      final Map<String, dynamic> tank = _toMap(tanks[tankKey]);
      final int capacity = parseFirebaseInt(
        tank['capacity'],
        fallback: defaultCapacity,
      );
      final int speed = parseFirebaseInt(
        tank['speed'],
        fallback: defaultSpeed,
      );

      if (i > 0) {
        tiles.add(const Divider());
      }

      tiles.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
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
            minAllowed: 1,
            maxAllowed: 100000,
            hintText: 'أدخل السعة بالمليلتر',
          ),
        ),
      );
      tiles.add(
        _configValueTile(
          label: 'سرعة المضخة (${SensorUnits.milliliterPerSecond})',
          value: SensorUnits.attachUnit('$speed', SensorUnits.milliliterPerSecond),
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

  int _toInt(dynamic value, [int fallback = 0]) =>
      parseFirebaseInt(value, fallback: fallback);

  Widget _buildConfigSections(Map<String, dynamic> config) {
    final Map<String, dynamic> autoWater = _toMap(config['auto_water']);
    final Map<String, dynamic> autoFertilizer = _toMap(config['auto_fertilizer']);
    final Map<String, dynamic> tanks = _toMap(config['tanks']);

    return Column(
      children: <Widget>[
        _SectionCard(
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
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'إعدادات التسميد التلقائي',
          subtitle:
              'حدود النيتروجين والفوسفور والبوتاسيوم (${SensorUnits.mgPerKg})',
          children: <Widget>[
            _configRangeTile(
              label: 'نيتروجين (N) — ${SensorUnits.mgPerKg}',
              minValue: _toInt(autoFertilizer['n_min']),
              maxValue: _toInt(autoFertilizer['n_max']),
              unit: SensorUnits.mgPerKg,
              onTap: () => _editConfigRange(
                section: 'auto_fertilizer',
                title: 'تعديل حدود النيتروجين',
                minKey: 'n_min',
                maxKey: 'n_max',
                currentMin: _toInt(autoFertilizer['n_min'], 120),
                currentMax: _toInt(autoFertilizer['n_max'], 220),
                allowedMin: 0,
                allowedMax: 20000,
                unit: SensorUnits.mgPerKg,
              ),
            ),
            const Divider(),
            _configRangeTile(
              label: 'فوسفور (P) — ${SensorUnits.mgPerKg}',
              minValue: _toInt(autoFertilizer['p_min']),
              maxValue: _toInt(autoFertilizer['p_max']),
              unit: SensorUnits.mgPerKg,
              onTap: () => _editConfigRange(
                section: 'auto_fertilizer',
                title: 'تعديل حدود الفوسفور',
                minKey: 'p_min',
                maxKey: 'p_max',
                currentMin: _toInt(autoFertilizer['p_min'], 40),
                currentMax: _toInt(autoFertilizer['p_max'], 80),
                allowedMin: 0,
                allowedMax: 20000,
                unit: SensorUnits.mgPerKg,
              ),
            ),
            const Divider(),
            _configRangeTile(
              label: 'بوتاسيوم (K) — ${SensorUnits.mgPerKg}',
              minValue: _toInt(autoFertilizer['k_min']),
              maxValue: _toInt(autoFertilizer['k_max']),
              unit: SensorUnits.mgPerKg,
              onTap: () => _editConfigRange(
                section: 'auto_fertilizer',
                title: 'تعديل حدود البوتاسيوم',
                minKey: 'k_min',
                maxKey: 'k_max',
                currentMin: _toInt(autoFertilizer['k_min'], 150),
                currentMax: _toInt(autoFertilizer['k_max'], 250),
                allowedMin: 0,
                allowedMax: 20000,
                unit: SensorUnits.mgPerKg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'إعدادات الخزانات المتقدمة',
          subtitle:
              'سعة الخزان (${SensorUnits.milliliter}) وسرعة المضخة (${SensorUnits.milliliterPerSecond})',
          children: _buildTankTiles(tanks),
        ),
      ],
    );
  }

  Future<String?> _showStatusDialog() async {
    String selectedStatus = 'Healthy';

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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseStreams.leafStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                final String leafStatus = 'Healthy';
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
              final String rawLeafStatus = '${leaf['status'] ?? 'Healthy'}';
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
          const SizedBox(height: 16),
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseStreams.configStream,
            builder: (context, snapshot) {
              final Map<String, dynamic> config = _toMap(
                snapshot.data?.snapshot.value,
              );
              return _buildConfigSections(config);
            },
          ),
          const SizedBox(height: 12),
          _PumpControlSection(database: _database),
          const SizedBox(height: 12),
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseStreams.leafStream,
            builder: (context, snapshot) {
              final Map<String, dynamic> leaf = _toMap(
                snapshot.data?.snapshot.value,
              );
              final String currentStatus = _displayLeafStatus(
                '${leaf['status'] ?? 'Healthy'}',
              );
              return _SectionCard(
                title: 'قواعد الكشف',
                subtitle: 'عناصر تحكم واجهة المستخدم فقط',
                children: <Widget>[
                  _EditableTile(
                    label: 'حالة الورقة',
                    value: currentStatus,
                    onTap: _editLeafStatus,
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
                      title: const Text('مضخة السماد 1'),
                      subtitle: const Text('تجاوز يدوي للمغذيات (1)'),
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
                      title: const Text('مضخة السماد 2'),
                      subtitle: const Text('تجاوز يدوي للمغذيات (2)'),
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
