import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserStorage {
  static const String _fileName = "users.json";

  // Obtiene el archivo local donde se guardarán los usuarios
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Lee y devuelve la lista de usuarios almacenados
  Future<List<Map<String, dynamic>>> _readUsers() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString(encoding: utf8);
      if (content.trim().isEmpty) {
        return [];
      }

      final List<dynamic> jsonData = json.decode(content);
      return List<Map<String, dynamic>>.from(jsonData);
    } catch (e) {
      print('Error leyendo usuarios: $e');
      return [];
    }
  }

  // Escribe la lista actualizada de usuarios en el archivo
  Future<void> _writeUsers(List<Map<String, dynamic>> users) async {
    try {
      final file = await _getLocalFile();
      final jsonString = const JsonEncoder.withIndent('  ').convert(users);
      await file.writeAsString(jsonString, encoding: utf8);
    } catch (e) {
      print('Error escribiendo usuarios: $e');
      rethrow;
    }
  }

  // Agrega un usuario solo si no existe otro con el mismo nombre de usuario
  Future<bool> addUser(Map<String, dynamic> user) async {
    final users = await _readUsers();

    final existeUsuario = users.any((u) => u['usuario'] == user['usuario']);
    if (existeUsuario) {
      print('El usuario "${user['usuario']}" ya existe.');
      return false; // No se añadió por duplicado
    }

    users.add(user);
    print('Guardando usuarios: $users');
    await _writeUsers(users);
    return true;
  }

  // Actualiza un usuario existente por su nombre de usuario
  Future<void> updateUser(Map<String, dynamic> user) async {
    final users = await _readUsers();
    final index = users.indexWhere((u) => u['usuario'] == user['usuario']);
    if (index != -1) {
      users[index] = user;
      await _writeUsers(users);
    } else {
      throw Exception('Usuario no encontrado');
    }
  }

  // Elimina un usuario por su nombre de usuario
  Future<void> deleteUser(String usuario) async {
    final users = await _readUsers();
    users.removeWhere((u) => u['usuario'] == usuario);
    await _writeUsers(users);
  }

  // Carga la lista completa de usuarios
  Future<List<Map<String, dynamic>>> loadUsers() async {
    return await _readUsers();
  }
}
