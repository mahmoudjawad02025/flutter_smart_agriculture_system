import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_cubit.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_state.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/utils/ui_helpers.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _showSnackBar(String message, {bool isError = true}) {
    showLocalizedSnackBar(
      context,
      message,
      durationSeconds: 4,
      forceError: isError,
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
