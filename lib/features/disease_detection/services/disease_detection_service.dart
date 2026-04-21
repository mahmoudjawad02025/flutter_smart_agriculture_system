import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/roboflow_config.dart';
import '../models/detection_result.dart';

class DiseaseDetectionService {
  DiseaseDetectionService({
    required ImagePicker imagePicker,
    required Dio dio,
    required RoboflowConfig config,
  }) : _imagePicker = imagePicker,
       _dio = dio,
       _config = config;

  final ImagePicker _imagePicker;
  final Dio _dio;
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
}
