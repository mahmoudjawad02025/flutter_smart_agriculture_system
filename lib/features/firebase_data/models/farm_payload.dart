class FarmPayload {
  const FarmPayload._();

  static const String rootPath = 'smart_cucumber_agriculture';
  static const String nitrogenPath = '$rootPath/data/sensors/n';

  static Map<String, dynamic> sampleData() {
    return <String, dynamic>{
      'data': <String, dynamic>{
        'sensors': <String, dynamic>{
          'moist': 45,
          'temp': 24.5,
          'hum': 60,
          'n': 120,
          'p': 50,
          'k': 200,
          'time': DateTime.now().toUtc().toIso8601String(),
        },
        'leaf': <String, dynamic>{
          'status': 'Healthy',
          'needs_fix': false,
          'reupload_at': '',
        },
      },
      'actions': <String, dynamic>{
        'pumps': <String, dynamic>{'water': false, 'fert': false, 'auto': true},
        'goals': <String, dynamic>{
          'moist_min': 30,
          'moist_max': 65,
          'n_min': 100,
          'n_max': 180,
          'p_min': 40,
          'p_max': 80,
          'k_min': 150,
          'k_max': 250,
          'leaf_goal': 'Healthy',
        },
      },
      'logs': <String, dynamic>{
        'water_log': <String, dynamic>{
          'id_1': <String, dynamic>{
            'time': DateTime.now().toUtc().toIso8601String(),
          },
        },
        'fert_log': <String, dynamic>{
          'id_1': <String, dynamic>{
            'time': DateTime.now().toUtc().toIso8601String(),
            'type': 'Disease_Fix',
            'val': 'Mildew',
          },
        },
        'upload_log': <String, dynamic>{
          'id_1': <String, dynamic>{
            'time': DateTime.now().toUtc().toIso8601String(),
            'res': 'Healthy',
          },
        },
      },
    };
  }
}
