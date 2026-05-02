import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/firebase_options.dart';

import 'core/config/app_access_control.dart';
import 'core/config/app_runtime_config.dart';
import 'core/di/app_di.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/ui/bloc/auth_bloc.dart';
import 'features/ai_detection/ui/bloc/ai_detection_bloc.dart';
import 'features/dashboard/ui/bloc/dashboard_bloc.dart';
import 'features/notifications/ui/bloc/notifications_bloc.dart';
import 'features/auth/ui/pages/auth_wrapper.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AppAccessControl.instance.initialize();
  await AppRuntimeConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(authService: AppDi.provideAuthRepository()),
        ),
        BlocProvider<NotificationsCubit>(
          create: (_) => NotificationsCubit(
            notificationsService: AppDi.provideNotificationsRepository(),
          ),
        ),
        BlocProvider<AiDetectionCubit>(
          create: (context) {
            return AiDetectionCubit(
              pickAndSaveLeafImage: AppDi.providePickAndSaveLeafImageUsecase(),
              analyzeLeafImage: AppDi.provideAnalyzeLeafImageUsecase(),
              updateLeafStatus: AppDi.provideUpdateLeafStatusUsecase(),
              notificationsCubit: context.read<NotificationsCubit>(),
            );
          },
        ),
        BlocProvider<DashboardCubit>(
          create: (_) => DashboardCubit(
            writeSampleData: AppDi.provideWriteSampleDataUsecase(),
            readNitrogen: AppDi.provideReadNitrogenUsecase(),
            pushTestNotification: AppDi.providePushTestNotificationUsecase(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Cucumber Agriculture',
        theme: AppTheme.light(),
        home: const AuthWrapper(),
      ),
    );
  }
}

