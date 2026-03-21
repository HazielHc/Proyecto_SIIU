// lib/database_helper.dart
import 'package:mysql1/mysql1.dart';

class DatabaseHelper {
  // Configuración de la conexión
  Future<MySqlConnection> getConnection() async {
    final settings = ConnectionSettings(
      host: 'localhost', // Usa 'localhost' si ejecutas en Web o iOS. En emulador Android usa '10.0.2.2'
      port: 3306,
      user: 'root',     // Usuario por defecto en XAMPP
      password: '',     // Contraseña por defecto está vacía en XAMPP
      db: 'flutter_app_db', // El nombre de la BD que creamos
    );

    return await MySqlConnection.connect(settings);
  }

  // Método que consulta la tabla y devuelve una lista de objetos Usuario
  Future<List<Usuario>> getUsuarios() async {
    List<Usuario> usuarios = [];
    final conn = await getConnection();

    try {
      // Ejecutar la consulta SQL
      var results = await conn.query('SELECT id, nombre, email FROM usuarios');

      // Recorrer los resultados y convertir cada fila a un objeto Usuario
      for (var row in results) {
        usuarios.add(Usuario(
          id: row[0] as int,
          nombre: row[1] as String,
          email: row[2] as String,
        ));
      }
    } catch (e) {
      print('Error al obtener usuarios: $e');
    } finally {
      // Siempre cerrar la conexión al terminar
      await conn.close();
    }

    return usuarios;
  }
}

// Modelo de datos: representa un registro de la tabla "usuarios"
class Usuario {
  final int id;
  final String nombre;
  final String email;

  Usuario({required this.id, required this.nombre, required this.email});
}