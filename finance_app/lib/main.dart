import 'package:finance_app/providers/main_currency_provider.dart';
import 'package:flutter/material.dart';
import 'pages/starting_page.dart';
import 'theme/color_schemes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedSchemeName = prefs.getString('selectedColorScheme') ?? 'Cold';
  final savedScheme = appColorSchemes[savedSchemeName]!;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(
            initialSchemeName: savedSchemeName,
            initialScheme: savedScheme,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MainCurrencyProvider()),
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