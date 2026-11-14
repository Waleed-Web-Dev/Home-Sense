import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  static String get baseUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://127.0.0.1:8000';
    }
    // Replace with your laptop's IPv4 address from ipconfig:
    return 'http://10.202.33.234:8000';
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          final responseData = e.response?.data;
          String cleanMessage = 'Network error occurred';

          if (responseData is Map && responseData['detail'] != null) {
            final detail = responseData['detail'];
            cleanMessage = detail is List
                ? detail.first['msg'].toString()
                : detail.toString();
          } else if (e.message != null) {
            cleanMessage = e.message!;
          }

          return handler.next(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: cleanMessage,
            ),
          );
        },
      ),
    );
  }

  // 1. AUTHENTICATION ENDPOINTS
  Future<String> authenticate({
    required String email,
    required String password,
    required bool isRegister,
  }) async {
    final String path = isRegister ? '/auth/register' : '/auth/login';

    final Response response = await dio.post(
      path,
      data: {
        'username': email,
        'password': password,
        'options': isRegister ? null : Options(contentType: Headers.formUrlEncodedContentType),
      },
    );

    final data = response.data;
    final String? token =
    data is Map ? (data['access_token'] ?? data['token']) : null;

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_email', email);
      return token;
    }

    if (isRegister) {
      return authenticate(email: email, password: password, isRegister: false);
    }
    return '';
  }

  // 2. PLANT IDENTIFICATION & INVENTORY ENDPOINTS
  Future<Map<String, dynamic>> uploadPlantImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'plant_scan.jpg'),
    });

    final response = await dio.post('/plants/identify', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> confirmAddPlant(
      Map<String, dynamic> plantPayload) async {
    final response = await dio.post('/plants/confirm-add', data: plantPayload);
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> fetchMyPlants() async {
    final response = await dio.get('/plants/my-plants');
    return response.data as List<dynamic>;
  }
}