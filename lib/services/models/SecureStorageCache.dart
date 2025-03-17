import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageCache implements FlutterSecureStorage {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final Map<String, String> cache = {};

  SecureStorageCache._privateConstructor();

  static final SecureStorageCache _instance = SecureStorageCache._privateConstructor();

  factory SecureStorageCache() {
    return _instance;
  }

  @override
  AndroidOptions get aOptions => secureStorage.aOptions;

  @override
  IOSOptions get iOptions => secureStorage.iOptions;

  @override
  LinuxOptions get lOptions => secureStorage.lOptions;

  @override
  MacOsOptions get mOptions => secureStorage.mOptions;

  @override
  WindowsOptions get wOptions => secureStorage.wOptions;

  @override
  WebOptions get webOptions => secureStorage.webOptions;

  @override
  Future<bool> containsKey({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) {
    return Future.value(secureStorage.containsKey(key: key, iOptions: iOptions, aOptions: aOptions, lOptions: lOptions, webOptions: webOptions, mOptions: mOptions, wOptions: wOptions));
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) {
    cache.remove(key);
    return Future.value(secureStorage.delete(key: key, iOptions: iOptions, aOptions: aOptions, lOptions: lOptions, webOptions: webOptions, mOptions: mOptions, wOptions: wOptions));
  }

  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) {
    cache.clear();
    return Future.value(secureStorage.deleteAll(iOptions: iOptions, aOptions: aOptions, lOptions: lOptions, webOptions: webOptions, mOptions: mOptions, wOptions: wOptions));
  }

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) {
    if(cache.containsKey(key)) {
      return Future.value(cache[key]);
    } else {
      return Future.value(secureStorage.read(key: key, iOptions: iOptions, aOptions: aOptions, lOptions: lOptions, webOptions: webOptions, mOptions: mOptions, wOptions: wOptions));
    }
  }

  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) {
    return Future.value(secureStorage.readAll(iOptions: iOptions, aOptions: aOptions, lOptions: lOptions, webOptions: webOptions, mOptions: mOptions, wOptions: wOptions));
  }

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) {
    cache[key] = value!;
    return Future.value(secureStorage.write(key: key, value: value, iOptions: iOptions, aOptions: aOptions, lOptions: lOptions, webOptions: webOptions, mOptions: mOptions, wOptions: wOptions));
  }
}