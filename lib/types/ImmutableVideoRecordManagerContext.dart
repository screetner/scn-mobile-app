
import 'dart:io';

class ImmutableVideoRecordManagerContext {
  final Directory recordDirectory;
  final int recordIntervalMilliseconds;

  ImmutableVideoRecordManagerContext({
    required this.recordDirectory,
    required this.recordIntervalMilliseconds,
  }) { }

  Map<String, dynamic> toJson() {
    Map<String,dynamic> map = {
      'recordDirectory': recordDirectory.path,
      'recordInterval': recordIntervalMilliseconds
    };

    // Remove keys with null values
    map.removeWhere((key, value) => value == null);
    return map;
  }

  static ImmutableVideoRecordManagerContext toObject(Map<String, dynamic> input) {
    return new ImmutableVideoRecordManagerContext(
      recordDirectory: Directory(input['recordDirectory']),
      recordIntervalMilliseconds: input['recordInterval'],
    );
  }
}

typedef RecordContext = ImmutableVideoRecordManagerContext;