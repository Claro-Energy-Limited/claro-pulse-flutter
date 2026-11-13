import 'package:dio/dio.dart';

import '../models/smartnet_models.dart';
import 'api_exception.dart';

abstract final class SmartnetConfig {
  static const String baseUrl =
      'https://es0uan7xw1.execute-api.ap-south-1.amazonaws.com/default/smartnetFinal_dataService_15042024_002';
}

class SmartnetApi {
  SmartnetApi({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  final Dio _dio;

  static Dio _createDefaultDio() {
    return Dio(
      BaseOptions(
        baseUrl: SmartnetConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ),
    );
  }

  Future<T> _getWithRetry<T>(
    String url,
    Map<String, dynamic> queryParams,
    T Function(dynamic data) parse,
  ) async {
    dynamic lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _dio.get<dynamic>(url, queryParameters: queryParams);
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          final msg = data['message'] as String? ?? '';
          if (msg.contains('No data found') || response.statusCode == 400) {
            throw ApiException(message: msg);
          }
        }
        return parse(data);
      } on DioException catch (e) {
        lastError = e;
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final map = e.response!.data as Map<String, dynamic>;
          if (map.containsKey('message')) {
            throw ApiException(
              message: map['message'] as String? ?? 'API Error',
            );
          }
        }
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }
      } catch (e) {
        lastError = e;
        if (e is ApiException) rethrow;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }
      }
    }
    throw ApiException(
      message: lastError is DioException ? lastError.message ?? 'Network error' : '$lastError',
    );
  }

  /// Fetches latest telemetry (`op=lat`).
  Future<SmartnetLatestReading?> fetchLatest(String sno) async {
    return _getWithRetry<SmartnetLatestReading?>(
      '',
      {'op': 'lat', 'sno': sno},
      (data) {
        if (data is Map<String, dynamic>) {
          if (data.containsKey('message') &&
              (data['message'] as String).contains('No data found')) {
            return null;
          }
          return SmartnetLatestReading.fromJson(data);
        }
        return null;
      },
    );
  }

  /// Fetches today's graph (`op=tg`).
  Future<SmartnetTodayGraph?> fetchTodayGraph(String sno, String startingTimeUtc) async {
    return _getWithRetry<SmartnetTodayGraph?>(
      '',
      {'op': 'tg', 'sno': sno, 'startingTime': startingTimeUtc},
      (data) {
        if (data is Map<String, dynamic>) {
          return SmartnetTodayGraph.fromJson(data);
        }
        return null;
      },
    );
  }

  /// Fetches last 7 days daily generation (`op=7d`).
  Future<Smartnet7DaysHistory?> fetchLast7Days(String sno) async {
    return _getWithRetry<Smartnet7DaysHistory?>(
      '',
      {'op': '7d', 'sno': sno},
      (data) {
        if (data is Map<String, dynamic>) {
          return Smartnet7DaysHistory.fromJson(data);
        }
        return null;
      },
    );
  }

  /// Fetches month daily generation (`op=mg`).
  Future<SmartnetMonthHistory?> fetchMonth(String sno, String startingTimeUtc) async {
    return _getWithRetry<SmartnetMonthHistory?>(
      '',
      {'op': 'mg', 'sno': sno, 'startingTime': startingTimeUtc},
      (data) {
        if (data is Map<String, dynamic>) {
          return SmartnetMonthHistory.fromJson(data);
        }
        return null;
      },
    );
  }

  /// Fetches custom range records (`op=cr`).
  Future<List<SmartnetCustomRangePoint>> fetchCustomRange({
    required String sno,
    required String startingTimeUtc,
    required String endTimeUtc,
    int intervalMinutes = 10,
    required String fields,
    double? ratingKw,
  }) async {
    final query = <String, dynamic>{
      'op': 'cr',
      'sno': sno,
      'startingTime': startingTimeUtc,
      'endTime': endTimeUtc,
      'interval': intervalMinutes.toString(),
      'fields': fields,
    };
    if (ratingKw != null) {
      query['rat'] = ratingKw.toString();
    }

    return _getWithRetry<List<SmartnetCustomRangePoint>>(
      '',
      query,
      (data) {
        if (data is Map<String, dynamic>) {
          final items = data['items'] as List<dynamic>? ?? [];
          return items
              .whereType<Map<String, dynamic>>()
              .map((m) => SmartnetCustomRangePoint.fromJson(m))
              .toList();
        }
        return [];
      },
    );
  }
}
