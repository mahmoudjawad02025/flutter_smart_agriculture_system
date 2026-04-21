import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/disease_detection_cubit.dart';
import '../cubit/disease_detection_state.dart';
import '../models/detection_result.dart';

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
                Text(
                  'Upload cucumber leaf image',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'The app saves the latest upload as lib/core/uploads/img.jpg and '
                  'replaces old image automatically.',
                ),
                const SizedBox(height: 14),
                _ImagePreview(
                  path: state.imagePath,
                  refreshToken: state.previewRevision,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: state.isAnalyzing
                          ? null
                          : cubit.pickImageAndSave,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Image'),
                    ),
                    FilledButton.icon(
                      onPressed: (!state.hasImage || state.isAnalyzing)
                          ? null
                          : cubit.analyzeImage,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Connect API'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.imagePath == null
                      ? 'Saved file: lib/core/uploads/img.jpg (after first upload)'
                      : 'Saved file: ${state.imagePath}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Text('Result', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (state.isAnalyzing) ...<Widget>[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  const Center(child: Text('Analyzing image...')),
                ] else if (state.result != null) ...<Widget>[
                  _ResultView(result: state.result!),
                ] else ...<Widget>[
                  const Text(
                    'No analysis result yet. Upload image then press Connect API.',
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
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No image selected', textAlign: TextAlign.center),
        ),
      );
    }

    final File imageFile = File(widget.path!);
    if (!imageFile.existsSync()) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Saved image not found on disk.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        imageFile,
        key: ValueKey<String>('${widget.path!}_${widget.refreshToken}'),
        fit: BoxFit.cover,
        height: 220,
        width: double.infinity,
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
          Text(
            'Raw API response',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: SelectableText(
              prettyJson,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
