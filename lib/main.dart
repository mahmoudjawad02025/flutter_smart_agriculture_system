import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_cucumber_agriculture_system/features/disease_detection/services/plant_classifier_service.dart';
import 'package:smart_cucumber_agriculture_system/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/config/app_access_control.dart';
import 'core/config/app_runtime_config.dart';
import 'core/localization/app_strings.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/ui/auth_wrapper.dart';

import 'features/disease_detection/cubit/disease_detection_cubit.dart';
import 'features/disease_detection/services/disease_detection_service.dart';
import 'features/firebase_data/cubit/firebase_data_cubit.dart';
import 'features/firebase_data/models/farm_payload.dart';
import 'features/notifications/cubit/notifications_cubit.dart';
import 'features/notifications/services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local preferences should always succeed; let any failure surface clearly.
  await AppAccessControl.instance.initialize();
  await AppRuntimeConfig.initialize();

  // Firebase/network problems must not stop the UI from rendering, otherwise
  // the Windows process exits right after build with "Lost connection to
  // device" and no visible error.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stack) {
    debugPrint('[STARTUP] Firebase.initializeApp failed: $error\n$stack');
  }

  try {
    await FarmPayload.ensureDefaults(FirebaseDatabase.instance);
  } catch (error, stack) {
    debugPrint('[STARTUP] FarmPayload.ensureDefaults failed: $error\n$stack');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            database: FirebaseDatabase.instance,
          ),
        ),
        BlocProvider<DiseaseDetectionCubit>(
          create: (context) {
            final DiseaseDetectionService service = DiseaseDetectionService(
              imagePicker: ImagePicker(),
              database: FirebaseDatabase.instance,
              plantClassifierService: PlantClassifierService(),
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
        title: AppStrings.appTitle,
        locale: const Locale('ar'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('ar')],
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

// continue from consider BacterialSpot <=> Healthy
