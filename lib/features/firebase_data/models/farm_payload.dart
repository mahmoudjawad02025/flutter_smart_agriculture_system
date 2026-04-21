import '../../../core/config/app_runtime_config.dart';

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
          'moist_min': AppRuntimeConfig.moistMin.value,
          'moist_max': AppRuntimeConfig.moistMax.value,
          'n_min': AppRuntimeConfig.nMin.value,
          'n_max': AppRuntimeConfig.nMax.value,
          'p_min': AppRuntimeConfig.pMin.value,
          'p_max': AppRuntimeConfig.pMax.value,
          'k_min': AppRuntimeConfig.kMin.value,
          'k_max': AppRuntimeConfig.kMax.value,
          'leaf_goal': AppRuntimeConfig.leafGoal.value,
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
      'notifications': <String, dynamic>{
        'unread_count': 0,
        'items': <String, dynamic>{
          'notif_1': <String, dynamic>{
            'title': 'Disease Detected',
            'message': 'Powdery Mildew detected on your cucumber leaf',
            'disease_name': 'Powdery_Mildew',
            'next_upload': DateTime.now()
                .toUtc()
                .add(const Duration(days: 2))
                .toIso8601String(),
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
        },
      },
    };
  }
}
