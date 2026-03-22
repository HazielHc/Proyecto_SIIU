// lib/database_helper.dart
import 'package:mysql1/mysql1.dart';
import 'package:bcrypt/bcrypt.dart';

class DatabaseHelper {
  // ── CONEXIÓN ──────────────────────────────────────────────
  Future<MySqlConnection> getConnection() async {
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: null,
      db: 'siiu',
    );
    return await MySqlConnection.connect(settings);
  }

  // ── LOGIN ─────────────────────────────────────────────────
  // Verifica correo y contraseña, devuelve el Usuario o null si falla
  Future<Usuario?> login(String correo, String contrasena) async {
    final conn = await getConnection();
    try {
      var results = await conn.query(
        'SELECT id, nombre, correo, contrasena, rol FROM usuario WHERE correo = ?',
        [correo],
      );

      if (results.isEmpty) return null; // correo no existe

      final row = results.first;
      final String hashGuardado = row[3] as String;

      // Verificar contraseña con bcrypt
      final bool esValida = BCrypt.checkpw(contrasena, hashGuardado);
      if (!esValida) return null; // contraseña incorrecta

      return Usuario(
        id: row[0] as int,
        nombre: row[1] as String,
        correo: row[2] as String,
        rol: row[4] as String,
      );
    } catch (e) {
      print('Error en login: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  // ── REGISTRAR USUARIO (solo admin) ────────────────────────
  // Crea el registro en `usuario` y en la tabla del rol correspondiente
  Future<bool> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required String matricula,
    String? carrera,               // solo para estudiantes
    List<int>? idsProfesiones,     // solo para docentes
  }) async {
    final conn = await getConnection();
    try {
      // Encriptar contraseña
      final String hash = BCrypt.hashpw(contrasena, BCrypt.gensalt());

      // 1. Insertar en tabla usuario
      var result = await conn.query(
        'INSERT INTO usuario (nombre, correo, contrasena, rol) VALUES (?, ?, ?, ?)',
        [nombre, correo, hash, rol],
      );
      final int idUsuario = result.insertId!;

      // 2. Insertar en la tabla del rol correspondiente
      if (rol == 'estudiante') {
        await conn.query(
          'INSERT INTO estudiante (matricula, carrera, id_usuario) VALUES (?, ?, ?)',
          [matricula, carrera ?? '', idUsuario],
        );
      } else if (rol == 'docente') {
        await conn.query(
          'INSERT INTO docente (matricula, id_usuario) VALUES (?, ?)',
          [matricula, idUsuario],
        );
        // 3. Insertar profesiones del docente
        if (idsProfesiones != null && idsProfesiones.isNotEmpty) {
          for (final idProfesion in idsProfesiones) {
            await conn.query(
              'INSERT INTO usuario_profesion (id_usuario, id_profesion) VALUES (?, ?)',
              [idUsuario, idProfesion],
            );
          }
        }
      } else if (rol == 'administrador') {
        await conn.query(
          'INSERT INTO administrador (matricula, id_usuario) VALUES (?, ?)',
          [matricula, idUsuario],
        );
      }

      return true;
    } catch (e) {
      print('Error al registrar usuario: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  // ── PROFESIONES ───────────────────────────────────────────

  // Obtener todas las profesiones (para mostrar checkboxes)
  Future<List<Profesion>> getProfesiones() async {
    final conn = await getConnection();
    List<Profesion> lista = [];
    try {
      var results = await conn.query('SELECT id, nombre FROM profesion');
      for (var row in results) {
        lista.add(Profesion(id: row[0] as int, nombre: row[1] as String));
      }
    } catch (e) {
      print('Error al obtener profesiones: $e');
    } finally {
      await conn.close();
    }
    return lista;
  }

  // Agregar una nueva profesión
  Future<bool> agregarProfesion(String nombre) async {
    final conn = await getConnection();
    try {
      await conn.query(
        'INSERT INTO profesion (nombre) VALUES (?)',
        [nombre],
      );
      return true;
    } catch (e) {
      print('Error al agregar profesión: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  // ── USUARIOS ──────────────────────────────────────────────

  // Obtener todos los usuarios (para panel admin)
  Future<List<Usuario>> getUsuarios() async {
    final conn = await getConnection();
    List<Usuario> usuarios = [];
    try {
      var results = await conn.query(
        'SELECT id, nombre, correo, rol FROM usuario ORDER BY rol, nombre',
      );
      for (var row in results) {
        usuarios.add(Usuario(
          id: row[0] as int,
          nombre: row[1] as String,
          correo: row[2] as String,
          rol: row[3] as String,
        ));
      }
    } catch (e) {
      print('Error al obtener usuarios: $e');
    } finally {
      await conn.close();
    }
    return usuarios;
  }

  // Actualizar contraseña (encripta con bcrypt)
  Future<bool> actualizarContrasena(int idUsuario, String nuevaContrasena) async {
    final conn = await getConnection();
    try {
      final String hash = BCrypt.hashpw(nuevaContrasena, BCrypt.gensalt());
      await conn.query(
        'UPDATE usuario SET contrasena = ? WHERE id = ?',
        [hash, idUsuario],
      );
      return true;
    } catch (e) {
      print('Error al actualizar contraseña: $e');
      return false;
    } finally {
      await conn.close();
    }
  }
}

// ── MODELOS ───────────────────────────────────────────────────

class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });
}

class Profesion {
  final int id;
  final String nombre;

  Profesion({required this.id, required this.nombre});
}