import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:work/constants.dart';
import 'package:work/models/error_model.dart';
import 'package:work/models/user_model.dart';
import 'package:work/repository/local_storage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:http/http.dart';
import 'package:work/screens/login.dart';

import '../utils/errorHandling.dart';
import '../utils/globalvariable.dart';
import '../utils/utils.dart';

final authRepositoryProvider = Provider(
      (ref) => AuthRepository(
    googleSignIn: AuthService(),
    client: Client(),
    localStorageRepository: LocalStorageRepository(),
  ),
);

final userProvider = StateProvider<UserModel?>((ref) => null);

class AuthRepository {
  final AuthService _googleSignIn;
  final Client _client;
  final LocalStorageRepository _localStorageRepository;
  AuthRepository({
    required AuthService googleSignIn,
    required Client client,
    required LocalStorageRepository localStorageRepository,
  })  : _googleSignIn = googleSignIn,
        _client = client,
        _localStorageRepository = localStorageRepository;


  signUpUser({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
    required String phone,
    required String otp
  }) async {
    ErrorModel error = ErrorModel(
      error: 'Some unexpected error occurred.',
      data: null,
    );
    final userAcc = UserModel(
      email: email,
      name: name,
      profilePic: phone ,
      uid: '',
      token: '',
    );
    try {


      http.Response res = await http.post(
        Uri.parse('$host/api/signup'),
        body: userAcc.toJson(),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {

          final newUser = userAcc.copyWith(
            uid: jsonDecode(res.body)['user']['_id'],
            token: jsonDecode(res.body)['token'],
          );
          error = ErrorModel(error: null, data: newUser);
          _localStorageRepository.setToken(newUser.token);
        },
      );
    } catch (e) {
      error = ErrorModel(
        error: e.toString(),
        data: null,
      );
    }
  }
  Future<ErrorModel> signInWithGoogle(
  BuildContext context, String email, String password,
      ) async {
    ErrorModel error = ErrorModel(
      error: 'Some unexpected error occurred.',
      data: null,
    );
    try {

        final userAcc = UserModel(
          email: email,
          name: password,
          profilePic: password,
          uid: '',
          token: '',
        );

        var res = await _client.post(Uri.parse('$host/api/signup'), body: userAcc.toJson(), headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        });
        print('ho1');
        switch (res.statusCode) {

          case 200:
            print('ho');
            final newUser = userAcc.copyWith(
              uid: jsonDecode(res.body)['user']['_id'],
              token: jsonDecode(res.body)['token'],
            );
            error = ErrorModel(error: null, data: newUser);
            _localStorageRepository.setToken(newUser.token);
            break;
        }

    } catch (e) {
      error = ErrorModel(
        error: e.toString(),
        data: null,
      );
    }
    return error;
  }



  Future<ErrorModel> getUserData() async {
    ErrorModel error = ErrorModel(
      error: 'Some unexpected error occurred.',
      data: null,
    );
    try {
      String? token = await _localStorageRepository.getToken();

      if (token != null) {
        var res = await _client.get(Uri.parse('$host/'), headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        });
        switch (res.statusCode) {
          case 200:
            final newUser = UserModel.fromJson(
              jsonEncode(
                jsonDecode(res.body)['user'],
              ),
            ).copyWith(token: token);
            error = ErrorModel(error: null, data: newUser);
            _localStorageRepository.setToken(newUser.token);
            break;
        }
      }
    } catch (e) {
      error = ErrorModel(
        error: e.toString(),
        data: null,
      );
    }
    return error;
  }

  void signOut() async {

    _localStorageRepository.setToken('');
  }
}
class AuthService {
  signInUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      http.Response res = await http.post(
        Uri.parse('$host/api/signup'),
        body: jsonEncode({
          'email': email,
          'name': password,
          'profilePic': password,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () async {
          print('update');
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
logOut(BuildContext context) async {
    try {

      Navigator.pushAndRemoveUntil(
        context,
        LoginScreen() as Route<Object?>,
            (route) => false,
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
}