import 'dart:io';

import 'package:tus_client_dart/tus_client_dart.dart';

class CustomTusFileStore extends TusFileStore {
  CustomTusFileStore(super.directory);

  @override
  Future<void> remove(String fingerprint) async {
    final file = await _getFile(fingerprint);

    if (file.existsSync()) {
      file.deleteSync();
    }

    // This method doesn't delete the entire directory like the default one.
  }

  Future<File> _getFile(String fingerprint) async {
    final filePath = '${directory.absolute.path}/$fingerprint';
    return File(filePath);
  }
}

typedef CTusFileStore = CustomTusFileStore;