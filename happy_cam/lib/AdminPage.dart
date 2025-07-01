import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'user_storage.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final UserStorage _userStorage = UserStorage();
  List<Map<String, dynamic>> _users = [];

  // Controladores declarados aquí para reutilizar
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passController = TextEditingController();
  String _rol = 'usuario';

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    // Liberar controladores
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _usuarioController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await _userStorage.loadUsers();
    setState(() {
      _users = users;
    });
  }

  void _deleteUser(int index) async {
    await _userStorage.deleteUser(_users[index]['usuario']);
    await _loadUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.deleteSuccess)),
    );
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    final loc = AppLocalizations.of(context)!;

    // Inicializar valores en controladores
    if (user != null) {
      _nombreController.text = user['nombre'] ?? '';
      _apellidoController.text = user['apellido'] ?? '';
      _correoController.text = user['correo'] ?? '';
      _usuarioController.text = user['usuario'] ?? '';
      _passController.clear();
      _rol = user['rol'] ?? 'usuario';
    } else {
      _nombreController.clear();
      _apellidoController.clear();
      _correoController.clear();
      _usuarioController.clear();
      _passController.clear();
      _rol = 'usuario';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? loc.createUser : loc.editUser),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(labelText: loc.name),
                  validator: (v) => v == null || v.isEmpty ? loc.required : null,
                ),
                TextFormField(
                  controller: _apellidoController,
                  decoration: InputDecoration(labelText: loc.lastname),
                  validator: (v) => v == null || v.isEmpty ? loc.required : null,
                ),
                TextFormField(
                  controller: _correoController,
                  decoration: InputDecoration(labelText: loc.email),
                  validator: (v) => v == null || v.isEmpty ? loc.required : null,
                ),
                TextFormField(
                  controller: _usuarioController,
                  decoration: InputDecoration(labelText: loc.username),
                  validator: (v) => v == null || v.isEmpty ? loc.required : null,
                  enabled: user == null,
                ),
                TextFormField(
                  controller: _passController,
                  decoration: InputDecoration(labelText: loc.password),
                  obscureText: true,
                  validator: (v) {
                    if (user == null && (v == null || v.isEmpty)) {
                      return loc.required;
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _rol,
                  decoration: InputDecoration(labelText: loc.role),
                  items: [
                    DropdownMenuItem(value: 'usuario', child: Text(loc.usuario)),
                    DropdownMenuItem(value: 'administrador', child: Text(loc.administrador)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _rol = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text(loc.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(loc.save),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newUser = {
                  "nombre": _nombreController.text.trim(),
                  "apellido": _apellidoController.text.trim(),
                  "correo": _correoController.text.trim(),
                  "usuario": _usuarioController.text.trim(),
                  "contrasena": _passController.text.isNotEmpty
                      ? _passController.text
                      : user?['contrasena'] ?? '',
                  "rol": _rol,
                };
                try {
                  if (user == null) {
                    await _userStorage.addUser(newUser);
                  } else {
                    await _userStorage.updateUser(newUser);
                  }
                  await _loadUsers();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.administer),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(child: Text(user['nombre'][0])),
            title: Text('${user['nombre']} ${user['apellido']}'),
            subtitle: Text('${user['usuario']} (${user['rol'] == 'usuario' ? loc.usuario : loc.administrador})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showUserDialog(user: user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
        tooltip: loc.createUser,
      ),
    );
  }
}
