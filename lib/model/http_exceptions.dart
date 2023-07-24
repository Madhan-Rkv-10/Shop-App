import 'dart:developer';

class OwnHttpException implements Exception {
  final String message;

  OwnHttpException({required this.message});
  @override
  String toString() {
    log('ownwxceptions message $message');
    return message;
    // return super.toString(); //Instance of exception
  }
}
//it has always to string method to convert error message