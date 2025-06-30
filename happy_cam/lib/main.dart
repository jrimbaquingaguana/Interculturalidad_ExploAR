import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:happy_cam/firebase_options.dart';
import 'login_page.dart';
import 'register_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // IMPORTANTE para que Flutter esté listo
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('es');

  final Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
    'fr': 'Français',
    'pt': 'Português',
  };

  void _changeLanguage(String? languageCode) {
    if (languageCode != null && supportedLanguages.containsKey(languageCode)) {
      setState(() {
        _locale = Locale(languageCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inicio',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: supportedLanguages.keys.map((code) => Locale(code)).toList(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(
        currentLocale: _locale,
        supportedLanguages: supportedLanguages,
        onLocaleChange: _changeLanguage,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Locale currentLocale;
  final Map<String, String> supportedLanguages;
  final ValueChanged<String?> onLocaleChange;

  const HomeScreen({
    super.key,
    required this.currentLocale,
    required this.supportedLanguages,
    required this.onLocaleChange,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              dropdownColor: Colors.indigo.shade50,
              underline: const SizedBox(),
              value: currentLocale.languageCode,
              icon: const Icon(Icons.language, color: Colors.white),
              items: supportedLanguages.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(color: Colors.indigo),
                  ),
                );
              }).toList(),
              onChanged: onLocaleChange,
            ),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.black.withOpacity(0.3),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/welcome.png',
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: MediaQuery.of(context).size.width * 0.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.welcome,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1, 1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.indigo.shade800,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          elevation: 6,
                        ),
                        child: Text(localizations.loginButton),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(
                                currentLocale: currentLocale,
                                supportedLanguages: supportedLanguages,
                                onLocaleChange: onLocaleChange,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text(localizations.noAccount),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
