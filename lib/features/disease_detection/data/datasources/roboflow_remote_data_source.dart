import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/config/roboflow_config.dart';
import '../models/detection_result_model.dart';

abstract class RoboflowRemoteDataSource {
  Future<DetectionResultModel> analyzeImage(String imagePath);
}

class RoboflowRemoteDataSourceImpl implements RoboflowRemoteDataSource {
  RoboflowRemoteDataSourceImpl({
    required Dio dio,
    required RoboflowConfig config,
  }) : _dio = dio,
       _config = config;

  final Dio _dio;
  final RoboflowConfig _config;

  @override
  Future<DetectionResultModel> analyzeImage(String imagePath) async {
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
      return DetectionResultModel.fromApiResponse(body);
    }
    if (body is Map) {
      return DetectionResultModel.fromApiResponse(
        Map<String, dynamic>.from(body),
      );
    }

    throw Exception('Unexpected API response format.');
  }
}
