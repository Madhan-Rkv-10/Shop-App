import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../model/http_exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? _authTimer;

  bool get isAuth {
    log('token.isNotEmpty${token.isNotEmpty}');
    return token != '';
  }

  String get userId {
    return _userId!;
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token!;
    }
    return '';
  }

  Future<void> _authenticate(
      String email, String password, String urlType) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlType?key=AIzaSyBM2pr9lSC-1yadRRK7mLSUt53FrJW0e68');

    try {
      final response = await http.post(url,
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true
          }));
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        log(responseData['error']['message']);
        throw OwnHttpException(message: responseData['error']['message']);
      }
      //if there is no error
      _token = responseData['idToken']!;
      _userId = responseData['localId']!;
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(responseData['expiresIn'])));

      _autologout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userLoggedData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String()
        },
      );
      prefs.setString('userLogData', userLoggedData);
      log('userLoggedData$userLoggedData');
    } catch (e) {
      rethrow;
    }
    // log(json.decode(response.body));
  }

  Future<void> signUp(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> autologin() async {
    log('autologin called');
    final prefs = await SharedPreferences.getInstance();
    log('autologin');

    if (prefs.containsKey('userLogData') == false) {
      return false;
    }

    String encodedMap = prefs.getString('userLogData').toString();
    final Map<String, dynamic> extractedUserData = json.decode(encodedMap);
    final expireDate =
        DateTime.parse(extractedUserData['expiryDate'] as String);
    if (expireDate.isBefore(DateTime.now())) {
      return false;
    }

    _token = extractedUserData['token'] as String;
    _userId = extractedUserData['userId'] as String;
    log(" extractedUserData['expiryDate'] ${extractedUserData['expiryDate']}");
    DateTime etime = DateTime.parse(extractedUserData['expiryDate']);
    _expiryDate = etime;
    log('etime$etime');

    log('_expiryDate$_expiryDate');

    notifyListeners();
    _autologout();
    return true;
  }

  Future<void> logout() async {
    _token = '';
    _userId = '';
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final pref = await SharedPreferences.getInstance();
    pref.clear();
  }

  void _autologout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final expirytime = _expiryDate!.difference(DateTime.now()).inSeconds;
    log('expirytime$expirytime'); //expirytime3599
    _authTimer = Timer(Duration(seconds: expirytime), logout);
  }
}
