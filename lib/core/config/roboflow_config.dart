import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoboflowConfig {
  const RoboflowConfig();

  String get baseUrl => 'https://detect.roboflow.com';


  String get apiKey => dotenv.env['ROBOFLOW_API_KEY'] ?? '';
  String get modelId => dotenv.env['ROBOFLOW_MODEL_ID'] ?? '';
}

