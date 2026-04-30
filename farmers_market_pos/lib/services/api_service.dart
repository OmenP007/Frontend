import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Surface useful error messages from the API
        final apiMsg = error.response?.data?['message'];
        if (apiMsg != null) {
          return handler.reject(DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            message: apiMsg as String,
          ));
        }
        return handler.next(error);
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email, 'password': password, 'device_name': 'Flutter POS',
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  // ── Farmers ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getFarmers({String? query}) async {
    final res = await _dio.get('/farmers', queryParameters: query != null ? {'q': query} : null);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFarmer(int id) async {
    final res = await _dio.get('/farmers/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createFarmer(Map<String, dynamic> data) async {
    final res = await _dio.post('/farmers', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFarmerDebts(int farmerId) async {
    final res = await _dio.get('/farmers/$farmerId/debts');
    return res.data as Map<String, dynamic>;
  }

  // ── Categories ────────────────────────────────────────────────────────────
  Future<List<dynamic>> getCategories({bool rootOnly = false}) async {
    final res = await _dio.get('/categories',
        queryParameters: rootOnly ? {'root_only': true} : null);
    return res.data as List<dynamic>;
  }

  // ── Products ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProducts({int? categoryId, String? search}) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['category_id'] = categoryId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _dio.get('/products', queryParameters: params.isNotEmpty ? params : null);
    return res.data as Map<String, dynamic>;
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createTransaction({
    required int farmerId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    double? interestRate,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'farmer_id':      farmerId,
      'payment_method': paymentMethod,
      'items':          items,
    };
    if (interestRate != null) data['interest_rate'] = interestRate;
    if (notes != null)        data['notes']          = notes;

    final res = await _dio.post('/transactions', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ── Repayments ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createRepayment({
    required int farmerId,
    required double kgReceived,
    required String commodity,
    double? rateOverride,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'farmer_id':   farmerId,
      'kg_received': kgReceived,
      'commodity':   commodity,
    };
    if (rateOverride != null) data['commodity_rate_fcfa_per_kg'] = rateOverride;
    if (notes != null)        data['notes']                       = notes;

    final res = await _dio.post('/repayments', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  Future<List<dynamic>> getSettings() async {
    final res = await _dio.get('/settings');
    return res.data as List<dynamic>;
  }
}
