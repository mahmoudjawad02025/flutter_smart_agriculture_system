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

  /// All class labels the on-device TFLite model can output.
  static const List<String> modelLabels = <String>[
    'Healthy',
    'BacterialSpot',
    'LateBlight',
  ];

  /// Diseases the local AI can detect (excludes [Healthy]).
  static const List<String> detectableDiseaseLabels = <String>[
    'BacterialSpot',
    'LateBlight',
  ];

  static const String defaultFert2DiseaseName = 'BacterialSpot';

  static const List<String> _labels = modelLabels;

  Future<void> _initModel() async {
    final InterpreterOptions options = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      'assets/best_float32.tflite',
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

    final Uint8List imageBytes = await imageFile.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('فشل فك ترميز الصورة.');
    }

    // 1. Resize to 224x224
    final img.Image resizedImage = img.copyResize(
      decodedImage,
      width: 224,
      height: 224,
    );

    // 2. Extract RGB and normalize (0.0 to 1.0)
    // The model expects a Float32List of shape [1, 224, 224, 3]
    final Float32List inputBuffer = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        final img.Pixel pixel = resizedImage.getPixel(x, y);

        // Normalize RGB values
        inputBuffer[pixelIndex++] = pixel.r / 255.0;
        inputBuffer[pixelIndex++] = pixel.g / 255.0;
        inputBuffer[pixelIndex++] = pixel.b / 255.0;
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

    String detectedLabel = _labels[maxIndex];
    if (detectedLabel == 'Healthy') {
      detectedLabel = 'BacterialSpot';
    } else if (detectedLabel == 'BacterialSpot') {
      detectedLabel = 'Healthy';
    }

    // Build raw JSON for advanced details similar to Roboflow
    // Ensure probabilities map keys reflect the swapped labels so
    // rawJson is consistent with `detectedLabel` and `detectedLabels`.
    final Map<String, double> probsMap = <String, double>{};
    for (int i = 0; i < _labels.length; i++) {
      String key = _labels[i];
      if (key == 'Healthy') {
        key = 'BacterialSpot';
      } else if (key == 'BacterialSpot') {
        key = 'Healthy';
      }
      probsMap[key] = probabilities[i];
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
