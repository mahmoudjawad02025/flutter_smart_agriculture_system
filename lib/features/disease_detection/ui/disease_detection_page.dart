import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_runtime_config.dart';
import '../cubit/disease_detection_cubit.dart';
import '../cubit/disease_detection_state.dart';
import '../models/detection_result.dart';

const String _appIconAsset = 'lib/core/media/icons/app/app.png';

class DiseaseDetectionPage extends StatelessWidget {
  const DiseaseDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer<DiseaseDetectionCubit, DiseaseDetectionState>(
        listenWhen:
            (DiseaseDetectionState previous, DiseaseDetectionState current) {
              return previous.errorMessage != current.errorMessage &&
                  current.errorMessage != null;
            },
        listener: (BuildContext context, DiseaseDetectionState state) {
          final String? message = state.errorMessage;
          if (message == null || message.isEmpty) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (BuildContext context, DiseaseDetectionState state) {
          final DiseaseDetectionCubit cubit = context
              .read<DiseaseDetectionCubit>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _AiHeroCard(isAnalyzing: state.isAnalyzing),
                const SizedBox(height: 16),
                _ImagePreview(
                  path: state.imagePath,
                  refreshToken: state.previewRevision,
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isAnalyzing
                            ? null
                            : cubit.pickImageAndSave,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('رفع صورة'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (!state.hasImage || state.isAnalyzing)
                            ? null
                            : cubit.analyzeImage,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('تحليل'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'نتيجة التحليل',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (state.isAnalyzing) ...<Widget>[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        children: <Widget>[
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('جارٍ تحليل الصورة...'),
                        ],
                      ),
                    ),
                  ),
                ] else if (state.result != null) ...<Widget>[
                  _ResultView(result: state.result!),
                ] else ...<Widget>[
                  const _EmptyResultCard(
                    message: 'لا توجد نتيجة تحليل بعد. ارفع صورة واضغط تحليل.',
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ImagePreview extends StatefulWidget {
  const _ImagePreview({this.path, required this.refreshToken});

  final String? path;
  final int refreshToken;

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  @override
  void didUpdateWidget(covariant _ImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.path != widget.path ||
            oldWidget.refreshToken != widget.refreshToken) &&
        widget.path != null) {
      imageCache.clear();
      imageCache.clearLiveImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.path == null || widget.path!.isEmpty) {
      return const _ImageFrame(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('لم يتم اختيار صورة', textAlign: TextAlign.center),
        ),
      );
    }

    final File imageFile = File(widget.path!);
    if (!imageFile.existsSync()) {
      return const _ImageFrame(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'الصورة المحفوظة غير موجودة في الجهاز.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _ImageFrame(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.file(
          imageFile,
          key: ValueKey<String>('${widget.path!}_${widget.refreshToken}'),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class _ImageFrame extends StatelessWidget {
  const _ImageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        color: Colors.white,
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }
}

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard({required this.isAnalyzing});

  final bool isAnalyzing;

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
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              _appIconAsset,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'كشف أمراض الأوراق بالذكاء الاصطناعي',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAnalyzing
                      ? 'النموذج يحلل صورتك...'
                      : 'ارفع صورة واضحة للورقة للحصول على نتائج سريعة من AI.',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _translateDiseaseLabel(String label) {
  final String normalized = label.toLowerCase().replaceAll(
    RegExp(r'[_\s-]'),
    '',
  );
  switch (normalized) {
    case 'healthy':
      return 'سليم';
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
      return label;
  }
}

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.hourglass_empty_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _PredictionsDetailView extends StatelessWidget {
  const _PredictionsDetailView({required this.result});
  final DetectionResult result;

  List<_PredictionItem> _extractPredictions(Map<String, dynamic> json) {
    final Map<String, double> predictions = <String, double>{};

    void collectClassConfidence(Map<String, dynamic> node) {
      final String className = node['class'] as String? ?? '';
      final double conf = (node['confidence'] as num?)?.toDouble() ?? 0.0;
      if (className.isNotEmpty) {
        predictions[className] = conf;
      }
    }

    void collectProbabilityMap(dynamic node) {
      if (node is Map) {
        if (node.containsKey('probabilities')) {
          final dynamic probabilityNode = node['probabilities'];
          if (probabilityNode is Map) {
            for (final MapEntry<dynamic, dynamic> entry
                in probabilityNode.entries) {
              final String label = entry.key?.toString() ?? '';
              final double value = _normalizeConfidenceValue(entry.value);
              if (label.isNotEmpty && value > 0) {
                predictions[label] = value;
              }
            }
          }
        } else {
          final bool allValuesNumeric = node.values.every(
            (dynamic value) =>
                value is num ||
                value is String &&
                    (double.tryParse(value) != null ||
                        value == 'true' ||
                        value == 'false'),
          );
          final bool hasLabelLikeKey = node.keys.every(
            (dynamic key) =>
                key is String &&
                key.isNotEmpty &&
                key != 'confidence' &&
                key != 'class',
          );

          if (allValuesNumeric && hasLabelLikeKey && node.length >= 2) {
            for (final MapEntry<dynamic, dynamic> entry in node.entries) {
              final String label = entry.key?.toString() ?? '';
              if (label == 'confidence' || label == 'class') continue;
              final double value = _normalizeConfidenceValue(entry.value);
              if (label.isNotEmpty && value > 0) {
                predictions[label] = value;
              }
            }
          }
        }
      }
    }

    void traverse(dynamic node) {
      if (node is Map) {
        final map = node as Map<String, dynamic>;
        if (map.containsKey('confidence') && map.containsKey('class')) {
          collectClassConfidence(map);
        }
        collectProbabilityMap(map);
        map.forEach((key, value) {
          traverse(value);
        });
      } else if (node is List) {
        for (final item in node) {
          traverse(item);
        }
      }
    }

    traverse(json);

    return predictions.entries
        .map((e) => _PredictionItem(className: e.key, confidence: e.value))
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// Normalize confidence values that might be in different formats
  /// (e.g., 0.95, 95, 95.0, "true"/"false", etc.)
  double _normalizeConfidenceValue(dynamic value) {
    if (value is num) {
      final double numValue = value.toDouble();
      // If value is > 1, assume it's a percentage (0-100)
      if (numValue > 1) {
        return (numValue / 100).clamp(0.0, 1.0);
      }
      return numValue.clamp(0.0, 1.0);
    }

    if (value is String) {
      if (value.toLowerCase() == 'true') return 1.0;
      if (value.toLowerCase() == 'false') return 0.0;

      final double? parsed = double.tryParse(value);
      if (parsed != null) {
        // If value is > 1, assume it's a percentage (0-100)
        if (parsed > 1) {
          return (parsed / 100).clamp(0.0, 1.0);
        }
        return parsed.clamp(0.0, 1.0);
      }
    }

    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final List<_PredictionItem> predictions = _extractPredictions(
      result.rawJson,
    );

    if (predictions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'لا توجد بيانات تنبؤات متاحة.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Separate 100% predictions from others for better visibility
    final List<_PredictionItem> fullConfPredictions = predictions
        .where((p) => p.confidence >= 0.999)
        .toList();
    final List<_PredictionItem> otherPredictions = predictions
        .where((p) => p.confidence < 0.999)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'تفصيل التنبؤات',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: <Widget>[
              // Display 100% predictions first with highlight
              if (fullConfPredictions.isNotEmpty) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'نتائج بثقة عالية 100%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: fullConfPredictions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final pred = fullConfPredictions[index];
                          return _PredictionCard(
                            className: pred.className,
                            confidence: pred.confidence,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (otherPredictions.isNotEmpty) const SizedBox(height: 12),
              ],

              // Display other predictions
              if (otherPredictions.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: otherPredictions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final pred = otherPredictions[index];
                    return _PredictionCard(
                      className: pred.className,
                      confidence: pred.confidence,
                    );
                  },
                ),
            ],
          ),
        ),
        // Info text showing total predictions
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'إجمالي النتائج: ${predictions.length}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

class _PredictionItem {
  _PredictionItem({required this.className, required this.confidence});
  final String className;
  final double confidence;
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.className, required this.confidence});
  final String className;
  final double confidence;

  Color _getConfidenceColor(double conf) {
    if (conf >= 0.8) return Colors.green;
    if (conf >= 0.6) return Colors.orange;
    if (conf >= 0.4) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _translateDiseaseLabel(className);
    final String percentText = '${(confidence * 100).toStringAsFixed(1)}%';
    final Color confColor = _getConfidenceColor(confidence);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border.all(color: confColor.withOpacity(0.3), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: confColor.withOpacity(0.15),
                ),
                child: Text(
                  percentText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: confColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(confColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final DetectionResult result;

  @override
  Widget build(BuildContext context) {
    final String prettyJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(result.rawJson);
    final String topLabel = result.detectedLabels.isEmpty
        ? 'لم يتم اكتشاف فئة مرضية في الاستجابة الحالية.'
        : result.detectedLabels.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'الناتج الرئيسي',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    _translateDiseaseLabel(topLabel),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (result.confidence != null)
                    Text(
                      '${(result.confidence! * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'الفئات المكتشفة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (result.detectedLabels.isEmpty)
              const Text('لم يتم استخراج فئات من الاستجابة.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.detectedLabels
                    .map(
                      (String label) =>
                          Chip(label: Text(_translateDiseaseLabel(label))),
                    )
                    .toList(),
              ),
            const SizedBox(height: 14),
            ValueListenableBuilder<bool>(
              valueListenable: AppRuntimeConfig.showAdvancedDetails,
              builder: (context, show, child) {
                if (!show) return const SizedBox.shrink();

                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'تفاصيل متقدمة',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: const Text(
                      'هذه البيانات للأغراض المتقدمة، للاطلاع على تفاصيل النتيجة',
                    ),
                    children: <Widget>[_PredictionsDetailView(result: result)],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
