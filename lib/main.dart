import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'core/config/roboflow_config.dart';
import 'features/disease_detection/data/datasources/local_image_data_source.dart';
import 'features/disease_detection/data/datasources/roboflow_remote_data_source.dart';
import 'features/disease_detection/data/repositories/disease_detection_repository_impl.dart';
import 'features/disease_detection/domain/usecases/analyze_leaf_image_usecase.dart';
import 'features/disease_detection/domain/usecases/pick_and_store_image_usecase.dart';
import 'features/disease_detection/presentation/cubit/disease_detection_cubit.dart';
import 'features/disease_detection/presentation/pages/disease_detection_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

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
      home: BlocProvider(
        create: (_) {
          final repository = DiseaseDetectionRepositoryImpl(
            localImageDataSource: LocalImageDataSourceImpl(
              imagePicker: ImagePicker(),
            ),
            remoteDataSource: RoboflowRemoteDataSourceImpl(
              dio: Dio(),
              config: _config,
            ),
          );

          return DiseaseDetectionCubit(
            pickAndStoreImageUseCase: PickAndStoreImageUseCase(repository),
            analyzeLeafImageUseCase: AnalyzeLeafImageUseCase(repository),
          );
        },
        child: const DiseaseDetectionPage(),
      ),
    );
  }
}
