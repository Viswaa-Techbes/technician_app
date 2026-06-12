import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/core/api/api_client.dart';
import 'package:customer_app/core/api/api_exceptions.dart';

class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response {}

void main() {
  group('ApiClient Tests', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient.instance;
    });

    test('ApiClient singleton is indeed a single instance', () {
      final instance1 = ApiClient.instance;
      final instance2 = ApiClient.instance;
      expect(instance1, same(instance2));
    });

    test('ApiClient initializes base options correctly', () {
      expect(apiClient.dio.options.baseUrl, isNotEmpty);
      expect(apiClient.dio.options.connectTimeout, const Duration(seconds: 15));
    });
  });
}
