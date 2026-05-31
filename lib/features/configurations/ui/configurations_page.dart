import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/localization/app_strings.dart';
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

  Future<List<int>?> _showBoundedRangeDialog({
    required String title,
    required String minLabel,
    required String maxLabel,
    required int minValue,
    required int maxValue,
    required int minAllowed,
    required int maxAllowed,
  }) async {
    final TextEditingController minController = TextEditingController(
      text: minValue.toString(),
    );
    final TextEditingController maxController = TextEditingController(
      text: maxValue.toString(),
    );

    return showDialog<List<int>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(minAllowed < 0 ? r'^-?\d*$' : r'^\d*$'),
                  ),
                ],
                decoration: InputDecoration(labelText: minLabel),
              ),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(minAllowed < 0 ? r'^-?\d*$' : r'^\d*$'),
                  ),
                ],
                decoration: InputDecoration(labelText: maxLabel),
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
                final int? minParsed = int.tryParse(minController.text.trim());
                final int? maxParsed = int.tryParse(maxController.text.trim());
                if (minParsed == null || maxParsed == null) {
                  Navigator.pop(dialogContext);
                  return;
                }
                Navigator.pop(dialogContext, <int>[minParsed, maxParsed]);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  bool _validateRangeValues(
    int minValue,
    int maxValue,
    int minAllowed,
    int maxAllowed,
  ) {
    if (minValue < minAllowed || maxValue > maxAllowed) return false;
    if (minValue > maxValue) return false;
    return true;
  }

  Future<void> _syncAutoWaterToRealtimeDatabase({
    required int tempMin,
    required int tempMax,
    required int humMin,
    required int humMax,
    required int moistMin,
    required int moistMax,
  }) async {
    await _database.ref(FarmPayload.autoWaterPath).set(<String, dynamic>{
      'temp_min': tempMin,
      'temp_max': tempMax,
      'hum_min': humMin,
      'hum_max': humMax,
      'moist_min': moistMin,
      'moist_max': moistMax,
    });
  }

  Future<void> _syncAutoFertilizerToRealtimeDatabase({
    required int nMin,
    required int nMax,
    required int pMin,
    required int pMax,
    required int kMin,
    required int kMax,
    required String leafGoal,
  }) async {
    await _database.ref(FarmPayload.autoFertilizerPath).set(<String, dynamic>{
      'n_min': nMin,
      'n_max': nMax,
      'p_min': pMin,
      'p_max': pMax,
      'k_min': kMin,
      'k_max': kMax,
      'leaf_goal': leafGoal,
    });
  }

  Future<void> _saveAutoWaterConfig({
    int? tempMin,
    int? tempMax,
    int? humMin,
    int? humMax,
    int? moistMin,
    int? moistMax,
  }) async {
    final int tempMinValue = tempMin ?? AppRuntimeConfig.tempMin.value;
    final int tempMaxValue = tempMax ?? AppRuntimeConfig.tempMax.value;
    final int humMinValue = humMin ?? AppRuntimeConfig.humMin.value;
    final int humMaxValue = humMax ?? AppRuntimeConfig.humMax.value;
    final int moistMinValue = moistMin ?? AppRuntimeConfig.moistMin.value;
    final int moistMaxValue = moistMax ?? AppRuntimeConfig.moistMax.value;

    if (!_validateRangeValues(
          tempMinValue,
          tempMaxValue,
          AppRuntimeConfig.tempLowerBound,
          AppRuntimeConfig.tempUpperBound,
        ) ||
        !_validateRangeValues(
          humMinValue,
          humMaxValue,
          AppRuntimeConfig.humLowerBound,
          AppRuntimeConfig.humUpperBound,
        ) ||
        !_validateRangeValues(
          moistMinValue,
          moistMaxValue,
          AppRuntimeConfig.moistLowerBound,
          AppRuntimeConfig.moistUpperBound,
        )) {
      _showError(
        'يرجى الحفاظ على درجة الحرارة والرطوبة والرطوبة داخل الحدود الصالحة وأن يكون الحد الأدنى أقل من أو يساوي الحد الأقصى.',
      );
      return;
    }

    try {
      await _syncAutoWaterToRealtimeDatabase(
        tempMin: tempMinValue,
        tempMax: tempMaxValue,
        humMin: humMinValue,
        humMax: humMaxValue,
        moistMin: moistMinValue,
        moistMax: moistMaxValue,
      );
      await AppRuntimeConfig.setAutoWaterTargets(
        tempMinValue: tempMinValue,
        tempMaxValue: tempMaxValue,
        humMinValue: humMinValue,
        humMaxValue: humMaxValue,
        moistMinValue: moistMinValue,
        moistMaxValue: moistMaxValue,
      );
      _showSuccess('تم حفظ إعدادات الري التلقائي ومزامنتها.');
    } catch (error) {
      _showError('مزامنة Firebase فشلت: $error');
    }
  }

  Future<void> _saveAutoFertilizerConfig({
    int? nMin,
    int? nMax,
    int? pMin,
    int? pMax,
    int? kMin,
    int? kMax,
  }) async {
    final int nMinValue = nMin ?? AppRuntimeConfig.nMin.value;
    final int nMaxValue = nMax ?? AppRuntimeConfig.nMax.value;
    final int pMinValue = pMin ?? AppRuntimeConfig.pMin.value;
    final int pMaxValue = pMax ?? AppRuntimeConfig.pMax.value;
    final int kMinValue = kMin ?? AppRuntimeConfig.kMin.value;
    final int kMaxValue = kMax ?? AppRuntimeConfig.kMax.value;
    const String leafGoalValue = 'Healthy';

    if (!_validateRangeValues(
          nMinValue,
          nMaxValue,
          AppRuntimeConfig.nutrientLowerBound,
          AppRuntimeConfig.nutrientUpperBound,
        ) ||
        !_validateRangeValues(
          pMinValue,
          pMaxValue,
          AppRuntimeConfig.nutrientLowerBound,
          AppRuntimeConfig.nutrientUpperBound,
        ) ||
        !_validateRangeValues(
          kMinValue,
          kMaxValue,
          AppRuntimeConfig.nutrientLowerBound,
          AppRuntimeConfig.nutrientUpperBound,
        )) {
      _showError(
        'يرجى الحفاظ على N/P/K داخل الحدود الصالحة وأن يكون الحد الأدنى أقل من أو يساوي الحد الأقصى.',
      );
      return;
    }

    try {
      await _syncAutoFertilizerToRealtimeDatabase(
        nMin: nMinValue,
        nMax: nMaxValue,
        pMin: pMinValue,
        pMax: pMaxValue,
        kMin: kMinValue,
        kMax: kMaxValue,
        leafGoal: leafGoalValue,
      );
      await AppRuntimeConfig.setAutoFertilizerTargets(
        nMinValue: nMinValue,
        nMaxValue: nMaxValue,
        pMinValue: pMinValue,
        pMaxValue: pMaxValue,
        kMinValue: kMinValue,
        kMaxValue: kMaxValue,
        leafGoalValue: leafGoalValue,
      );
      _showSuccess('تم حفظ إعدادات التسميد التلقائي ومزامنتها.');
    } catch (error) {
      _showError('مزامنة Firebase فشلت: $error');
    }
  }

  Future<void> _editTempRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'نطاق درجة حرارة الري التلقائي',
      minLabel: 'الحد الأدنى لدرجة الحرارة (°م)',
      maxLabel: 'الحد الأقصى لدرجة الحرارة (°م)',
      minValue: AppRuntimeConfig.tempMin.value,
      maxValue: AppRuntimeConfig.tempMax.value,
      minAllowed: AppRuntimeConfig.tempLowerBound,
      maxAllowed: AppRuntimeConfig.tempUpperBound,
    );

    if (range == null ||
        !_validateRangeValues(
          range[0],
          range[1],
          AppRuntimeConfig.tempLowerBound,
          AppRuntimeConfig.tempUpperBound,
        )) {
      if (range != null) {
        _showError(
          'يرجى الحفاظ على درجة الحرارة داخل الحدود وأن يكون الحد الأدنى أقل من أو يساوي الحد الأقصى.',
        );
      }
      return;
    }

    await _saveAutoWaterConfig(tempMin: range[0], tempMax: range[1]);
  }

  Future<void> _editHumidityRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'نطاق رطوبة الري التلقائي',
      minLabel: 'الحد الأدنى للرطوبة (%)',
      maxLabel: 'الحد الأقصى للرطوبة (%)',
      minValue: AppRuntimeConfig.humMin.value,
      maxValue: AppRuntimeConfig.humMax.value,
      minAllowed: AppRuntimeConfig.humLowerBound,
      maxAllowed: AppRuntimeConfig.humUpperBound,
    );

    if (range == null ||
        !_validateRangeValues(
          range[0],
          range[1],
          AppRuntimeConfig.humLowerBound,
          AppRuntimeConfig.humUpperBound,
        )) {
      if (range != null) {
        _showError(
          'يرجى الحفاظ على الرطوبة داخل الحدود وأن يكون الحد الأدنى أقل من أو يساوي الحد الأقصى.',
        );
      }
      return;
    }

    await _saveAutoWaterConfig(humMin: range[0], humMax: range[1]);
  }

  Future<void> _editMoistureRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'نطاق رطوبة التربة للري التلقائي',
      minLabel: 'الحد الأدنى لرطوبة التربة (%)',
      maxLabel: 'الحد الأقصى لرطوبة التربة (%)',
      minValue: AppRuntimeConfig.moistMin.value,
      maxValue: AppRuntimeConfig.moistMax.value,
      minAllowed: AppRuntimeConfig.moistLowerBound,
      maxAllowed: AppRuntimeConfig.moistUpperBound,
    );

    if (range == null ||
        !_validateRangeValues(
          range[0],
          range[1],
          AppRuntimeConfig.moistLowerBound,
          AppRuntimeConfig.moistUpperBound,
        )) {
      if (range != null) {
        _showError(
          'يرجى الحفاظ على الرطوبة داخل الحدود وأن يكون الحد الأدنى أقل من أو يساوي الحد الأقصى.',
        );
      }
      return;
    }

    await _saveAutoWaterConfig(moistMin: range[0], moistMax: range[1]);
  }

  Future<void> _editNitrogenRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'نطاق النيتروجين في التسميد التلقائي',
      minLabel: 'الحد الأدنى للنيتروجين',
      maxLabel: 'الحد الأقصى للنيتروجين',
      minValue: AppRuntimeConfig.nMin.value,
      maxValue: AppRuntimeConfig.nMax.value,
      minAllowed: AppRuntimeConfig.nutrientLowerBound,
      maxAllowed: AppRuntimeConfig.nutrientUpperBound,
    );

    if (range == null ||
        !_validateRangeValues(
          range[0],
          range[1],
          AppRuntimeConfig.nutrientLowerBound,
          AppRuntimeConfig.nutrientUpperBound,
        )) {
      if (range != null) {
        _showError(
          'يرجى الحفاظ على النيتروجين داخل الحدود وأن يكون الحد الأدنى أقل من أو يساوي الحد الأقصى.',
        );
      }
      return;
    }

    await _saveAutoFertilizerConfig(nMin: range[0], nMax: range[1]);
  }

  Future<void> _editPhosphorusRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'نطاق الفوسفور في التسميد التلقائي',
      minLabel: 'الحد الأدنى للفوسفور',
      maxLabel: 'الحد الأقصى للفوسفور',
      minValue: AppRuntimeConfig.pMin.value,
      maxValue: AppRuntimeConfig.pMax.value,
      minAllowed: AppRuntimeConfig.nutrientLowerBound,
      maxAllowed: AppRuntimeConfig.nutrientUpperBound,
    );

    if (range == null ||
        !_validateRangeValues(
          range[0],
          range[1],
          AppRuntimeConfig.nutrientLowerBound,
          AppRuntimeConfig.nutrientUpperBound,
        )) {
      if (range != null) {
        _showError(
          'يرجى الحفاظ على الفوسفور داخل الحدود وأن يكون الحد الأدنى أقل من أو يساوي الحد الأقصى.',
        );
      }
      return;
    }

    await _saveAutoFertilizerConfig(pMin: range[0], pMax: range[1]);
  }

  Future<void> _editPotassiumRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'نطاق البوتاسيوم في التسميد التلقائي',
      minLabel: 'الحد الأدنى للبوتاسيوم',
      maxLabel: 'الحد الأقصى للبوتاسيوم',
      minValue: AppRuntimeConfig.kMin.value,
      maxValue: AppRuntimeConfig.kMax.value,
      minAllowed: AppRuntimeConfig.nutrientLowerBound,
      maxAllowed: AppRuntimeConfig.nutrientUpperBound,
    );

    if (range == null ||
        !_validateRangeValues(
          range[0],
          range[1],
          AppRuntimeConfig.nutrientLowerBound,
          AppRuntimeConfig.nutrientUpperBound,
        )) {
      if (range != null) {
        _showError(
          'يرجى الحفاظ على البوتاسيوم داخل الحدود وأن يكون الحد الأدنى أقل من أو يساوي الحد الأقصى.',
        );
      }
      return;
    }

    await _saveAutoFertilizerConfig(kMin: range[0], kMax: range[1]);
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
          _SectionCard(
            title: 'إعدادات الري التلقائي',
            subtitle: 'حدود درجة الحرارة والرطوبة ورطوبة التربة للري',
            children: <Widget>[
              _EditableTile(
                label: 'درجة الحرارة',
                value:
                    '${AppRuntimeConfig.tempMin.value} °م - ${AppRuntimeConfig.tempMax.value} °م',
                onTap: _editTempRange,
                trailingIcon: Icons.add,
              ),
              _EditableTile(
                label: 'الرطوبة',
                value:
                    '${AppRuntimeConfig.humMin.value}% - ${AppRuntimeConfig.humMax.value}%',
                onTap: _editHumidityRange,
                trailingIcon: Icons.add,
              ),
              _EditableTile(
                label: 'رطوبة التربة',
                value:
                    '${AppRuntimeConfig.moistMin.value}% - ${AppRuntimeConfig.moistMax.value}%',
                onTap: _editMoistureRange,
                trailingIcon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'إعدادات التسميد التلقائي',
            subtitle: 'حدود N و P و K مع هدف الورقة للعرض فقط',
            children: <Widget>[
              ValueListenableBuilder<int>(
                valueListenable: AppRuntimeConfig.nMin,
                builder: (context, nMin, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: AppRuntimeConfig.nMax,
                    builder: (context, nMax, __) {
                      return _EditableTile(
                        label: 'النيتروجين (N)',
                        value: '$nMin - $nMax',
                        onTap: _editNitrogenRange,
                        trailingIcon: Icons.add,
                      );
                    },
                  );
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: AppRuntimeConfig.pMin,
                builder: (context, pMin, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: AppRuntimeConfig.pMax,
                    builder: (context, pMax, __) {
                      return _EditableTile(
                        label: 'الفوسفور (P)',
                        value: '$pMin - $pMax',
                        onTap: _editPhosphorusRange,
                        trailingIcon: Icons.add,
                      );
                    },
                  );
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: AppRuntimeConfig.kMin,
                builder: (context, kMin, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: AppRuntimeConfig.kMax,
                    builder: (context, kMax, __) {
                      return _EditableTile(
                        label: 'البوتاسيوم (K)',
                        value: '$kMin - $kMax',
                        onTap: _editPotassiumRange,
                        trailingIcon: Icons.add,
                      );
                    },
                  );
                },
              ),
              const _SimpleTile(
                label: 'هدف الورقة',
                value: 'سليم (للقراءة فقط)',
                icon: Icons.lock_outline,
              ),
            ],
          ),
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
          _PumpControlSection(database: _database),
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
