import 'package:flutter/material.dart';

/// Show a SnackBar and choose success/error color by detecting English/Arabic cues
void showLocalizedSnackBar(
  BuildContext context,
  String message, {
  int durationSeconds = 4,
  bool? forceError,
}) {
  final String m = message.toLowerCase();

  bool detectSuccess() {
    return m.contains('successfully') ||
        m.contains('created') ||
        m.contains('sent') ||
        m.contains('updated') ||
        m.contains('تم') ||
        m.contains('بنجاح') ||
        m.contains('تم إرسال') ||
        m.contains('تم تحديث') ||
        m.contains('تم إنشاء') ||
        m.contains('تم تسجيل') ||
        m.contains('تم حفظ') ||
        m.contains('نجاح');
  }

  final bool isError = forceError ?? !detectSuccess();

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: durationSeconds),
      ),
    );
}
