import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/firebase_options.dart';

import 'core/config/app_access_control.dart';
import 'core/config/app_runtime_config.dart';
import 'core/di/app_di.dart';
import 'core/theme/app_theme.dart';
import 'features/ui/bloc/auth_bloc.dart';
import 'features/ui/bloc/disease_detection_bloc.dart';
import 'features/ui/bloc/firebase_data_bloc.dart';
import 'features/ui/bloc/notifications_bloc.dart';
import 'features/ui/pages/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        BlocProvider<DiseaseDetectionCubit>(
          create: (context) {
            return DiseaseDetectionCubit(
              diseaseDetectionService: AppDi.provideDiseaseRepository(),
              notificationsCubit: context.read<NotificationsCubit>(),
            );
          },
        ),
        BlocProvider<FirebaseDataCubit>(
          create: (_) => FirebaseDataCubit(
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
