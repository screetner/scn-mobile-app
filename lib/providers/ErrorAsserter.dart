import 'package:flutter/material.dart';

class Asserter {
  Asserter._privateConstructor();

  static final Asserter _instance = Asserter._privateConstructor();

  factory Asserter() {
    return _instance;
  }

  void handle(BuildContext context, void Function() callback) {
    try {
      callback();
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stacktrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}