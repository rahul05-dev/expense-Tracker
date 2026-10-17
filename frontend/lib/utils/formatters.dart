import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';

final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
final dateFormat = DateFormat('dd MMM yyyy');
final monthYearFormat = DateFormat('MMMM yyyy');

String formatMoney(double value) => currencyFormat.format(value);

Color amountColor(String type) {
  return type == 'income' ? AppColors.income : AppColors.expense;
}

IconData iconFromName(String? name) {
  switch (name) {
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'directions_car':
      return Icons.directions_car_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'receipt_long':
      return Icons.receipt_long_rounded;
    case 'movie':
      return Icons.movie_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'laptop':
      return Icons.laptop_rounded;
    case 'storefront':
      return Icons.storefront_rounded;
    case 'card_giftcard':
      return Icons.card_giftcard_rounded;
    default:
      return Icons.category_rounded;
  }
}

Color parseHexColor(String? hex, {Color fallback = const Color(0xFF0F766E)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var value = hex.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

double parseAmount(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String friendlyError(Object error) {
  final text = error.toString().replaceFirst('ApiException: ', '');
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return 'Cannot reach the server. Check that the API is running and the base URL is correct.';
  }
  if (text.contains('TimeoutException') || text.contains('timed out')) {
    return 'The server took too long to respond. Please try again.';
  }
  return text;
}
