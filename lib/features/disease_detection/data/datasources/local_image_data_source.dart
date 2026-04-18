import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

abstract class LocalImageDataSource {
  Future<String?> pickAndSaveImageAsMainUpload();
}

class LocalImageDataSourceImpl implements LocalImageDataSource {
  LocalImageDataSourceImpl({required ImagePicker imagePicker})
    : _imagePicker = imagePicker;

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickAndSaveImageAsMainUpload() async {
    final XFile? selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (selectedImage == null) {
      return null;
    }
    // Save to lib/core/uploads/img.jpg
    // final Directory appDirectory = await getApplicationDocumentsDirectory();
    // final Directory uploadsDirectory = Directory(
    //   '${appDirectory.path}${Platform.pathSeparator}uploads',
    // );

    // Save to project-local path: lib/core/uploads/img.jpg
    final String projectUploadsPath =
        '${Directory.current.path}${Platform.pathSeparator}lib${Platform.pathSeparator}core${Platform.pathSeparator}uploads';
    final Directory uploadsDirectory = Directory(projectUploadsPath);

    if (!await uploadsDirectory.exists()) {
      await uploadsDirectory.create(recursive: true);
    }

    final File savedImage = File(
      '${uploadsDirectory.path}${Platform.pathSeparator}img.jpg',
    );

    if (await savedImage.exists()) {
      await savedImage.delete();
    }

    final List<int> bytes = await selectedImage.readAsBytes();
    await savedImage.writeAsBytes(bytes, flush: true);

    return savedImage.path;
  }
}
