import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_cubit.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_state.dart';

import '../../../core/services/firebase_streams.dart';
import '../../../core/config/app_runtime_config.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../firebase_data/models/farm_payload.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const String staticWifiSsid = 'hardware_wifi';
  static const String staticWifiPassword = 'hardware_wifi_123';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Map<String, dynamic> _cachedWifiConfig = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _primeWifiConfig();
  }

  Future<void> _primeWifiConfig() async {
    final Map<String, dynamic> wifi = await _loadWifiConfig();
    if (!mounted) return;
    setState(() => _cachedWifiConfig = wifi);
  }

  void _showSnackBar(String message, {bool isError = true}) {
    showLocalizedSnackBar(
      context,
      message,
      durationSeconds: 4,
      forceError: isError,
    );
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _wifiSsid(Map<String, dynamic> wifi, {required bool isNew}) {
    final List<String> keys = isNew
        ? <String>['new_ssid', 'new_name']
        : <String>['old_ssid', 'old_name', 'name'];
    for (final String key in keys) {
      final dynamic raw = wifi[key];
      if (raw == null) continue;
      final String value = raw.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _wifiPass(Map<String, dynamic> wifi, {required bool isNew}) {
    final List<String> keys = isNew
        ? <String>['new_pass']
        : <String>['old_pass', 'old_password', 'password'];
    for (final String key in keys) {
      final dynamic raw = wifi[key];
      if (raw == null) continue;
      final String value = raw.toString();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  Future<Map<String, dynamic>> _loadWifiConfig() async {
    final DatabaseEvent? cached = FirebaseStreams.lastWifiEvent;
    if (cached != null && cached.snapshot.value != null) {
      return _toMap(cached.snapshot.value);
    }

    final DataSnapshot snapshot = await _database
        .ref(FarmPayload.wifiPath)
        .get();
    return _toMap(snapshot.value);
  }

  Future<void> _openChangeWifiDialog({
    required bool isNew,
    required String dialogTitle,
    required String profileLabel,
    required String nameFieldKey,
    required String passwordFieldKey,
    required String successMessage,
  }) async {
    final Map<String, dynamic> wifi = await _loadWifiConfig();
    await _showChangeWifiDialog(
      dialogTitle: dialogTitle,
      profileLabel: profileLabel,
      nameFieldKey: nameFieldKey,
      passwordFieldKey: passwordFieldKey,
      currentName: _wifiSsid(wifi, isNew: isNew),
      currentPassword: _wifiPass(wifi, isNew: isNew),
      successMessage: successMessage,
    );
  }

  Future<bool> _showWifiDangerConfirmation({
    required String profileLabel,
    required String wifiName,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
          title: const Text('تنبيه خطير'),
          content: Text(
            'تأكد أن إعدادات شبكة Wi-Fi واحدة على الأقل (الحالية أو الجديدة) '
            'صحيحة 100%. إذا كان كلاهما خاطئًا فسيفقد المتحكم الاتصال بالشبكة '
            'وستحتاج إلى إعادة برمجته.\n\n'
            'الملف المراد حفظه: $profileLabel\n'
            'اسم الشبكة: $wifiName',
            style: const TextStyle(height: 1.5),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأكيد الإرسال'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _showChangeWifiDialog({
    required String dialogTitle,
    required String profileLabel,
    required String nameFieldKey,
    required String passwordFieldKey,
    required String currentName,
    required String currentPassword,
    required String successMessage,
  }) async {
    String wifiName = currentName;
    String wifiPassword = currentPassword;

    final bool? shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(dialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تأكد أن إعدادات شبكة Wi-Fi واحدة على الأقل (الحالية أو الجديدة) '
                            'صحيحة 100%. إذا كان كلاهما خاطئًا فسيفقد المتحكم الاتصال '
                            'بالشبكة وستحتاج إلى إعادة برمجته.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: currentName,
                    decoration: const InputDecoration(
                      labelText: 'اسم شبكة Wi-Fi',
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (String value) {
                      setState(() => wifiName = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: currentPassword,
                    decoration: const InputDecoration(
                      labelText: 'كلمة مرور Wi-Fi',
                    ),
                    obscureText: true,
                    onChanged: (String value) {
                      setState(() => wifiPassword = value);
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('متابعة'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSubmit != true) {
      return;
    }

    wifiName = wifiName.trim();

    if (wifiName.isEmpty) {
      _showSnackBar('يرجى إدخال اسم شبكة Wi-Fi.');
      return;
    }

    if (wifiPassword.trim().isEmpty) {
      _showSnackBar('يرجى إدخال كلمة مرور Wi-Fi.');
      return;
    }

    final bool confirmed = await _showWifiDangerConfirmation(
      profileLabel: profileLabel,
      wifiName: wifiName,
    );
    if (!confirmed) {
      return;
    }

    try {
      await _database.ref(FarmPayload.wifiPath).update(<String, dynamic>{
        nameFieldKey: wifiName,
        passwordFieldKey: wifiPassword,
      });
      if (mounted) {
        _showSnackBar(successMessage, isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل حفظ إعدادات Wi-Fi: $e');
      }
    }
  }

  Widget _buildControllerWifiSection(Map<String, dynamic> wifi) {
    final String oldWifiSsid = _wifiSsid(wifi, isNew: false);
    final String newWifiSsid = _wifiSsid(wifi, isNew: true);

    return Column(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.wifi_outlined),
          title: const Text('الشبكة الحالية'),
          subtitle: Text(
            oldWifiSsid.isEmpty
                ? 'لم يتم حفظ اسم الشبكة الحالية بعد'
                : 'الشبكة الحالية: $oldWifiSsid',
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _openChangeWifiDialog(
            isNew: false,
            dialogTitle: 'تعديل الشبكة الحالية',
            profileLabel: 'الشبكة الحالية',
            nameFieldKey: 'old_ssid',
            passwordFieldKey: 'old_pass',
            successMessage: 'تم حفظ إعدادات الشبكة الحالية للمتحكم.',
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.wifi_tethering_outlined),
          title: const Text('شبكة جديدة'),
          subtitle: Text(
            newWifiSsid.isEmpty
                ? 'لم يتم حفظ اسم الشبكة الجديدة بعد'
                : 'الشبكة الجديدة: $newWifiSsid',
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _openChangeWifiDialog(
            isNew: true,
            dialogTitle: 'تعديل الشبكة الجديدة',
            profileLabel: 'الشبكة الجديدة',
            nameFieldKey: 'new_ssid',
            passwordFieldKey: 'new_pass',
            successMessage: 'تم حفظ إعدادات الشبكة الجديدة للمتحكم.',
          ),
        ),
        const Divider(height: 1),
        const _WifiRecoveryInfoTile(),
      ],
    );
  }

  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير البريد الإلكتروني'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'سيتم إرسال رابط التحقق إلى البريد الإلكتروني الجديد.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني الجديد',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text.trim();
              final pass = passController.text;

              if (email.isEmpty || !email.contains('@')) {
                _showSnackBar('يرجى إدخال بريد إلكتروني صالح.');
                return;
              }
              if (pass.isEmpty) {
                _showSnackBar('يرجى إدخال كلمة المرور الحالية للتحقق.');
                return;
              }

              context.read<AuthCubit>().changeEmail(
                currentPassword: pass,
                newEmail: email,
              );
              Navigator.pop(context);
            },
            child: const Text('تأكيد وتغيير'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
              ),
              obscureText: true,
            ),
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                hintText: 'الحد الأدنى 6 أحرف',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final current = currentPassController.text;
              final newPass = newPassController.text;

              if (current.isEmpty) {
                _showSnackBar('كلمة المرور الحالية مطلوبة.');
                return;
              }
              if (newPass.length < 6) {
                _showSnackBar(
                  'يجب أن تكون كلمة المرور الجديدة ستة أحرف على الأقل.',
                );
                return;
              }

              context.read<AuthCubit>().changePassword(
                currentPassword: current,
                newPassword: newPass,
              );
              Navigator.pop(context);
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          final String m = state.message.toLowerCase();
          final bool isSuccess =
              m.contains('successfully') ||
              m.contains('sent to') ||
              m.contains('تم') ||
              m.contains('تم إرسال') ||
              m.contains('تم تحديث') ||
              m.contains('اكتمل') ||
              m.contains('نجاح');
          _showSnackBar(state.message, isError: !isSuccess);
        }
      },
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF1F5B24), Color(0xFF4C8A2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'الإعدادات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'قم بتخصيص سلوك التطبيق وإشعاراته.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'الأمان',
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('تغيير البريد الإلكتروني'),
                  onTap: _showChangeEmailDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('تغيير كلمة المرور'),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'المتحكم',
              children: <Widget>[
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseStreams.wifiStream,
                  initialData: FirebaseStreams.lastWifiEvent,
                  builder: (context, snapshot) {
                    final Map<String, dynamic> streamedWifi = _toMap(
                      snapshot.data?.snapshot.value,
                    );
                    final Map<String, dynamic> wifi = streamedWifi.isNotEmpty
                        ? streamedWifi
                        : _cachedWifiConfig;

                    return _buildControllerWifiSection(wifi);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'الإشعارات',
              children: <Widget>[
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.pushNotifications,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setPushNotifications,
                      title: const Text('إشعارات الدفع'),
                      subtitle: const Text('عرض التنبيهات عند اكتشاف المرض'),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.strongAlertMode,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setStrongAlertMode,
                      title: const Text('وضع التنبيه القوي'),
                      subtitle: const Text('استخدم ألوان أقوى لتحذيرات المرض'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'صفحة التكوين',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(
                    'الأقسام الأساسية تبقى ظاهرة دائمًا: بطاقة الحالة أعلى الصفحة، '
                    'المضخات، الخزانات، وقائمة «ما تحتاجه».',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      height: 1.35,
                    ),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.showConfigRefreshTime,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setShowConfigRefreshTime,
                      title: const Text('زمن تحديث الحلقة'),
                      subtitle: const Text(
                        'فترة انتظار المتحكم الدقيق بين كل دورة',
                      ),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.showConfigAutoWater,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setShowConfigAutoWater,
                      title: const Text('إعدادات الري التلقائي'),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.showConfigAutoFert,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setShowConfigAutoFert,
                      title: const Text('إعدادات التسميد التلقائي'),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.showConfigFert2Dose,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setShowConfigFert2Dose,
                      title: const Text('معالجة أمراض الأوراق'),
                      subtitle: const Text('مرض المعالجة وجرعة السماد 2'),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.showConfigDetectionRules,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setShowConfigDetectionRules,
                      title: const Text('قواعد الكشف'),
                      subtitle: const Text('حالة الورقة ومدة إعادة الرفع'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'التحليل',
              children: <Widget>[
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.autoAnalyze,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setAutoAnalyze,
                      title: const Text('التحليل التلقائي بعد الرفع'),
                      subtitle: const Text('تشغيل كشف المرض فورًا'),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: AppRuntimeConfig.showAdvancedDetails,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      value: value,
                      onChanged: AppRuntimeConfig.setShowAdvancedDetails,
                      title: const Text('عرض تفاصيل التحليل'),
                      subtitle: const Text(
                        'عرض الثقة والملصقات الخام من الذكاء الاصطناعي',
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Developer cloud tools removed from settings
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'حول',
              children: const <Widget>[
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('إصدار التطبيق'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: Icon(Icons.science_outlined),
                  title: Text('مصدر النموذج'),
                  subtitle: Text(
                    'كشف أمراض البندورة باستخدام الذكاء الاصطناعي السحابي',
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('التخزين'),
                  subtitle: Text('قاعدة بيانات Firebase في الوقت الفعلي'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.9,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _WifiRecoveryInfoTile extends StatelessWidget {
  const _WifiRecoveryInfoTile();

  Future<void> _showRecoveryInfo(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextTheme textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          icon: const Icon(Icons.info_outline, color: Color(0xFF1565C0)),
          title: const Text('استعادة اتصال المتحكم'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'إذا كانت الشبكة الحالية والشبكة الجديدة معًا غير صحيحة، '
                  'سيفقد المتحكم الاتصال بالإنترنت ولن يستقبل التحديثات من التطبيق.',
                  style: textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 14),
                Text(
                  'للاستعادة، يوفر المتحكم شبكة احتياطية مدمجة. '
                  'اتصل هاتفك مؤقتًا بها، ثم أعد ضبط قيم الشبكتين من التطبيق.',
                  style: textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBDEFB)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _WifiCredentialRow(
                        label: 'اسم الشبكة',
                        value: SettingsPage.staticWifiSsid,
                      ),
                      SizedBox(height: 8),
                      _WifiCredentialRow(
                        label: 'كلمة المرور',
                        value: SettingsPage.staticWifiPassword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'تأكد أن إعدادات شبكة واحدة على الأقل (الحالية أو الجديدة) '
                  'صحيحة 100% قبل الحفظ.',
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('حسناً'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: Color(0xFF1565C0)),
      title: const Text('ماذا لو فقد المتحكم الاتصال؟'),
      subtitle: const Text('اضغط لعرض شبكة الاستعادة المدمجة'),
      trailing: const Directionality(
        textDirection: TextDirection.ltr,
        child: Icon(Icons.chevron_left),
      ),
      onTap: () => _showRecoveryInfo(context),
    );
  }
}

class _WifiCredentialRow extends StatelessWidget {
  const _WifiCredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
