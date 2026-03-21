
// lib/database_helper.dart
import 'package:mysql1/mysql1.dart';

class DatabaseHelper {
  // Configuración de la conexión
  Future<MySqlConnection> getConnection() async {
    final settings = ConnectionSettings(
      host: '10.0.2.2', // Usa 'localhost' si ejecutas en Web o iOS. En emulador Android usa '10.0.2.2'
      port: 3306,
      user: 'root', // Usuario por defecto en XAMPP
      password: '', // Contraseña por defecto está vacía en XAMPP
      db: 'flutter_app_db' // El nombre de la BD que creamos
    );

    return await MySqlConnection.connect(settings);
  }
}