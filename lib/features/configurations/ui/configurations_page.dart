import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../firebase_data/models/farm_payload.dart';

class ConfigurationsPage extends StatefulWidget {
  const ConfigurationsPage({super.key});

  @override
  State<ConfigurationsPage> createState() => _ConfigurationsPageState();
}

class _ConfigurationsPageState extends State<ConfigurationsPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final int? value = int.tryParse(controller.text.trim());
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Save'),
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
              child: const Text('Cancel'),
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  int? _parseAndValidateBoundedValue(
    String raw,
    int minAllowed,
    int maxAllowed,
  ) {
    final int? value = int.tryParse(raw.trim());
    if (value == null) return null;
    if (value < minAllowed || value > maxAllowed) return null;
    return value;
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
        'Please keep temperature/humidity/moisture inside valid bounds and min <= max.',
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
      _showSuccess('Auto water config saved and synced.');
    } catch (error) {
      _showError('Firebase sync failed: $error');
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
      _showError('Please keep N/P/K inside valid bounds and min <= max.');
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
      _showSuccess('Auto fertilizer config saved and synced.');
    } catch (error) {
      _showError('Firebase sync failed: $error');
    }
  }

  Future<void> _editTempRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'Auto water temperature range',
      minLabel: 'Temperature min (C)',
      maxLabel: 'Temperature max (C)',
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
        _showError('Please keep temperature within bounds and min <= max.');
      }
      return;
    }

    await _saveAutoWaterConfig(tempMin: range[0], tempMax: range[1]);
  }

  Future<void> _editHumidityRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'Auto water humidity range',
      minLabel: 'Humidity min (%)',
      maxLabel: 'Humidity max (%)',
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
        _showError('Please keep humidity within bounds and min <= max.');
      }
      return;
    }

    await _saveAutoWaterConfig(humMin: range[0], humMax: range[1]);
  }

  Future<void> _editMoistureRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'Auto water moisture range',
      minLabel: 'Moisture min (%)',
      maxLabel: 'Moisture max (%)',
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
        _showError('Please keep moisture within bounds and min <= max.');
      }
      return;
    }

    await _saveAutoWaterConfig(moistMin: range[0], moistMax: range[1]);
  }

  Future<void> _editNitrogenRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'Auto fertilizer nitrogen range',
      minLabel: 'Nitrogen min',
      maxLabel: 'Nitrogen max',
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
        _showError('Please keep nitrogen within bounds and min <= max.');
      }
      return;
    }

    await _saveAutoFertilizerConfig(nMin: range[0], nMax: range[1]);
  }

  Future<void> _editPhosphorusRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'Auto fertilizer phosphorus range',
      minLabel: 'Phosphorus min',
      maxLabel: 'Phosphorus max',
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
        _showError('Please keep phosphorus within bounds and min <= max.');
      }
      return;
    }

    await _saveAutoFertilizerConfig(pMin: range[0], pMax: range[1]);
  }

  Future<void> _editPotassiumRange() async {
    final List<int>? range = await _showBoundedRangeDialog(
      title: 'Auto fertilizer potassium range',
      minLabel: 'Potassium min',
      maxLabel: 'Potassium max',
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
        _showError('Please keep potassium within bounds and min <= max.');
      }
      return;
    }

    await _saveAutoFertilizerConfig(kMin: range[0], kMax: range[1]);
  }

  Future<void> _editReuploadDelay() async {
    final int? value = await _showBoundedNumberDialog(
      title: 'Edit reupload delay',
      label: 'Days',
      initialValue: AppRuntimeConfig.diseaseReuploadDelayDays.value,
      minAllowed: 1,
      maxAllowed: 365,
      hintText: 'Enter 1 to 365 days',
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
        _showSuccess('Leaf status updated to: $status');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update status: $e');
      }
    }
  }

  Future<String?> _showStatusDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Leaf Status'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Status',
              hintText: 'e.g., Healthy, LateBlight, EarlyBlight',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String value = controller.text.trim();
                Navigator.pop(dialogContext, value.isNotEmpty ? value : null);
              },
              child: const Text('Save'),
            ),
          ],
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
            stream: _database.ref(FarmPayload.leafPath).onValue,
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
              final String leafStatus = '${leaf['status'] ?? 'Healthy'}';
              final bool hasDisease =
                  leafStatus.toLowerCase() != 'healthy' &&
                  leafStatus.isNotEmpty;
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
            title: 'Auto Water Config',
            subtitle: 'Temperature, humidity, and moisture limits for watering',
            children: <Widget>[
              _EditableTile(
                label: 'Temperature',
                value:
                    '${AppRuntimeConfig.tempMin.value} C - ${AppRuntimeConfig.tempMax.value} C',
                onTap: _editTempRange,
                trailingIcon: Icons.add,
              ),
              _EditableTile(
                label: 'Humidity',
                value:
                    '${AppRuntimeConfig.humMin.value}% - ${AppRuntimeConfig.humMax.value}%',
                onTap: _editHumidityRange,
                trailingIcon: Icons.add,
              ),
              _EditableTile(
                label: 'Moisture',
                value:
                    '${AppRuntimeConfig.moistMin.value}% - ${AppRuntimeConfig.moistMax.value}%',
                onTap: _editMoistureRange,
                trailingIcon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Auto Fertilizer Config',
            subtitle: 'N, P, K limits with leaf goal shown read-only',
            children: <Widget>[
              _EditableTile(
                label: 'Nitrogen (N)',
                value:
                    '${AppRuntimeConfig.nMin.value} - ${AppRuntimeConfig.nMax.value}',
                onTap: _editNitrogenRange,
                trailingIcon: Icons.add,
              ),
              _EditableTile(
                label: 'Phosphorus (P)',
                value:
                    '${AppRuntimeConfig.pMin.value} - ${AppRuntimeConfig.pMax.value}',
                onTap: _editPhosphorusRange,
                trailingIcon: Icons.add,
              ),
              _EditableTile(
                label: 'Potassium (K)',
                value:
                    '${AppRuntimeConfig.kMin.value} - ${AppRuntimeConfig.kMax.value}',
                onTap: _editPotassiumRange,
                trailingIcon: Icons.add,
              ),
              const _SimpleTile(
                label: 'Leaf goal',
                value: 'Healthy (read-only)',
                icon: Icons.lock_outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<DatabaseEvent>(
            stream: _database.ref(FarmPayload.leafPath).onValue,
            builder: (context, snapshot) {
              final Map<String, dynamic> leaf = _toMap(
                snapshot.data?.snapshot.value,
              );
              final String currentStatus = '${leaf['status'] ?? 'Healthy'}';
              return _SectionCard(
                title: 'Detection Rules',
                subtitle: 'User-facing controls only',
                children: <Widget>[
                  _EditableTile(
                    label: 'Leaf Status',
                    value: currentStatus,
                    onTap: _editLeafStatus,
                  ),
                  _EditableTile(
                    label: 'Disease reupload delay',
                    value:
                        '${AppRuntimeConfig.diseaseReuploadDelayDays.value} days',
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
            title: 'What You Need',
            subtitle: 'Minimal checklist for a clean farm workflow',
            children: const <Widget>[
              _ChecklistTile(text: 'Firebase Realtime Database connected'),
              _ChecklistTile(text: 'Cucumber leaf images clear enough for AI'),
              _ChecklistTile(text: 'Correct min and max crop thresholds'),
              _ChecklistTile(text: 'Notifications enabled for disease alerts'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PumpControlSection extends StatelessWidget {
  const _PumpControlSection({required this.database});
  final FirebaseDatabase database;

  Future<void> _handleManualToggle(
    DatabaseReference pumpRef,
    String pumpName,
    bool newValue,
  ) async {
    try {
      // 1. Capture "Before" state snapshot
      final DataSnapshot dataSnapshot = await FarmPayload.rootRef(
        database,
      ).get();
      final Map<dynamic, dynamic> currentData =
          dataSnapshot.value as Map? ?? {};
      final Map<dynamic, dynamic> sensors =
          currentData['sensors'] as Map? ?? {};
      final Map<dynamic, dynamic> leaf = currentData['leaf'] as Map? ?? {};

      // 2. Perform the toggle
      await pumpRef.set(newValue);

      // 3. Push a simplified manual log
      final String logId = 'manual_${DateTime.now().millisecondsSinceEpoch}';

      final Map<String, dynamic> sensorsData = _toMap(currentData['sensors']);
      final Map<String, dynamic> leafData = _toMap(currentData['leaf']);

      await database.ref('${FarmPayload.manualLogsPath}/$logId').set({
        'time': DateTime.now().toUtc().toIso8601String(),
        'action': '${newValue ? 'ON' : 'OFF'}',
        'pump': pumpName,
        'state': {
          'temp': sensorsData['temp'] ?? 0,
          'moist': sensorsData['moist'] ?? 0,
          'hum': sensorsData['hum'] ?? 0,
          'n': sensorsData['n'] ?? 0,
          'p': sensorsData['p'] ?? 0,
          'k': sensorsData['k'] ?? 0,
          'status': leafData['status'] ?? 'Unknown',
        },
      });
    } catch (e) {
      debugPrint('Manual log failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: database.ref(FarmPayload.pumpsPath).onValue,
      builder: (context, snapshot) {
        final Map<String, dynamic> data = _toMap(snapshot.data?.snapshot.value);
        final bool isAuto = data['auto'] == true;
        final bool isWater = data['water'] == true;
        final bool isFert1 = data['fert1'] == true;
        final bool isFert2 = data['fert2'] == true;

        return _SectionCard(
          title: 'Pump & Mode Control',
          subtitle: 'Override auto systems or toggle manual state',
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto Control Mode'),
              subtitle: const Text('Let the system handle pumps automatically'),
              value: isAuto,
              onChanged: (bool value) {
                database.ref('${FarmPayload.pumpsPath}/auto').set(value);
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
                      title: const Text('Water Pump'),
                      subtitle: const Text('Manual override for irrigation'),
                      value: isWater,
                      onChanged: (bool value) {
                        _handleManualToggle(
                          database.ref('${FarmPayload.pumpsPath}/water'),
                          'Water',
                          value,
                        );
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fertilizer Pump 1'),
                      subtitle: const Text('Manual override for nutrients (1)'),
                      value: isFert1,
                      onChanged: (bool value) {
                        _handleManualToggle(
                          database.ref('${FarmPayload.pumpsPath}/fert1'),
                          'Fertilizer 1',
                          value,
                        );
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fertilizer Pump 2'),
                      subtitle: const Text('Manual override for nutrients (2)'),
                      value: isFert2,
                      onChanged: (bool value) {
                        _handleManualToggle(
                          database.ref('${FarmPayload.pumpsPath}/fert2'),
                          'Fertilizer 2',
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
            'Farm Configurations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tune the detection and crop targets from one screen.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoChip(label: 'Reupload', value: '$diseaseReuploadDays days'),
              _InfoChip(
                label: hasDisease ? 'Disease' : 'Status',
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
