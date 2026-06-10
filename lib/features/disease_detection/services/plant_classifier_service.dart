import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection_result.dart';

class PlantClassifierService {
  PlantClassifierService() {
    _initModel();
  }

  Interpreter? _interpreter;
  // map_ai_results: labels from the current TFLite model
  // IMPORTANT: order must match the model output indices (Python test shows)
  static const List<String> _labels = <String>[
    'Anthracnose',
    'DownyMildew',
    'Healthy',
  ];

  Future<void> _initModel() async {
    final InterpreterOptions options = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      'lib/core/media/ai/best_float32.tflite',
      options: options,
    );
  }

  Future<DetectionResult> analyzeSavedImage(String imagePath) async {
    if (_interpreter == null) {
      await _initModel();
    }

    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('لم يتم العثور على الصورة.');
    }

    print('[PLANT_CLASSIFIER] Loading image from: $imagePath');
    final Uint8List imageBytes = await imageFile.readAsBytes();
    print('[PLANT_CLASSIFIER] Image bytes: ${imageBytes.length} bytes');

    final img.Image? decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('فشل فك ترميز الصورة.');
    }

    print(
      '[PLANT_CLASSIFIER] Decoded image: ${decodedImage.width}x${decodedImage.height}',
    );

    // 1. Normalize orientation and resize to 224x224
    // map_ai_results: align with Python/Pillow processing (EXIF orientation + bicubic)
    final img.Image oriented = img.bakeOrientation(decodedImage);
    final img.Image resizedImage = img.copyResize(
      oriented,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.cubic,
    );

    // 2. Extract RGB and normalize (0.0 to 1.0)
    // The model expects a Float32List of shape [1, 224, 224, 3]
    // map_ai_results: pixel extraction must exactly match Python preprocessing
    final Float32List inputBuffer = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        final img.Pixel pixel = resizedImage.getPixel(x, y);

        // Extract RGB channels (ensure 0-255 range)
        // pixel.r, pixel.g, pixel.b are in 0-255 range
        final double r = (pixel.r as num).toDouble();
        final double g = (pixel.g as num).toDouble();
        final double b = (pixel.b as num).toDouble();

        // Normalize to 0.0-1.0 range (matches Python: np.array(img, dtype=np.float32) / 255.0)
        inputBuffer[pixelIndex++] = r / 255.0;
        inputBuffer[pixelIndex++] = g / 255.0;
        inputBuffer[pixelIndex++] = b / 255.0;
      }
    }

    // 3. Inference
    // Output shape is [1, 3] for 3 classes
    final List<List<double>> outputBuffer = List<List<double>>.filled(
      1,
      List<double>.filled(3, 0.0),
    );

    _interpreter!.run(
      inputBuffer.buffer.asFloat32List().reshape(<int>[1, 224, 224, 3]),
      outputBuffer,
    );

    // 4. Map index to labels
    final List<double> probabilities = outputBuffer[0];
    int maxIndex = 0;
    double maxProb = probabilities[0];

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    // map_ai_results: the new model outputs these labels directly
    final String detectedLabel = _labels[maxIndex];

    // DEBUG: Log model predictions to verify preprocessing matches Python test
    print('[PLANT_CLASSIFIER] Raw probabilities:');
    for (int i = 0; i < _labels.length; i++) {
      print('  ${_labels[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
    }
    print(
      '[PLANT_CLASSIFIER] Predicted: $detectedLabel (${(maxProb * 100).toStringAsFixed(2)}%)',
    );

    // Build raw JSON for advanced details similar to Roboflow
    final Map<String, double> probsMap = <String, double>{};
    for (int i = 0; i < _labels.length; i++) {
      probsMap[_labels[i]] = probabilities[i];
    }

    final Map<String, dynamic> rawJson = <String, dynamic>{
      'predictions': <Map<String, dynamic>>[
        <String, dynamic>{
          'class': detectedLabel,
          'confidence': maxProb,
          'probabilities': probsMap,
        },
      ],
    };

    return DetectionResult(
      rawJson: rawJson,
      detectedLabels: <String>[detectedLabel],
      createdAt: DateTime.now(),
      confidence: maxProb,
    );
  }

  void close() {
    _interpreter?.close();
  }
}
