import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../sessions.dart';

class Http {
  late Dio dio;

  final Logger logger = Logger();

  static const String baseUrl =
      'https://social-mammal-entirely.ngrok-free.app/api/v1/';

  // Singleton
  static final Http _instance = Http._internal();
  factory Http() => _instance;

  Http._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.i('➡️ ${options.method} ${options.uri}');
          try {
            logger.i('   request headers: ${options.headers}');
          } catch (_) {}
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.i(
            '✅ ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          try {
            logger.e('❌ ${error.response?.statusCode} ${error.requestOptions.path}');
            logger.e('   response data: ${error.response?.data}');
          } catch (_) {
            logger.e('❌ Dio error: $error');
          }
          handler.next(error);
        },
      ),
    );
  }

  // =====================
  // AUTH
  // =====================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    try {
      final response = await dio.post(
        'auth/login',
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
        },
      );

      // Ensure we always return a consistent map structure
      if (response.data is Map<String, dynamic>) return Map<String, dynamic>.from(response.data as Map);
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await dio.post(
        'auth/logout',
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getRoles({
    String? search,
    bool? isActive,
    int? perPage,
  }) async {
    // Try request, if 401 try to refresh header from Sessions and retry once
    try {
      // ensure Authorization header is present (try Sessions if not set)
      try {
        final token = await Sessions.getToken();
        if (token != null && token.isNotEmpty) {
          final current = dio.options.headers['Authorization'];
          if (current == null || (current is String && current.isEmpty)) {
            dio.options.headers['Authorization'] = 'Bearer $token';
            logger.i('getRoles: set Authorization header from Sessions');
          }
        }
      } catch (_) {}

      final response = await dio.get(
        'roles',
        queryParameters: {
          if (search != null) 'search': search,
          if (isActive != null) 'is_active': isActive,
          if (perPage != null) 'per_page': perPage,
        },
      );

      if (response.data is Map<String, dynamic>) return Map<String, dynamic>.from(response.data as Map);
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      // if unauthorized, try to set header from Sessions and retry once
      final status = e.response?.statusCode;
      if (status == 401) {
        try {
          final token = await Sessions.getToken();
          if (token != null && token.isNotEmpty) {
            dio.options.headers['Authorization'] = 'Bearer $token';
            logger.i('getRoles: retrying after setting Authorization from Sessions');
            final retry = await dio.get(
              'roles',
              queryParameters: {
                if (search != null) 'search': search,
                if (isActive != null) 'is_active': isActive,
                if (perPage != null) 'per_page': perPage,
              },
            );
            if (retry.data is Map<String, dynamic>) return Map<String, dynamic>.from(retry.data as Map);
            return {'success': true, 'data': retry.data};
          }
        } catch (retryErr) {
          logger.w('getRoles retry failed: $retryErr');
        }
      }

      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  // ... other methods omitted in this shim
}
