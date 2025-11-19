import '../core.dart';

class NotFoundException implements Exception {
  NotFoundException(this.message);

  final String? message;

  @override
  String toString() => message ?? '';
}

class UnSupportedException implements Exception {
  UnSupportedException(this.message);

  final String? message;

  @override
  String toString() => message ?? '';
}

class LogicalException implements Exception {
  LogicalException(this.message);

  final String? message;

  @override
  String toString() => message ?? '';
}

class ServiceException implements Exception {
  ServiceException(this.model);

  final ExceptionModel? model;

  @override
  String toString() => model?.message ?? '';
}

sealed class ErrorCode {
  final String code;
  final String message;
  final String? description;

  ErrorCode({required this.code, required this.message, required this.description});
}

class Er100 extends ErrorCode {
  Er100() : super(code: 'err100', message: 'STATE_NOT_MATCHED', description: '프로필 상태와 권한 상태가 일치하지 않음');
}

class Er200 extends ErrorCode {
  Er200() : super(code: 'err200', message: 'PROFILE_NOT_FOUND', description: '권한은 제한되어있지만 프로필을 찾을 수 없음');
}

class Er300 extends ErrorCode {
  Er300() : super(code: 'err300', message: 'PROFILE_NOT_FOUND', description: '권한은 허용되어있지만 프로필을 찾을 수 없음');
}

class Er400 extends ErrorCode {
  Er400() : super(code: 'err400', message: 'NETWORK_ERROR', description: '인터넷이 연결되어있지 않음');
}

class Er500 extends ErrorCode {
  Er500() : super(code: 'err500', message: 'UNKNOWN_ERROR', description: '알 수 없는 에러');
}
