class AppStrings {
  AppStrings._();

  // App metadata
  static const String appTitle = 'المزرعة الذكية';
  // Asset path for the app icon used inside the Flutter UI (drawer, appbar).
  static const String appIconAsset = 'lib/core/media/icons/app/app.png';
  static const String diseaseDetected = 'تم الكشف عن مرض';

  // Common UI labels
  static const String on = 'تشغيل';
  static const String off = 'إيقاف';
  static const String newLabel = 'جديد';

  // Canonical crop name used across the app.
  static const String plant = 'نبتة';
  static const String plantDefinite = 'النبتة';

  // Disease display mapping
  static String displayDiseaseName(String name) {
    if (name.isEmpty) return '';
    final String normalized = name.toLowerCase().replaceAll(
      RegExp(r'[_\s-]'),
      '',
    );

    switch (normalized) {
      case 'manualtest':
        return 'اختبار يدوي';
      case 'usersignup':
        return 'تسجيل مستخدم';
      case 'healthy':
        return 'سليم';
      case 'lateblight':
      case 'late':
        return 'تعفن متأخر';
      case 'bacterialspot':
      case 'bacterial':
        return 'بقعة بكتيرية';
      case 'earlyblight':
        return 'تعفن مبكر';
      case 'yellowleafcurl':
        return 'لف الورقة الأصفر';
      case 'septoria':
        return 'سِبتوريا';
      case 'powderymildew':
        return 'سوس العفن';
      default:
        return name.replaceAll('_', ' ');
    }
  }

  // Leaf status mapping (normalized)
  static String displayLeafStatus(String status) {
    final String normalized = status.toLowerCase().replaceAll(
      RegExp(r'[_\s-]'),
      '',
    );
    switch (normalized) {
      case 'healthy':
        return 'سليم';
      case 'unknown':
        return 'غير معروف';
      case 'bacterialspot':
        return 'بقعة بكتيرية';
      case 'lateblight':
        return 'تعفن متأخر';
      case 'earlyblight':
        return 'تعفن مبكر';
      case 'yellowleafcurl':
        return 'لف الورقة الأصفر';
      case 'septoria':
        return 'سِبتوريا';
      case 'powderymildew':
        return 'سوس العفن';
      default:
        return status;
    }
  }

  // Pump name mapping
  static String displayPumpName(String pump) {
    if (pump.isEmpty) return '';
    final String normalized = pump.toLowerCase().replaceAll(
      RegExp(r'[_\s-]'),
      '',
    );
    switch (normalized) {
      case 'water':
      case 'waterpump':
      case 'pump':
        return 'ري';
      case 'fert1':
      case 'fertilizer1':
      case 'fert':
        return 'تسميد 1';
      case 'fert2':
      case 'fertilizer2':
        return 'تسميد 2';
      default:
        return pump;
    }
  }

  // Action display mapping (e.g., ON/OFF tokens from DB)
  static String displayAction(String action) {
    if (action.isEmpty) return '';
    final String normalized = action.toLowerCase().replaceAll(
      RegExp(r'[_\s-]'),
      '',
    );
    switch (normalized) {
      case 'on':
      case 'تشغيل':
        return on;
      case 'off':
      case 'إيقاف':
        return off;
      default:
        return action;
    }
  }
}
