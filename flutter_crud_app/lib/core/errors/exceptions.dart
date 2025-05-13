class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'A server error occurred.']);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'A cache error occurred.']);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'A network error occurred.']);

  @override
  String toString() => 'NetworkException: $message';
}