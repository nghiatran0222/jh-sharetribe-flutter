import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/app_error.dart';
import '../../core/result.dart';

/// Runs a repository body and turns every throw into an [Err] (ADR 0009),
/// so no exception leaves a repository.
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
      return status == 401 ? const Unauthorized() : ServerError(status);
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return e.error is IOException || e.error is TimeoutException
          ? const NetworkError()
          : UnexpectedError('${e.error ?? e.message}');
  }
}
