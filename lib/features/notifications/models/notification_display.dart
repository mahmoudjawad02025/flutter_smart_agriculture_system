import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import 'farm_notification.dart';

/// Visual + copy metadata for a [FarmNotification] card.
class NotificationDisplay {
  const NotificationDisplay({
    required this.resolvedType,
    required this.categoryLabel,
    required this.icon,
    required this.accentColor,
    required this.titleText,
    required this.bodyText,
    this.detailLabel,
    this.isDisease = false,
    this.strongAlertEligible = false,
  });

  final String resolvedType;
  final String categoryLabel;
  final IconData icon;
  final Color accentColor;
  final String titleText;
  final String bodyText;
  final String? detailLabel;
  final bool isDisease;
  final bool strongAlertEligible;

  static NotificationDisplay resolve(
    FarmNotification notification, {
    required bool isStrongAlertMode,
  }) {
    final String type = notification.resolvedType;
    final bool isRead = notification.isRead;

    switch (type) {
      case FarmNotification.typeSensorAlert:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'تنبيه مستشعر',
          icon: _sensorIconFromText(
            '${notification.title} ${notification.message}',
          ),
          accentColor: isRead ? Colors.grey.shade500 : const Color(0xFFEF6C00),
          titleText: notification.title,
          bodyText: notification.message,
        );

      case FarmNotification.typeTankAlert:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'تنبيه خزان',
          icon: _tankIconFromText(notification.title),
          accentColor: isRead ? Colors.grey.shade500 : const Color(0xFFE65100),
          titleText: notification.title,
          bodyText: notification.message,
        );

      case FarmNotification.typeForceStop:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'إيقاف قسري',
          icon: Icons.stop_circle_outlined,
          accentColor: isRead ? Colors.grey.shade500 : const Color(0xFFC62828),
          titleText: notification.title,
          bodyText: notification.message,
        );

      case FarmNotification.typePumpChange:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'تغيير مضخة',
          icon: Icons.settings_input_component_outlined,
          accentColor: isRead ? Colors.grey.shade500 : const Color(0xFF1565C0),
          titleText: notification.title,
          bodyText: notification.message,
        );

      case FarmNotification.typeImageUpload:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'رفع صورة',
          icon: Icons.upload_outlined,
          accentColor: isRead ? Colors.grey.shade500 : const Color(0xFF00838F),
          titleText: notification.title,
          bodyText: notification.message,
        );

      case FarmNotification.typeUserSignup:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'مستخدم جديد',
          icon: Icons.person_add_rounded,
          accentColor: isRead ? Colors.grey.shade500 : Colors.deepPurple,
          titleText: notification.title,
          bodyText: notification.message,
        );

      case FarmNotification.typeReuploadReminder:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'تذكير رفع صورة',
          icon: Icons.photo_camera_outlined,
          accentColor: isRead ? Colors.grey.shade500 : const Color(0xFF0277BD),
          titleText: notification.title,
          bodyText: notification.message,
        );

      case FarmNotification.typeManualTest:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'اختبار',
          icon: Icons.cloud_done_rounded,
          accentColor: isRead ? Colors.grey.shade500 : Colors.blue,
          titleText: notification.title.isNotEmpty
              ? notification.title
              : AppStrings.displayDiseaseName('Manual_Test'),
          bodyText: notification.message,
        );

      case FarmNotification.typeAutoAction:
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'إجراء تلقائي',
          icon: Icons.auto_mode_outlined,
          accentColor: isRead ? Colors.grey.shade500 : const Color(0xFF2E7D32),
          titleText: notification.title,
          bodyText: notification.message,
        );

      case FarmNotification.typeDisease:
        final String diseaseCode = _diseaseCode(notification);
        final String displayDisease = AppStrings.displayDiseaseName(diseaseCode);
        final bool strong = isStrongAlertMode && !isRead;
        return NotificationDisplay(
          resolvedType: type,
          categoryLabel: 'كشف مرض',
          icon: Icons.biotech_outlined,
          accentColor: strong
              ? const Color(0xFFD32F2F)
              : (isRead ? Colors.grey.shade500 : const Color(0xFF2E7D32)),
          titleText: notification.title.isNotEmpty
              ? notification.title
              : 'تم اكتشاف $displayDisease',
          bodyText: notification.message.isNotEmpty
              ? notification.message
              : 'تم اكتشاف $displayDisease على ورقة ${AppStrings.plantDefinite}',
          detailLabel: displayDisease,
          isDisease: true,
          strongAlertEligible: true,
        );

      default:
        return NotificationDisplay(
          resolvedType: FarmNotification.typeGeneral,
          categoryLabel: 'إشعار نظام',
          icon: Icons.notifications_outlined,
          accentColor: isRead ? Colors.grey.shade500 : const Color(0xFF546E7A),
          titleText: notification.title,
          bodyText: notification.message,
        );
    }
  }

  static String _diseaseCode(FarmNotification notification) {
    if (notification.diseaseName.isNotEmpty) {
      return notification.diseaseName;
    }
    return _extractDiseaseFromText(notification.title) ??
        _extractDiseaseFromText(notification.message) ??
        '';
  }

  static String? _extractDiseaseFromText(String? text) {
    if (text == null || text.isEmpty) return null;
    final String normalized = text.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');
    const List<String> candidates = <String>[
      'bacterialspot',
      'lateblight',
      'earlyblight',
      'yellowleafcurl',
      'septoria',
      'powderymildew',
      'healthy',
    ];
    for (final String c in candidates) {
      if (normalized.contains(c)) return c;
    }
    return null;
  }

  static IconData _sensorIconFromText(String text) {
    if (text.contains('الحرارة')) return Icons.thermostat_outlined;
    if (text.contains('الرطوبة الأرضية') || text.contains('التربة')) {
      return Icons.water_drop_outlined;
    }
    if (text.contains('الرطوبة')) return Icons.air_outlined;
    if (text.contains('النيتروجين')) return Icons.grass_outlined;
    if (text.contains('الفوسفور')) return Icons.spa_outlined;
    if (text.contains('البوتاسيوم')) return Icons.eco_outlined;
    return Icons.sensors_outlined;
  }

  static IconData _tankIconFromText(String text) {
    if (text.contains('الماء') || text.contains('المياه')) {
      return Icons.water_drop_rounded;
    }
    if (text.contains('التسميد 2') || text.contains('السماد 2')) {
      return Icons.biotech_rounded;
    }
    if (text.contains('التسميد') || text.contains('السماد')) {
      return Icons.science_rounded;
    }
    return Icons.propane_tank_outlined;
  }
}
