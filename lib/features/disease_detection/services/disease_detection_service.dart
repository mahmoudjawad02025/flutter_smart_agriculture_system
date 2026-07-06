// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_cucumber_agriculture_system/features/disease_detection/services/plant_classifier_service.dart';
import 'package:smart_cucumber_agriculture_system/features/firebase_data/models/farm_payload.dart';

import '../../../core/config/app_runtime_config.dart';
import '../models/detection_result.dart';

class DiseaseDetectionService {
  DiseaseDetectionService({
    required ImagePicker imagePicker,
    required FirebaseDatabase database,
    required PlantClassifierService plantClassifierService,
  }) : _imagePicker = imagePicker,
       _database = database,
       _plantClassifierService = plantClassifierService;

  final ImagePicker _imagePicker;
  final FirebaseDatabase _database;
  final PlantClassifierService _plantClassifierService;

  Future<String?> pickAndSaveLeafImage() async {
    final XFile? selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (selectedImage == null) {
      return null;
    }

    final Directory tempDir = await getTemporaryDirectory();
    final Directory uploadsDirectory = Directory(
      '${tempDir.path}${Platform.pathSeparator}leaf_uploads',
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

    await selectedImage.saveTo(savedImage.path);

    return savedImage.path;
  }

  Future<DetectionResult> analyzeSavedImage(String imagePath) async {
    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('لم يتم العثور على صورة محفوظة. يرجى رفع صورة أولاً.');
    }

    // Local on-device TFLite inference
    return await _plantClassifierService.analyzeSavedImage(imagePath);

    /*
    // Keep Roboflow API code commented out as requested
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
        'فشل نموذج Roboflow. الحالة=$statusCode الجسم=$errorBody',
      );
    }

    final dynamic body = response.data;
    if (body is Map<String, dynamic>) {
      return DetectionResult.fromApiResponse(body);
    }
    if (body is Map) {
      return DetectionResult.fromApiResponse(Map<String, dynamic>.from(body));
    }

    throw Exception('تنسيق استجابة API غير متوقع.');
    */
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
        // Use canonical token so UI mapping displays localized text
        leafStatus = 'Unknown';
      } else if (isHealthy) {
        leafStatus = 'Healthy';
      } else {
        leafStatus = labels.first;
      }

      await pushLeafFields(_database, leafStatus);
    } catch (e) {
      print('[DISEASE_DETECTION] Firebase update FAILED: $e');
      // Firebase write failed - rethrow so UI shows the error
      throw Exception('فشل تحديث Firebase: $e');
    }
  }

  Future<void> updateLeafStatusManually(String status) async {
    await pushLeafFields(_database, status);
  }

  static Future<void> pushLeafFields(
    FirebaseDatabase database,
    String leafStatus,
  ) async {
    final Map<String, dynamic> payload = buildLeafUpdatePayload(leafStatus);

    print('[DISEASE_DETECTION] Updating Firebase with:');
    print('[DISEASE_DETECTION]   status: ${payload['status']}');
    print('[DISEASE_DETECTION]   needs_fix: ${payload['needs_fix']}');
    print('[DISEASE_DETECTION]   reupload_at: ${payload['reupload_at']}');

    await database.ref(FarmPayload.leafPath).update(payload);

    print('[DISEASE_DETECTION] Firebase update successful!');
  }

  static Map<String, dynamic> buildLeafUpdatePayload(String leafStatus) {
    final bool isHealthy = _isHealthyStatus(leafStatus);
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

    return <String, dynamic>{
      'status': leafStatus,
      'needs_fix': !isHealthy,
      'reupload_at': reuploadAt,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static bool _isHealthyStatus(String status) {
    final String normalized = status.toLowerCase();
    final List<String> keywords = AppRuntimeConfig.healthyKeywords.value
        .map((String value) => value.toLowerCase())
        .toList();

    return keywords.any(normalized.contains);
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
