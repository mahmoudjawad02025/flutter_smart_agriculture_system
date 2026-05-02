import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_cucumber_agriculture_system/firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'core/config/app_access_control.dart';
import 'core/config/app_runtime_config.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/ui/auth_wrapper.dart';

import 'core/config/roboflow_config.dart';
import 'features/disease_detection/cubit/disease_detection_cubit.dart';
import 'features/disease_detection/services/disease_detection_service.dart';
import 'features/disease_detection/services/tomato_classifier_service.dart';
import 'features/firebase_data/cubit/firebase_data_cubit.dart';
import 'features/notifications/cubit/notifications_cubit.dart';
import 'features/notifications/services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppAccessControl.instance.initialize();
  await AppRuntimeConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final RoboflowConfig _config = const RoboflowConfig();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF558B2F),
          surface: const Color(0xFFF4F8EE),
        );

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(
            authService: AuthService(
              firebaseAuth: FirebaseAuth.instance,
              database: FirebaseDatabase.instance,
            ),
          ),
        ),
        BlocProvider<NotificationsCubit>(
          create: (_) => NotificationsCubit(
            notificationsService: NotificationsService(
              database: FirebaseDatabase.instance,
            ),
          ),
        ),
        BlocProvider<DiseaseDetectionCubit>(
          create: (context) {
            final DiseaseDetectionService service = DiseaseDetectionService(
              imagePicker: ImagePicker(),
              dio: Dio(),
              database: FirebaseDatabase.instance,
              config: _config,
              tomatoClassifierService: TomatoClassifierService(),
            );
            return DiseaseDetectionCubit(
              diseaseDetectionService: service,
              notificationsCubit: context.read<NotificationsCubit>(),
            );
          },
        ),
        BlocProvider<FirebaseDataCubit>(
          create: (_) => FirebaseDataCubit(database: FirebaseDatabase.instance),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Cucumber Agriculture',
        theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFEEF5E9),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 1,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFFE3F0DB),
            indicatorColor: const Color(0xFFB7D9A8),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
              Set<WidgetState> states,
            ) {
              final bool selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF1F5B24)
                    : const Color(0xFF3D4B35),
              );
            }),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0.8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
