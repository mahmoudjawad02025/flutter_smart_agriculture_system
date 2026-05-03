import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_agriculture_system/core/config/app_runtime_config.dart';
import 'package:flutter_smart_agriculture_system/core/di/app_di.dart';
import 'package:flutter_smart_agriculture_system/features/configurations/domain/usecases/pump_controls.dart';
import 'package:flutter_smart_agriculture_system/features/configurations/domain/usecases/update_crop_targets.dart';

class ConfigurationsPage extends StatefulWidget {
  const ConfigurationsPage({super.key});

  @override
  State<ConfigurationsPage> createState() => _ConfigurationsPageState();
}

class _ConfigurationsPageState extends State<ConfigurationsPage> {
  final UpdateCropTargets _updateCropTargets =
      AppDi.provideUpdateCropTargetsUsecase();

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

  Future<int?> _showPositiveNumberDialog({
    required String title,
    required String label,
    required int initialValue,
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
              FilteringTextInputFormatter.digitsOnly,
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

  Future<List<int>?> _showPositiveRangeDialog({
    required String title,
    required String minLabel,
    required String maxLabel,
    required int minValue,
    required int maxValue,
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
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(labelText: minLabel),
              ),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
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

  Future<void> _saveCropTargets({
    int? moistMin,
    int? moistMax,
    int? nMin,
    int? nMax,
    int? pMin,
    int? pMax,
    int? kMin,
    int? kMax,
  }) async {
    final int moistMinValue = moistMin ?? AppRuntimeConfig.moistMin.value;
    final int moistMaxValue = moistMax ?? AppRuntimeConfig.moistMax.value;
    final int nMinValue = nMin ?? AppRuntimeConfig.nMin.value;
    final int nMaxValue = nMax ?? AppRuntimeConfig.nMax.value;
    final int pMinValue = pMin ?? AppRuntimeConfig.pMin.value;
    final int pMaxValue = pMax ?? AppRuntimeConfig.pMax.value;
    final int kMinValue = kMin ?? AppRuntimeConfig.kMin.value;
    final int kMaxValue = kMax ?? AppRuntimeConfig.kMax.value;
    const String leafGoalValue = 'Healthy';

    try {
      await _updateCropTargets.call(
        moistMin: moistMinValue,
        moistMax: moistMaxValue,
        nMin: nMinValue,
        nMax: nMaxValue,
        pMin: pMinValue,
        pMax: pMaxValue,
        kMin: kMinValue,
        kMax: kMaxValue,
        leafGoal: leafGoalValue,
      );

      await AppRuntimeConfig.setCropTargets(
        moistMinValue: moistMinValue,
        moistMaxValue: moistMaxValue,
        nMinValue: nMinValue,
        nMaxValue: nMaxValue,
        pMinValue: pMinValue,
        pMaxValue: pMaxValue,
        kMinValue: kMinValue,
        kMaxValue: kMaxValue,
        leafGoalValue: leafGoalValue,
      );

      _showSuccess('Saved and synced to Realtime Database.');
    } catch (error) {
      _showError('Firebase sync failed: $error');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editReuploadDelay() async {
    final int? value = await _showPositiveNumberDialog(
      title: 'Edit reupload delay',
      label: 'Days',
      initialValue: AppRuntimeConfig.diseaseReuploadDelayDays.value,
      hintText: 'Enter positive number of days',
    );

    if (value == null || value < 1) {
      if (value != null) {
        _showError('Please enter a positive number.');
      }
      return;
    }

    await AppRuntimeConfig.setDiseaseReuploadDelayDays(value);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editMoistureRange() async {
    final List<int>? range = await _showPositiveRangeDialog(
      title: 'Edit moisture range',
      minLabel: 'Moisture min (%)',
      maxLabel: 'Moisture max (%)',
      minValue: AppRuntimeConfig.moistMin.value,
      maxValue: AppRuntimeConfig.moistMax.value,
    );

    if (range == null || range[0] < 1 || range[1] < 1 || range[0] > range[1]) {
      if (range != null) {
        _showError('Please enter positive values and ensure min <= max.');
      }
      return;
    }

    await _saveCropTargets(moistMin: range[0], moistMax: range[1]);
  }

  Future<void> _editNitrogenRange() async {
    final List<int>? range = await _showPositiveRangeDialog(
      title: 'Edit nitrogen range',
      minLabel: 'Nitrogen min',
      maxLabel: 'Nitrogen max',
      minValue: AppRuntimeConfig.nMin.value,
      maxValue: AppRuntimeConfig.nMax.value,
    );

    if (range == null || range[0] < 1 || range[1] < 1 || range[0] > range[1]) {
      if (range != null) {
        _showError('Please enter positive values and ensure min <= max.');
      }
      return;
    }

    await _saveCropTargets(nMin: range[0], nMax: range[1]);
  }

  Future<void> _editPhosphorusRange() async {
    final List<int>? range = await _showPositiveRangeDialog(
      title: 'Edit phosphorus range',
      minLabel: 'Phosphorus min',
      maxLabel: 'Phosphorus max',
      minValue: AppRuntimeConfig.pMin.value,
      maxValue: AppRuntimeConfig.pMax.value,
    );

    if (range == null || range[0] < 1 || range[1] < 1 || range[0] > range[1]) {
      if (range != null) {
        _showError('Please enter positive values and ensure min <= max.');
      }
      return;
    }

    await _saveCropTargets(pMin: range[0], pMax: range[1]);
  }

  Future<void> _editPotassiumRange() async {
    final List<int>? range = await _showPositiveRangeDialog(
      title: 'Edit potassium range',
      minLabel: 'Potassium min',
      maxLabel: 'Potassium max',
      minValue: AppRuntimeConfig.kMin.value,
      maxValue: AppRuntimeConfig.kMax.value,
    );

    if (range == null || range[0] < 1 || range[1] < 1 || range[0] > range[1]) {
      if (range != null) {
        _showError('Please enter positive values and ensure min <= max.');
      }
      return;
    }

    await _saveCropTargets(kMin: range[0], kMax: range[1]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _HeaderCard(
            diseaseReuploadDays:
                AppRuntimeConfig.diseaseReuploadDelayDays.value,
            healthyKeywords: AppRuntimeConfig.healthyKeywords.value,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Crop Targets',
            subtitle: 'Min and max ranges used by the farm system (+ to edit)',
            children: <Widget>[
              _EditableTile(
                label: 'Moisture',
                value:
                    '${AppRuntimeConfig.moistMin.value}% - ${AppRuntimeConfig.moistMax.value}%',
                onTap: _editMoistureRange,
                trailingIcon: Icons.add,
              ),
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
          const _PumpControlSection(),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Detection Rules',
            subtitle: 'User-facing controls only',
            children: <Widget>[
              _EditableTile(
                label: 'Disease reupload delay',
                value:
                    '${AppRuntimeConfig.diseaseReuploadDelayDays.value} days',
                onTap: _editReuploadDelay,
              ),
            ],
          ),
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
  const _PumpControlSection();

  Future<void> _handleManualToggle({
    required String pumpKey,
    required String pumpName,
    required bool value,
  }) async {
    try {
      await AppDi.provideSetManualPumpStateUsecase().call(
        pumpKey: pumpKey,
        pumpName: pumpName,
        value: value,
      );
    } catch (error) {
      debugPrint('Manual log failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final WatchPumps watchPumps = AppDi.provideWatchPumpsUsecase();
    final SetPumpAutoMode setAutoMode = AppDi.provideSetPumpAutoModeUsecase();

    return StreamBuilder<Map<String, dynamic>?>(
      stream: watchPumps.call(),
      builder: (context, snapshot) {
        final Map<String, dynamic> data = _toMap(snapshot.data);
        final bool isAuto = data['auto'] == true;
        final bool isWater = data['water'] == true;
        final bool isFert = data['fert'] == true;

        return _SectionCard(
          title: 'Pump & Mode Control',
          subtitle: 'Override auto systems or toggle manual state',
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto Control Mode'),
              subtitle: const Text('Let the system handle pumps automatically'),
              value: isAuto,
              onChanged: setAutoMode.call,
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
                          pumpKey: 'water',
                          pumpName: 'Water',
                          value: value,
                        );
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fertilizer Pump'),
                      subtitle: const Text('Manual override for nutrients'),
                      value: isFert,
                      onChanged: (bool value) {
                        _handleManualToggle(
                          pumpKey: 'fert',
                          pumpName: 'Fertilizer',
                          value: value,
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
  });

  final int diseaseReuploadDays;
  final List<String> healthyKeywords;

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
              _InfoChip(label: 'Healthy', value: healthyKeywords.join(' • ')),
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

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({
    required this.label,
    required this.value,
    required this.icon,
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
