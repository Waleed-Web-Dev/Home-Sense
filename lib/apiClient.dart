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
    return 'http://10.202.30.96:8000';
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

  Future<String> authenticate({
    required String email,
    required String password,
    required bool isRegister,
  }) async {
    final String path = isRegister ? '/auth/signup' : '/auth/login';

    final Map<String, dynamic> payload = isRegister
        ? {
      'email': email,
      'password': password,
      'full_name': "Test Name",
      'gps_lat': 0,
      'gps_lon': 0,
      'city_name': "Isb",
      'has_pets': false,
      'has_children': false,
    }
        : {
      'username': email, // FastAPI OAuth2 expects 'username'
      'password': password,
    };

    final Response response = await dio.post(
      path,
      data: payload,
      options: isRegister
          ? null
          : Options(contentType: Headers.formUrlEncodedContentType),
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
  Future<Options> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  /// Matches @router.post("/upload-identify")
  Future<Map<String, dynamic>> uploadPlantImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'plant_scan.jpg',
        contentType: DioMediaType('image', 'jpeg'), // Required for FastAPI image/* check
      ),
    });

    final Response response = await dio.post(
      '/plants/upload-identify', // Adjust prefix if your router has a different prefix
      data: formData,
      options: await _authHeaders(),
    );

    return Map<String, dynamic>.from(response.data);
  }



  /// Matches @router.post("/confirm-add")
  Future<Map<String, dynamic>> confirmAndAddPlant({
    required String selectedSpeciesId,
    required String nickname,
    required double heightCm,
    required double potSizeInches,
    required String currentRoom,
    required String tempImagePath,
  }) async {
    final Response response = await dio.post(
      '/plants/confirm-add',
      data: {
        'selected_species_id': selectedSpeciesId,
        'nickname': nickname,
        'height_cm': heightCm,
        'pot_size_inches': potSizeInches,
        'current_room': currentRoom,
        'temp_image_path': tempImagePath,
      },
      options: await _authHeaders(),
    );

    return Map<String, dynamic>.from(response.data);
  }

  /// Matches @router.post("/diagnose")
  Future<Map<String, dynamic>> diagnosePlantImage({
    required String filePath,
    required String plantId,
  }) async {
    final formData = FormData.fromMap({
      'plant_id': plantId,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'plant_checkup.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });

    final Response response = await dio.post(
      '/plants/diagnose', // Adjust prefix if your router uses a different prefix
      data: formData,
      options: await _authHeaders(),
    );

    return Map<String, dynamic>.from(response.data);
  }


}