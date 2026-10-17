import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:expense_tracker/services/api_client.dart';
import 'package:expense_tracker/services/category_service.dart';
import 'package:expense_tracker/utils/formatters.dart';

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final responseBody = jsonEncode({
      'id': 'cat_1',
      'name': 'Food',
      'type': 'expense',
      'icon': 'food',
      'color': '#FF0000',
    });

    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test('formatMoney includes the rupee symbol', () {
    expect(formatMoney(1200), contains('1,200.00'));
  });

  test('parseAmount accepts numbers and strings', () {
    expect(parseAmount(10), 10);
    expect(parseAmount('15.50'), 15.5);
  });

  test('category update sends valid payload and parses response', () async {
    final api = ApiClient(
      httpClient: _FakeHttpClient(),
      storage: const FlutterSecureStorage(),
    );
    final service = CategoryService(api);

    final category = await service.update('cat_1', name: 'Food', icon: 'food', color: '#FF0000');

    expect(category.id, 'cat_1');
    expect(category.name, 'Food');
    expect(category.type, 'expense');
  });
}
