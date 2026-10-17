import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/transaction_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const storage = FlutterSecureStorage();
    final api = ApiClient(storage: storage);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService(api), storage)),
        ChangeNotifierProvider(create: (_) => CategoryProvider(CategoryService(api))),
        ChangeNotifierProvider(create: (_) => TransactionProvider(TransactionService(api))),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.mode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
