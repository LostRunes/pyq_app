import 'dart:developer';
import 'package:dio/dio.dart';

class _SupabaseAuthInterceptor extends Interceptor {
  final String apiKey;
  _SupabaseAuthInterceptor(this.apiKey);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['apikey'] = apiKey;
    options.headers['Authorization'] = 'Bearer $apiKey';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Only log in debug — avoids leaking internal paths/errors in release logcat
    assert(() {
      log(
        '[SupabaseRestClient] ${err.requestOptions.method} '
        '${err.requestOptions.path} → ${err.response?.statusCode}',
      );
      return true;
    }());
    handler.next(err);
  }
}

class SupabaseRestClient {
  SupabaseRestClient._() {
    // Uses the anon key — content tables (branches, subjects, topics, questions,
    // etc.) now have RLS enabled with public-read policies so the anon key is
    // sufficient. The service_role key must NEVER be used in client-side code.
    _dio = Dio(
      BaseOptions(
        baseUrl: '${const String.fromEnvironment('SUPABASE_URL')}/rest/v1/',
        contentType: 'application/json',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    )..interceptors.add(
        _SupabaseAuthInterceptor(const String.fromEnvironment('SUPABASE_KEY')),
      );
  }

  static final SupabaseRestClient instance = SupabaseRestClient._();
  late final Dio _dio;

  Future<List<dynamic>> getList(String path) async {
    final response = await _dio.get<List<dynamic>>(path);
    return response.data ?? [];
  }

  Future<dynamic> rpc(String rpcName, Map<String, dynamic> params) async {
    final response = await _dio.post<dynamic>('rpc/$rpcName', data: params);
    return response.data;
  }
}
