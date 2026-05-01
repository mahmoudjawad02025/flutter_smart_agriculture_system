// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_cucumber_agriculture_system/core/config/app_runtime_config.dart';
import 'package:smart_cucumber_agriculture_system/core/config/roboflow_config.dart';
import 'package:smart_cucumber_agriculture_system/features/ai_detection/data/models/detection_result_model.dart';

class AiDetectionService {
  AiDetectionService({
    required ImagePicker imagePicker,
    required Dio dio,
    required FirebaseDatabase database,
    required RoboflowConfig config,
  }) : _imagePicker = imagePicker,
       _dio = dio,
       _database = database,
       _config = config;

  final ImagePicker _imagePicker;
  final Dio _dio;
  final FirebaseDatabase _database;
  final RoboflowConfig _config;

  Future<String?> pickAndSaveLeafImage() async {
    final XFile? selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (selectedImage == null) {
      return null;
    }

    final Directory uploadsDirectory = Directory(
      '${Directory.current.path}${Platform.pathSeparator}lib${Platform.pathSeparator}core${Platform.pathSeparator}uploads',
    );

    if (!await uploadsDirectory.exists()) {
      await uploadsDirectory.create(recursive: true);
    }

    final File savedImage = File(
      '${uploadsDirectory.path}${Platform.pathSeparator}img.jpg',
    );

    if (await savedImage.exists()) {
      await savedImage.delete();
    }

    final List<int> bytes = await selectedImage.readAsBytes();
    await savedImage.writeAsBytes(bytes, flush: true);

    return savedImage.path;
  }

  Future<DetectionResult> analyzeSavedImage(String imagePath) async {
    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('No saved image found. Please upload an image first.');
    }

    final Uri endpoint = Uri.parse(
      '${_config.baseUrl}/${_config.modelId}',
    ).replace(queryParameters: <String, String>{'api_key': _config.apiKey});

    final FormData formData = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(imageFile.path, filename: 'img.jpg'),
    });

    Response<dynamic> response;
    try {
      response = await _dio.postUri(
        endpoint,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 35),
          receiveTimeout: const Duration(seconds: 35),
        ),
      );
    } on DioException catch (error) {
      final int? statusCode = error.response?.statusCode;
      final dynamic errorBody = error.response?.data;
      throw Exception(
        'Roboflow model API failed. status=$statusCode body=$errorBody',
      );
    }

    final dynamic body = response.data;
    if (body is Map<String, dynamic>) {
      return DetectionResult.fromApiResponse(body);
    }
    if (body is Map) {
      return DetectionResult.fromApiResponse(Map<String, dynamic>.from(body));
    }

    throw Exception('Unexpected API response format.');
  }

  Future<void> updateLeafStatusInFirebase(DetectionResult result) async {
    try {
      final List<String> labels = result.detectedLabels;
      final bool isHealthy = _isHealthy(labels);

      print('[DISEASE_DETECTION] Detected labels: $labels');
      print('[DISEASE_DETECTION] Is healthy: $isHealthy');

      // Handle case where detection failed or no disease detected
      final String leafStatus;
      if (labels.isEmpty) {
        leafStatus = 'Unknown - Detection Failed';
      } else if (isHealthy) {
        leafStatus = 'Healthy';
      } else {
        leafStatus = labels.first;
      }

      final String reuploadAt = isHealthy
          ? ''
          : DateTime.now()
                .toUtc()
                .add(
                  Duration(
                    days: AppRuntimeConfig.diseaseReuploadDelayDays.value,
                  ),
                )
                .toIso8601String();

      print('[DISEASE_DETECTION] Updating Firebase with:');
      print('[DISEASE_DETECTION]   status: $leafStatus');
      print('[DISEASE_DETECTION]   needs_fix: ${!isHealthy}');
      print('[DISEASE_DETECTION]   reupload_at: $reuploadAt');

      await _database
          .ref('smart_cucumber_agriculture/data/leaf')
          .update(<String, dynamic>{
            'status': leafStatus,
            'needs_fix': !isHealthy,
            'reupload_at': reuploadAt,
            'last_updated': DateTime.now().toUtc().toIso8601String(),
          });

      print('[DISEASE_DETECTION] Firebase update successful!');
    } catch (e) {
      print('[DISEASE_DETECTION] Firebase update FAILED: $e');
      // Firebase write failed - rethrow so UI shows the error
      throw Exception('Firebase update failed: $e');
    }
  }

  bool _isHealthy(List<String> labels) {
    if (labels.isEmpty) {
      return false;
    }

    final List<String> keywords = AppRuntimeConfig.healthyKeywords.value
        .map((String value) => value.toLowerCase())
        .toList();

    return labels.every((String label) {
      final String normalized = label.toLowerCase();
      return keywords.any(normalized.contains);
    });
  }
}

