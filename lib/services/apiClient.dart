import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:homesense/location_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  static final RegExp _mongoIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');

  static String get baseUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://127.0.0.1:8000';
    }
    // Replace with your laptop's IPv4 address from ipconfig:
    return 'http://10.202.26.84:8000';
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
                ? '${detail.first['loc']}: ${detail.first['msg']}'
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

  bool isValidMongoId(String id) => _mongoIdRegex.hasMatch(id);

  Future<String> authenticate({
    required String email,
    required String password,
    required bool isRegister,
    required String fullName, // Strictly required parameter
  }) async {
    if (isRegister && fullName.trim().isEmpty) {
      throw ArgumentError('Full name is required for registration.');
    }

    final String path = isRegister ? '/auth/signup' : '/auth/login';

    final Map<String, dynamic> payload = isRegister
        ? {
      'email': email,
      'password': password,
      'full_name': fullName.trim(), // Guaranteed non-empty string
      'gps_lat': null,
      'gps_lon': null,
      'city_name': null,
      'has_pets': false,
      'has_children': false,
    }
        : {
      'username': email,
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

      // Track whether the user already has a saved home location
      if (isRegister) {
        await prefs.setBool('has_home_location', false);
      } else if (data is Map && data['user'] is Map) {
        final hasLoc = data['user']['gps_lat'] != null;
        await prefs.setBool('has_home_location', hasLoc);
      }

      return token;
    }

    if (isRegister) {
      return authenticate(fullName:fullName,email: email, password: password, isRegister: false);
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
    final prefs = await SharedPreferences.getInstance();
    final bool hasHomeLocation = prefs.getBool('has_home_location') ?? false;

    double? lat;
    double? lon;

    // Fetch GPS only if the user's home location has not been set yet
    if (!hasHomeLocation) {
      final pos = await LocationHelper.getCurrentLocation();
      if (pos != null) {
        lat = pos.latitude;
        lon = pos.longitude;
      }
    }

    //_________________________________changes for error finding_______________________________
    try {
      final Response response = await dio.post(
        '/plants/confirm-add',
        data: {
          'selected_species_id': selectedSpeciesId,
          'nickname': nickname,
          'height_cm': heightCm,
          'pot_size_inches': potSizeInches,
          'current_room': currentRoom,
          'temp_image_path': tempImagePath,
          if (lat != null) 'gps_lat': lat,
          if (lon != null) 'gps_lon': lon,
        },
        options: await _authHeaders(),
      );

      if (!hasHomeLocation && lat != null && lon != null) {
        await prefs.setBool('has_home_location', true);
      }

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [API ERROR] Status: ${e.response?.statusCode}');
      debugPrint('❌ [API ERROR] Response Data: ${e.response?.data}');
      debugPrint('❌ [API ERROR] Request Data: ${e.requestOptions.data}');
      rethrow;
    }
    //______________________________________________________________________
  }


  //----------------Fetching Plants---------------
  Future<List<Map<String, dynamic>>> fetchMyPlants() async {
    try {
      final Response response = await dio.get(
        '/plants/my-plants', // <-- Matches your existing FastAPI route
        options: await _authHeaders(),
      );
      // Unwrap the "plants" array from {"count": ..., "plants": [...]}
      final List<dynamic> list = response.data['plants'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } on DioException catch (e) {
      debugPrint('❌ [FETCH PLANTS ERROR] ${e.response?.statusCode}: ${e.response?.data}');
      return [];
    }
  }
//--------------------------------------------------------------------------------


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


  // 3. NOTIFICATION & SCHEDULE SYNC ENDPOINTS

  /// POST /users/fcm-token
  Future<void> registerFcmToken(String fcmToken) async {
    await dio.post(
      '/users/fcm-token',
      data: {'fcm_token': fcmToken},
      options: await _authHeaders(),
    );
  }

  /// GET /plants/my-plants
  Future<List<PlantScheduleData>> fetchMyPlants() async {
    final Response response = await dio.get(
      '/plants/my-plants',
      options: await _authHeaders(),
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PlantScheduleData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /plants/{plant_id}
  Future<PlantScheduleData> fetchPlantById(String plantId) async {
    if (!isValidMongoId(plantId)) {
      throw ArgumentError('Invalid 24-char MongoDB plant_id: $plantId');
    }
    final Response response = await dio.get(
      '/plants/$plantId',
      options: await _authHeaders(),
    );
    return PlantScheduleData.fromJson(Map<String, dynamic>.from(response.data));
  }
}

class PlantScheduleData {
  final String plantId; // Exact 24-char MongoDB ObjectId
  final String name;
  final String healthStatus; // Thriving | Needs Attention | Recovering
  final DateTime? nextWaterDate;
  final DateTime? nextNutritionDate;
  final DateTime? nextCheckupDate;
  final List<dynamic> historyLogs;

  PlantScheduleData({
    required this.plantId,
    required this.name,
    required this.healthStatus,
    this.nextWaterDate,
    this.nextNutritionDate,
    this.nextCheckupDate,
    this.historyLogs = const [],
  });

  factory PlantScheduleData.fromJson(Map<String, dynamic> json) {
    DateTime? parseIso(dynamic val) =>
        val is String && val.isNotEmpty ? DateTime.tryParse(val)?.toLocal() : null;

    return PlantScheduleData(
      plantId: (json['plant_id'] ?? json['_id'] ?? '').toString(),
      name: (json['common_name'] ?? json['name'] ?? 'Unknown Plant').toString(),
      healthStatus: (json['health_status'] ?? 'Thriving').toString(),
      nextWaterDate: parseIso(json['next_water_date']),
      nextNutritionDate: parseIso(json['next_nutrition_date']),
      nextCheckupDate: parseIso(json['next_checkup_date']),
      historyLogs: (json['history_logs'] as List<dynamic>?) ?? const [],
    );
  }
}