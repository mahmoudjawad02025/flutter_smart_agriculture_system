import 'dart:convert';
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

    final String encodedImage = base64Encode(await imageFile.readAsBytes());
    final Uri endpoint = Uri.parse(_config.baseUrl).replace(
      pathSegments: <String>[
        ...Uri.parse(
          _config.baseUrl,
        ).pathSegments.where((String segment) => segment.isNotEmpty),
        _config.workspaceName,
        'workflows',
        _config.workflowId,
      ],
    );

    final Map<String, dynamic> payload = <String, dynamic>{
      'api_key': _config.apiKey,
      'use_cache': true,
      'inputs': <String, dynamic>{
        'image': <String, dynamic>{'type': 'base64', 'value': encodedImage},
        'classes': _config.classes,
      },
    };

    final Response<dynamic> response = await _dio.postUri(
      endpoint,
      data: payload,
      options: Options(
        headers: <String, String>{'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 35),
        receiveTimeout: const Duration(seconds: 35),
      ),
    );

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
