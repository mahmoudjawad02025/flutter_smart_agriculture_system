import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_cucumber_agriculture_system/firebase_options.dart';

import 'core/config/roboflow_config.dart';
import 'features/app_shell/ui/app_shell_page.dart';
import 'features/disease_detection/cubit/disease_detection_cubit.dart';
import 'features/disease_detection/services/disease_detection_service.dart';
import 'features/firebase_data/cubit/firebase_data_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final RoboflowConfig _config = const RoboflowConfig();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Cucumber Agriculture',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<DiseaseDetectionCubit>(
            create: (_) {
              final service = DiseaseDetectionService(
                imagePicker: ImagePicker(),
                dio: Dio(),
                config: _config,
              );
              return DiseaseDetectionCubit(diseaseDetectionService: service);
            },
          ),
          BlocProvider<FirebaseDataCubit>(
            create: (_) =>
                FirebaseDataCubit(database: FirebaseDatabase.instance),
          ),
        ],
        child: const AppShellPage(),
      ),
    );
  }
}
