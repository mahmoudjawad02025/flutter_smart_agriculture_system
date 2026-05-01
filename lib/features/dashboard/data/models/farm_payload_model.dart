class FarmPayload {
  const FarmPayload._();

  static const String rootPath = 'smart_cucumber_agriculture';
  static const String nitrogenPath = '$rootPath/data/sensors/n';

  static Map<String, dynamic> sampleData() {
    final now = DateTime.now().toUtc().toIso8601String();
    return <String, dynamic>{
      'actions': <String, dynamic>{
        'goals': <String, dynamic>{
          'k_max': 250,
          'k_min': 150,
          'leaf_goal': "Healthy",
          'moist_max': 165,
          'moist_min': 60,
          'n_max': 180,
          'n_min': 150,
          'p_max': 80,
          'p_min': 40,
        },
        'pumps': <String, dynamic>{'auto': true, 'fert': false, 'water': false},
      },
      'data': <String, dynamic>{
        'leaf': <String, dynamic>{
          'last_updated': now,
          'needs_fix': true,
          'reupload_at': DateTime.now()
              .toUtc()
              .add(const Duration(days: 3))
              .toIso8601String(),
          'status': "Downy_Mildew",
        },
        'sensors': <String, dynamic>{
          'hum': 60,
          'k': 200,
          'moist': 65,
          'n': 130,
          'p': 50,
          'temp': 54.5,
          'time': now,
        },
      },
      'logs': <String, dynamic>{
        'manual_log': <String, dynamic>{
          'manual_initial': <String, dynamic>{
            'action': "ON",
            'pump': "Water",
            'state': <String, dynamic>{
              'moist': 65,
              'status': "Downy_Mildew",
              'temp': 54.5,
            },
            'time': now,
          },
        },
      },
      'notifications': <String, dynamic>{
        'items': <String, dynamic>{
          'test_1': <String, dynamic>{
            'created_at': now,
            'disease_name': "Downy_Mildew",
            'is_read': true,
            'message': "Downy_Mildew detected on your cucumber leaf",
            'next_upload': now,
            'title': "Disease Detected",
          },
        },
        'unread_count': 0,
      },
    };
  }
}
