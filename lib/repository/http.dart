import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class Http {
  // Singleton instance
  static final Http _instance = Http._internal();

  factory Http() => _instance;

  late Dio dio;

  final Logger logger = Logger();

  static const String baseUrl =
      'https://social-mammal-entirely.ngrok-free.app/api/v1/';

  int _boolQuery(bool value) => value ? 1 : 0;

  String? token;
  String? userId;
  String? name;
  String? email;
  String? phone;
  String? roleId;
  String? role;

  // private constructor
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
          logger.i(
            '➡️ ${options.method} ${options.uri}',
          );

          logger.i(
            'HEADERS: ${options.headers}',
          );

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log status and path
          logger.i('✅ ${response.statusCode} ${response.requestOptions.path}');

          // Log request details (if any) and response body to help debugging
          try {
            logger.d('REQUEST DATA: ${response.requestOptions.data}');
          } catch (_) {}

          try {
            logger.i('RESPONSE DATA: ${response.data}');
          } catch (_) {
            logger.i(
                'RESPONSE RECEIVED (unprintable) for ${response.requestOptions.path}');
          }

          handler.next(response);
        },
        onError: (error, handler) {
          // Safely log error information. Wrap in try/catch to avoid throwing
          try {
            final status = error.response?.statusCode;
            String path = '';
            try {
              path = error.requestOptions.path;
            } catch (_) {
              path = '';
            }

            logger.e('❌ $status $path');

            final errData = error.response?.data ?? error.message;
            // Convert common structures to a readable string safely
            try {
              logger.e('ERROR DATA: $errData');
            } catch (_) {
              logger.e('ERROR DATA (unprintable)');
            }
          } catch (e) {
            // Fallback logging if something unexpected happens while logging
            logger.e('Error while logging Dio error: $e');
          }

          handler.next(error);
        },
      ),
    );
  }

  // =====================
  // TOKEN
  // =====================

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';

    logger.i(
      '🔑 Authorization header updated',
    );
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');

    logger.i(
      '🔓 Authorization header removed',
    );
  }

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
          if (isActive != null) 'is_active': _boolQuery(isActive),
          if (perPage != null) 'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
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

      return Map<String, dynamic>.from(response.data);
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

      return Map<String, dynamic>.from(response.data);
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

      return Map<String, dynamic>.from(response.data);
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

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
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

      final result = Map<String, dynamic>.from(response.data);

      if (result['success'] == true) {
        final data = result['data'];
        final user = data['user'];

        token = data['token'];
        userId = user['id'];
        name = user['name'];
        this.email = user['email'];
        phone = user['phone'];
        roleId = user['role_id'];
        role = user['role'];

        setToken(token!);
      }

      return result;
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

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> registerSeller({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String kategoriSellerId,
    required String namaToko,
    required String alamat,
    required String kota,
    required String provinsi,
    required String kecamatan,
    required String desa,
    String? logo,
    String? deskripsi,
  }) async {
    try {
      final response = await dio.post(
        'auth/register-seller',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'kategori_seller_id': kategoriSellerId,
          'nama_toko': namaToko,
          'alamat': alamat,
          'kota': kota,
          'provinsi': provinsi,
          'kecamatan': kecamatan,
          'desa': desa,
          'logo': logo,
          'deskripsi': deskripsi,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getKategoriSeller({
    String? search,
    bool? isActive,
    int? perPage,
  }) async {
    try {
      final response = await dio.get(
        'kategori-seller',
        queryParameters: {
          if (search != null) 'search': search,
          if (isActive != null) 'is_active': _boolQuery(isActive),
          if (perPage != null) 'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getProvinces({
    String? search,
    bool? isActive,
    int? perPage = 100,
  }) async {
    try {
      final response = await dio.get(
        'provinces',
        queryParameters: {
          if (search != null) 'search': search,
          if (isActive != null) 'is_active': _boolQuery(isActive),
          if (perPage != null) 'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getRegencies({
    String? provinceId,
    String? search,
    bool? isActive,
    int? perPage = 100,
  }) async {
    try {
      final response = await dio.get(
        'regencies',
        queryParameters: {
          if (provinceId != null) 'province_id': provinceId,
          if (search != null) 'search': search,
          if (isActive != null) 'is_active': _boolQuery(isActive),
          if (perPage != null) 'per_page': perPage,
        },
      );

      // Explicit debug log for regencies: full request uri and response data
      try {
        logger.i('getRegencies request => ${response.requestOptions.uri}');
        logger.i('getRegencies response => ${response.data}');
      } catch (_) {}

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getDistricts({
    String? regencyId,
    String? search,
    bool? isActive,
    int? perPage = 100,
  }) async {
    try {
      final response = await dio.get(
        'districts',
        queryParameters: {
          if (regencyId != null) 'regency_id': regencyId,
          if (search != null) 'search': search,
          if (isActive != null) 'is_active': _boolQuery(isActive),
          if (perPage != null) 'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getVillages({
    String? districtId,
    String? search,
    bool? isActive,
    int? perPage = 100,
  }) async {
    try {
      final response = await dio.get(
        'villages',
        queryParameters: {
          if (districtId != null) 'district_id': districtId,
          if (search != null) 'search': search,
          if (isActive != null) 'is_active': _boolQuery(isActive),
          if (perPage != null) 'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getSatuan({
    String? search,
    bool isActive = true,
    int perPage = 100,
  }) async {
    try {
      final response = await dio.get(
        'satuan',
        queryParameters: {
          if (search != null) 'search': search,
          'is_active': _boolQuery(isActive),
          'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getKategoriProduk({
    String? search,
    String? parentId,
    bool isActive = true,
    int perPage = 100,
  }) async {
    try {
      final response = await dio.get(
        'kategori-produk',
        queryParameters: {
          if (search != null) 'search': search,
          if (parentId != null) 'parent_id': parentId,
          'is_active': _boolQuery(isActive),
          'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getProduk({
    String? search,
    String? sellerId,
    String? kategoriProdukId,
    String? satuanId,
    bool isActive = true,
    int perPage = 100,
  }) async {
    try {
      final response = await dio.get(
        'produk',
        queryParameters: {
          if (search != null) 'search': search,
          if (sellerId != null) 'seller_id': sellerId,
          if (kategoriProdukId != null) 'kategori_produk_id': kategoriProdukId,
          if (satuanId != null) 'satuan_id': satuanId,
          'is_active': _boolQuery(isActive),
          'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  // =====================
// PRODUK VARIAN
// =====================

  Future<Map<String, dynamic>> getProdukVarian({
    String? search,
    String? produkId,
    int perPage = 100,
  }) async {
    try {
      final response = await dio.get(
        'produk-varian',
        queryParameters: {
          if (search != null) 'search': search,
          if (produkId != null) 'produk_id': produkId,
          'per_page': perPage,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> getProdukVarianDetail(
    String id,
  ) async {
    try {
      final response = await dio.get(
        'produk-varian/$id',
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> createProdukVarian({
    required String produkId,
    required String namaVarian,
    required int qty,
    required double harga,
    bool isActive = true,
  }) async {
    try {
      final response = await dio.post(
        'produk-varian',
        data: {
          'produk_id': produkId,
          'nama_varian': namaVarian,
          'qty': qty,
          'harga': harga,
          'is_active': isActive,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> updateProdukVarian({
    required String id,
    required String produkId,
    required String namaVarian,
    required int qty,
    required double harga,
    bool isActive = true,
  }) async {
    try {
      final payload = {
        'produk_id': produkId,
        'nama_varian': namaVarian,
        'qty': qty,
        'harga': harga,
        'is_active': isActive,
      };

      logger.i('UPDATE PRODUK VARIAN REQUEST: produk-varian/$id');
      logger.i('UPDATE PRODUK VARIAN PAYLOAD: $payload');

      final response = await dio.put(
        'produk-varian/$id',
        data: payload,
      );

      logger.i('UPDATE PRODUK VARIAN STATUS: ${response.statusCode}');
      logger.i('UPDATE PRODUK VARIAN RESPONSE: ${response.data}');

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      logger.e('UPDATE PRODUK VARIAN ERROR: ${e.response?.statusCode}');
      logger.e('UPDATE PRODUK VARIAN ERROR DATA: ${e.response?.data}');
      logger.e('UPDATE PRODUK VARIAN ERROR MESSAGE: ${e.message}');

      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }

  Future<Map<String, dynamic>> deleteProdukVarian(
    String id,
  ) async {
    try {
      final response = await dio.delete(
        'produk-varian/$id',
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data ?? e.message,
      };
    }
  }
}
