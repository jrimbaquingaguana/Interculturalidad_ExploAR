import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'user_storage.dart';
import 'menu_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passController = TextEditingController();
  final _repeatPassController = TextEditingController();

  bool _showPassword = false;
  bool _showRepeatPassword = false;

  final UserStorage _userStorage = UserStorage();

  final RegExp _nameRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
  final RegExp _emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final user = {
        "nombre": _nombreController.text.trim(),
        "apellido": _apellidoController.text.trim(),
        "correo": _correoController.text.trim(),
        "usuario": _usuarioController.text.trim(),
        "contrasena": _passController.text,
      };
      await _userStorage.addUser(user);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.registerSuccess),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage()),
        (route) => false,
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.registerTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        elevation: 5,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: _inputDecoration(loc.name, Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) return loc.required;
                  if (!_nameRegExp.hasMatch(value)) {
                    return loc.invalidName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoController,
                decoration: _inputDecoration(loc.lastname, Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) return loc.required;
                  if (!_nameRegExp.hasMatch(value)) {
                    return loc.invalidName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(loc.email, Icons.email),
                validator: (value) {
                  if (value == null || value.isEmpty) return loc.required;
                  if (!_emailRegExp.hasMatch(value)) {
                    return loc.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usuarioController,
                decoration: _inputDecoration(loc.username, Icons.account_circle),
                validator: (value) =>
                    (value == null || value.isEmpty) ? loc.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passController,
                obscureText: !_showPassword,
                decoration: _inputDecoration(loc.password, Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return loc.required;
                  if (value.length < 6) return loc.shortPassword;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repeatPassController,
                obscureText: !_showRepeatPassword,
                decoration: _inputDecoration(loc.repeatPassword, Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showRepeatPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showRepeatPassword = !_showRepeatPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return loc.required;
                  if (value != _passController.text) return loc.passwordMismatch;
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  child: Text(loc.registerButton, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
