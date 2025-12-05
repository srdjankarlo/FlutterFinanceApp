import 'package:finance_app/providers/main_currency_provider.dart';
import 'package:flutter/material.dart';
import 'pages/starting_page.dart';
import 'theme/color_schemes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/app_database.dart';
import 'services/currency_conversion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Ensure DB is ready
  await AppDatabase.instance.init();

  // 2) Ensure conversion service has loaded cached rates
  await CurrencyConversionService.instance.init();

  // 3) Load saved theme selection
  final prefs = await SharedPreferences.getInstance();
  final savedSchemeName = prefs.getString('selectedColorScheme') ?? 'Cold';
  final savedScheme = appColorSchemes[savedSchemeName]!;

  // 4) Create a ready MainCurrencyProvider (reads shared prefs + DB)
  final mainCurrencyProvider = await MainCurrencyProvider.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(
            initialSchemeName: savedSchemeName,
            initialScheme: savedScheme,
          ),
        ),
        ChangeNotifierProvider<MainCurrencyProvider>.value(
          value: mainCurrencyProvider,
        ),
      ],
      child: const FinanceApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  String _schemeName;
  ColorScheme _scheme;

  ThemeProvider({
    required String initialSchemeName,
    required ColorScheme initialScheme,
  })  : _schemeName = initialSchemeName,
        _scheme = initialScheme;

  ColorScheme get scheme => _scheme;
  String get schemeName => _schemeName;

  Future<void> changeScheme(String newName) async {
    if (newName == _schemeName) return;
    _schemeName = newName;
    _scheme = appColorSchemes[newName]!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedColorScheme', newName);
    notifyListeners();
  }
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Finance App',
      theme: ThemeData(
        colorScheme: themeProvider.scheme,
        useMaterial3: false,
      ),
      home: const StartingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
