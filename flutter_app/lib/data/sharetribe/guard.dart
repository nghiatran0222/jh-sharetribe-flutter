import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/app_error.dart';
import '../../core/result.dart';

/// Runs a repository body and turns every throw into an [Err] (ADR 0009),
/// so no exception leaves a repository. Used by the live *and* the mock
/// repositories: both talk to a TokenStore, which can throw a
/// PlatformException on a real device.
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on DioException catch (e) {
    return Err(appErrorFromDio(e));
  } on FormatException catch (e) {
    return Err(UnexpectedError(e.message));
  } catch (e) {
    return Err(UnexpectedError('$e'));
  }
}

/// Maps a dio failure to a domain error.
AppError appErrorFromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkError();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 401) return const Unauthorized();
      return ServerError(status, code: sharetribeErrorCode(e.response?.data));
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return e.error is IOException || e.error is TimeoutException
          ? const NetworkError()
          : UnexpectedError('${e.error ?? e.message}');
  }
}

/// Sharetribe error bodies look like `{"errors": [{"code": "...", ...}]}`.
/// Returns the first code, or an empty string when the body has none.
String sharetribeErrorCode(Object? body) {
  if (body is! Map) return '';
  final errors = body['errors'];
  if (errors is! List || errors.isEmpty) return '';
  final first = errors.first;
  return first is Map && first['code'] is String ? first['code'] as String : '';
}
