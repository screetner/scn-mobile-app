import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationRecorder {

  late StreamSubscription<Position> _positionStream;

  final Function(Position position) _onLocationUpdate;

  LocationRecorder._privateConstructor(this._onLocationUpdate);

  void dispose() {
    _positionStream.cancel();
  }

  static Future<LocationRecorder> createInstance(Function(Position position) onLocationUpdate) async {
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

      return LocationRecorder._privateConstructor(onLocationUpdate);
    } catch (e, stackTrace) {
      // TODO: implement error handling
      print('An error occurred: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }

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
      ).listen(_onLocationUpdate);
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
}