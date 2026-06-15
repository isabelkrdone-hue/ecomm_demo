import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class Http {
  late Dio dio;

  final Logger logger = Logger();

  static const String baseUrl =
      'https://social-mammal-entirely.ngrok-free.app/api/v1/';

  Http() {
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
          logger.i(
            '➡️ ${options.method} ${options.uri}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.i(
            '✅ ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          logger.e(
            '❌ ${error.response?.statusCode} ${error.requestOptions.path}',
          );
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

      return response.data;
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

  // =====================
  // ROLES
  // =====================

  Future<Map<String, dynamic>> getRoles({
    String? search,
    bool? isActive,
    int? perPage,
  }) async {
    try {
      final response = await dio.get(
        'roles',
        queryParameters: {
          if (search != null) 'search': search,
          if (isActive != null) 'is_active': isActive,
          if (perPage != null) 'per_page': perPage,
        },
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getRole(String id) async {
    try {
      final response = await dio.get(
        'roles/$id',
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> createRole({
    required String nama,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post(
        'roles',
        data: {
          'nama': nama,
          'is_active': isActive,
        },
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> updateRole({
    required String id,
    required String nama,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.put(
        'roles/$id',
        data: {
          'nama': nama,
          'is_active': isActive,
        },
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> deleteRole(String id) async {
    try {
      final response = await dio.delete(
        'roles/$id',
      );

      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }
}