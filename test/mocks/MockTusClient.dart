
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:tus_client_dart/tus_client_dart.dart'; // Replace with the correct import for TusClient

class MockTusClient extends Mock implements TusClient {
  MockTusClient(
      this.file, {
        this.store,
        this.maxChunkSize = 512 * 1024,
        this.retries = 0,
        this.retryScale = RetryScale.constant,
        this.retryInterval = 0,
      });

  /// Override this method to use a custom Client
  http.Client getHttpClient();

  /// Create a new upload throwing [ProtocolException] on server error
  Future<void> createUpload();

  /// Check if an upload can be resumed.
  Future<bool> isResumable();

  /// Set up test servers for measuring upload speed.
  Future<void> setUploadTestServers();

  /// Test the upload speed using the best servers.
  Future<void> uploadSpeedTest();

  /// Start or resume an upload in chunks, throwing [ProtocolException] on server error.
  Future<void> upload({
    Function(double, Duration)? onProgress,
    Function(TusClient, Duration?)? onStart,
    Function()? onComplete,
    required Uri uri,
    Map<String, String>? metadata = const {},
    Map<String, String>? headers = const {},
    bool measureUploadSpeed = false,
  });

  /// Perform the upload operation.
  Future<void> _performUpload({
    Function(double, Duration)? onProgress,
    Function()? onComplete,
    required Map<String, String> uploadHeaders,
    required http.Client client,
    required Stopwatch uploadStopwatch,
    required int totalBytes,
  });

  /// Pause the current upload.
  Future<bool> pauseUpload();

  /// Cancel the current upload.
  Future<bool> cancelUpload();

  /// Actions to be performed after a successful upload.
  Future<void> onCompleteUpload();

  /// Set the upload data (URL, headers, metadata).
  void setUploadData(
      Uri url,
      Map<String, String>? headers,
      Map<String, String>? metadata,
      );

  /// Get the current offset from the server, throwing [ProtocolException] on error.
  Future<int> _getOffset();

  /// Get data from the file to upload.
  Future<Uint8List> _getData();

  /// Parse the offset value from a string.
  int? _parseOffset(String? offset);

  /// Parse a URL string into a Uri object.
  Uri _parseUrl(String urlStr);

  http.StreamedResponse? _response;
  int? _fileSize;
  String _fingerprint = "";
  String? _uploadMetadata;
  Uri? _uploadUrl;
  int _offset = 0;
  bool _pauseUpload = false;

  /// The URI on the server for the file.
  Uri? get uploadUrl => _uploadUrl;

  /// The fingerprint of the file being uploaded.
  String get fingerprint => _fingerprint;

  /// The 'Upload-Metadata' header sent to the server.
  String get uploadMetadata => _uploadMetadata ?? "";

  /// Storage used to save and retrieve upload URLs by its fingerprint.
  final TusStore? store;

  /// File to upload, must be in[XFile] type
  final XFile file;

  /// The maximum payload size in bytes when uploading the file in chunks (512KB)
  final int maxChunkSize;

  /// The number of times that should retry to resume the upload if a failure occurs after rethrow the error.
  final int retries;

  /// The interval between the first error and the first retry in [seconds].
  final int retryInterval;

  /// The scale type used to increase the interval of time between every retry.
  final RetryScale retryScale;
}