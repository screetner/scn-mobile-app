
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tus_client_background_demo/main.dart';
import 'package:tus_client_background_demo/model/DirectoryUploadClient.dart';
import 'package:path/path.dart' as path;
import 'package:tus_client_background_demo/model/DirectoryUploadManager.dart';
import 'package:tus_client_background_demo/model/DirectoryUploadStore.dart';

void main() {
  // testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(const MyApp());
  //
  //   // Verify that our counter starts at 0.
  //   expect(find.text('0'), findsOneWidget);
  //   expect(find.text('1'), findsNothing);
  //
  //   // Tap the '+' icon and trigger a frame.
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pump();
  //
  //   // Verify that our counter has incremented.
  //   expect(find.text('0'), findsNothing);
  //   expect(find.text('1'), findsOneWidget);
  // });

  // testNewInsertion('Manager must upload all upload progress if the fingerprint file does not exist', (_) async {
  //   final uploadContext = await getEnvUploadContext();
  //
  //   final documentDirectory = await getApplicationDocumentsDirectory();
  //   final testDirectory = path.join(documentDirectory.path, 'test');
  //   final tusStoreDirectory = path.join(documentDirectory.path, 'tusStoreDir');
  //
  //   final tusStore = new DirectoryUploadFileStore(new Directory(tusStoreDirectory));
  //
  //   final duc = DirectoryUploadClient(uploadContext.tusStoreDirectory, store: tusStore);
  //
  //   duc.upsertUploadUrl();
  // });
}
