import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_smart_agriculture_system/core/config/app_runtime_config.dart';
import 'package:flutter_smart_agriculture_system/features/ai_detection/domain/entities/ai_detection_result.dart';
import 'package:flutter_smart_agriculture_system/features/ai_detection/ui/bloc/ai_detection_bloc.dart';
import 'package:flutter_smart_agriculture_system/features/ai_detection/ui/bloc/ai_detection_state.dart';

const String _appIconAsset = 'lib/core/media/icons/app/app.png';

class AiDetectionPage extends StatelessWidget {
  const AiDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer<AiDetectionCubit, AiDetectionState>(
        listenWhen: (AiDetectionState previous, AiDetectionState current) {
          return previous.errorMessage != current.errorMessage &&
              current.errorMessage != null;
        },
        listener: (BuildContext context, AiDetectionState state) {
          final String? message = state.errorMessage;
          if (message == null || message.isEmpty) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (BuildContext context, AiDetectionState state) {
          final AiDetectionCubit cubit = context.read<AiDetectionCubit>();

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
                        label: const Text('Upload Image'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (!state.hasImage || state.isAnalyzing)
                            ? null
                            : cubit.analyzeImage,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Analyze'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Analysis Result',
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
                          Text('Analyzing image...'),
                        ],
                      ),
                    ),
                  ),
                ] else if (state.result != null) ...<Widget>[
                  _ResultView(result: state.result!),
                ] else ...<Widget>[
                  const _EmptyResultCard(
                    message:
                        'No analysis result yet. Upload an image and press Analyze.',
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
          child: Text('No image selected', textAlign: TextAlign.center),
        ),
      );
    }

    final File imageFile = File(widget.path!);
    if (!imageFile.existsSync()) {
      return const _ImageFrame(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Saved image not found on disk.',
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
                  'AI Leaf Disease Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAnalyzing
                      ? 'Model is analyzing your image...'
                      : 'Upload a clear leaf photo to get fast AI insights.',
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

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final AiDetectionResult result;

  @override
  Widget build(BuildContext context) {
    final String prettyJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(result.rawJson);
    final String topLabel = result.detectedLabels.isEmpty
        ? 'No disease class detected from the current response.'
        : result.detectedLabels.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Primary Output',
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
                    topLabel,
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
              'Detected classes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (result.detectedLabels.isEmpty)
              const Text('No classes extracted from response.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.detectedLabels
                    .map((String label) => Chip(label: Text(label)))
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
                      'Advanced details',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: const Text('Developer JSON response'),
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        child: SelectableText(
                          prettyJson,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
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
