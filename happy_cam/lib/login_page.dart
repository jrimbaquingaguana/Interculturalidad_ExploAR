import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'register_page.dart';
import 'menu_page.dart';
import 'user_storage.dart';

class LoginPage extends StatefulWidget {
  // Recibe estos parámetros para controlar idioma
  final Locale currentLocale;
  final ValueChanged<String?> onLocaleChange;
  final Map<String, String> supportedLanguages;

  const LoginPage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChange,
    required this.supportedLanguages,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final UserStorage _userStorage = UserStorage();
  bool _showPassword = false;

  late String _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = widget.currentLocale.languageCode;
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizar el idioma si cambió desde el widget padre
    if (widget.currentLocale.languageCode != _selectedLanguageCode) {
      setState(() {
        _selectedLanguageCode = widget.currentLocale.languageCode;
      });
    }
  }

  void _onLanguageChanged(String? newCode) {
    if (newCode != null && widget.supportedLanguages.containsKey(newCode)) {
      setState(() {
        _selectedLanguageCode = newCode;
      });
      widget.onLocaleChange(newCode);
    }
  }

  void _login() async {
    final users = await _userStorage.loadUsers();
    final user = users.firstWhere(
      (u) =>
          u['usuario'] == _userController.text &&
          u['contrasena'] == _passController.text,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidCredentials)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.loginTitle),
        centerTitle: true,
        // Aquí removí el 'actions' para quitar el menú desplegable
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _userController,
                          decoration: InputDecoration(
                            labelText: loc.username,
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? loc.required : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: loc.password,
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? loc.required : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFF2575fc),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) _login();
                            },
                            child: Text(loc.loginButton,
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterPage()),
                            );
                          },
                          child: Text(
                            loc.noAccount,
                            style: const TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
