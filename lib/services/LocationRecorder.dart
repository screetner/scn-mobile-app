import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationRecorder {

  late StreamSubscription<Position> _positionStream;
  late Position _currentPosition;

  // Private constructor
  LocationRecorder._(this._currentPosition);


  void dispose() {
    _positionStream.cancel();
  }

  static Future<LocationRecorder> createInstance() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Go to settings to enable locations');
      }

      final currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          )
      );

      return LocationRecorder._(currentPosition);
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  // TODO: delete this if unused
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        )
    );
  }

  Future<void> startLocationRecorder() async {
    try{
      _positionStream = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          )
      ).listen((Position position) {
        _currentPosition = position;
      });
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  Future<void> stopLocationStream() async {
    try {
      _positionStream.cancel();
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

  double get latitude => _currentPosition.latitude;
  double get longitude => _currentPosition.longitude;
  Position get position => _currentPosition;
}