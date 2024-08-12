
import 'dart:io';

class ImmutableVideoRecordManagerContext {
  final Directory recordDirectory;

  ImmutableVideoRecordManagerContext({
    required this.recordDirectory,
  }) { }

  Map<String, dynamic> toJson() {
    Map<String,dynamic> map = {
      'recordDirectory': recordDirectory.path,
    };

    // Remove keys with null values
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static ImmutableVideoRecordManagerContext toObject(Map<String, dynamic> input) {
    return new ImmutableVideoRecordManagerContext(
      recordDirectory: Directory(input['recordDirectory']),
    );
  }
}

typedef RecordContext = ImmutableVideoRecordManagerContext;