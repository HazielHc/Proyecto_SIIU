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
  Future<Usuario?> login(String correo, String contrasena) async {
    final conn = await getConnection();
    try {
      var results = await conn.query(
        'SELECT id, nombre, correo, contrasena, rol FROM usuario WHERE correo = ?',
        [correo],
      );
      if (results.isEmpty) return null;
      final row = results.first;
      final String hashGuardado = row[3] as String;
      final bool esValida = BCrypt.checkpw(contrasena, hashGuardado);
      if (!esValida) return null;
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
  Future<bool> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required String matricula,
    String? carrera,
    List<int>? idsProfesiones,
  }) async {
    final conn = await getConnection();
    try {
      final String hash = BCrypt.hashpw(contrasena, BCrypt.gensalt());
      var result = await conn.query(
        'INSERT INTO usuario (nombre, correo, contrasena, rol) VALUES (?, ?, ?, ?)',
        [nombre, correo, hash, rol],
      );
      final int idUsuario = result.insertId!;
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

  Future<bool> agregarProfesion(String nombre) async {
    final conn = await getConnection();
    try {
      await conn.query('INSERT INTO profesion (nombre) VALUES (?)', [nombre]);
      return true;
    } catch (e) {
      print('Error al agregar profesión: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  // ── CARRERAS ──────────────────────────────────────────────
  Future<List<Carrera>> getCarreras() async {
    final conn = await getConnection();
    List<Carrera> lista = [];
    try {
      var results = await conn.query(
        'SELECT id, nombre FROM carrera ORDER BY nombre',
      );
      for (var row in results) {
        lista.add(Carrera(id: row[0] as int, nombre: row[1] as String));
      }
    } catch (e) {
      print('Error al obtener carreras: $e');
    } finally {
      await conn.close();
    }
    return lista;
  }

  Future<bool> agregarCarrera(String nombre) async {
    final conn = await getConnection();
    try {
      await conn.query('INSERT INTO carrera (nombre) VALUES (?)', [nombre]);
      return true;
    } catch (e) {
      print('Error al agregar carrera: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  // ── USUARIOS ──────────────────────────────────────────────
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

  // ── DOCENTES ──────────────────────────────────────────────
  Future<List<DocenteItem>> getDocentes() async {
    final conn = await getConnection();
    List<DocenteItem> lista = [];
    try {
      var results = await conn.query(
        'SELECT d.id, u.nombre, d.matricula '
        'FROM docente d '
        'JOIN usuario u ON d.id_usuario = u.id '
        'ORDER BY u.nombre',
      );
      for (var row in results) {
        lista.add(DocenteItem(
          id: row[0] as int,
          nombre: row[1] as String,
          matricula: row[2] as String,
        ));
      }
    } catch (e) {
      print('Error al obtener docentes: $e');
    } finally {
      await conn.close();
    }
    return lista;
  }

  Future<int?> getIdDocente(int idUsuario) async {
    final conn = await getConnection();
    try {
      var results = await conn.query(
        'SELECT id FROM docente WHERE id_usuario = ?',
        [idUsuario],
      );
      if (results.isEmpty) return null;
      return results.first[0] as int;
    } catch (e) {
      print('Error al obtener id_docente: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  // ── ESTUDIANTES ───────────────────────────────────────────
  Future<List<EstudianteItem>> getEstudiantes() async {
    final conn = await getConnection();
    List<EstudianteItem> lista = [];
    try {
      var results = await conn.query(
        'SELECT e.id, u.nombre, e.matricula, e.carrera '
        'FROM estudiante e '
        'JOIN usuario u ON e.id_usuario = u.id '
        'ORDER BY u.nombre',
      );
      for (var row in results) {
        lista.add(EstudianteItem(
          id: row[0] as int,
          nombre: row[1] as String,
          matricula: row[2] as String,
          carrera: row[3] as String,
        ));
      }
    } catch (e) {
      print('Error al obtener estudiantes: $e');
    } finally {
      await conn.close();
    }
    return lista;
  }

  Future<int?> getIdEstudiante(int idUsuario) async {
    final conn = await getConnection();
    try {
      var results = await conn.query(
        'SELECT id FROM estudiante WHERE id_usuario = ?',
        [idUsuario],
      );
      if (results.isEmpty) return null;
      return results.first[0] as int;
    } catch (e) {
      print('Error al obtener id_estudiante: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, String>?> getDatosEstudiante(int idUsuario) async {
    final conn = await getConnection();
    try {
      var results = await conn.query(
        'SELECT e.id, e.matricula, e.carrera FROM estudiante e WHERE e.id_usuario = ?',
        [idUsuario],
      );
      if (results.isEmpty) return null;
      final row = results.first;
      return {
        'id':        (row[0] as int).toString(),
        'matricula': row[1] as String,
        'carrera':   row[2] as String,
      };
    } catch (e) {
      print('Error al obtener datos del estudiante: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<List<MateriaItem>> getMateriasPorEstudiante(int idEstudiante) async {
    final conn = await getConnection();
    List<MateriaItem> lista = [];
    try {
      var results = await conn.query(
        'SELECT m.id, m.nombre, m.clave, m.id_docente, u.nombre '
        'FROM materia_estudiante me '
        'JOIN materia m ON me.id_materia = m.id '
        'JOIN docente d ON m.id_docente = d.id '
        'JOIN usuario u ON d.id_usuario = u.id '
        'WHERE me.id_estudiante = ? '
        'ORDER BY m.nombre',
        [idEstudiante],
      );
      for (var row in results) {
        lista.add(MateriaItem(
          id: row[0] as int,
          nombre: row[1] as String,
          clave: row[2] as String,
          idDocente: row[3] as int,
          nombreDocente: row[4] as String,
        ));
      }
    } catch (e) {
      print('Error al obtener materias del estudiante: $e');
    } finally {
      await conn.close();
    }
    return lista;
  }

  // ── MATERIAS ──────────────────────────────────────────────
  Future<List<MateriaItem>> getMaterias() async {
    final conn = await getConnection();
    List<MateriaItem> lista = [];
    try {
      var results = await conn.query(
        'SELECT m.id, m.nombre, m.clave, m.id_docente, u.nombre '
        'FROM materia m '
        'JOIN docente d ON m.id_docente = d.id '
        'JOIN usuario u ON d.id_usuario = u.id '
        'ORDER BY m.nombre',
      );
      for (var row in results) {
        lista.add(MateriaItem(
          id: row[0] as int,
          nombre: row[1] as String,
          clave: row[2] as String,
          idDocente: row[3] as int,
          nombreDocente: row[4] as String,
        ));
      }
    } catch (e) {
      print('Error al obtener materias: $e');
    } finally {
      await conn.close();
    }
    return lista;
  }

  Future<bool> crearMateria({
    required String nombre,
    required String clave,
    required int idDocente,
    required List<int> idsEstudiantes,
  }) async {
    final conn = await getConnection();
    try {
      var result = await conn.query(
        'INSERT INTO materia (nombre, clave, id_docente) VALUES (?, ?, ?)',
        [nombre, clave, idDocente],
      );
      final int idMateria = result.insertId!;
      for (final idEst in idsEstudiantes) {
        await conn.query(
          'INSERT INTO materia_estudiante (id_materia, id_estudiante) VALUES (?, ?)',
          [idMateria, idEst],
        );
      }
      return true;
    } catch (e) {
      print('Error al crear materia: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  Future<List<EstudianteItem>> getEstudiantesPorMateria(int idMateria) async {
    final conn = await getConnection();
    List<EstudianteItem> lista = [];
    try {
      var results = await conn.query(
        'SELECT e.id, u.nombre, e.matricula, e.carrera '
        'FROM materia_estudiante me '
        'JOIN estudiante e ON me.id_estudiante = e.id '
        'JOIN usuario u ON e.id_usuario = u.id '
        'WHERE me.id_materia = ? '
        'ORDER BY u.nombre',
        [idMateria],
      );
      for (var row in results) {
        lista.add(EstudianteItem(
          id: row[0] as int,
          nombre: row[1] as String,
          matricula: row[2] as String,
          carrera: row[3] as String,
        ));
      }
    } catch (e) {
      print('Error al obtener estudiantes por materia: $e');
    } finally {
      await conn.close();
    }
    return lista;
  }

  Future<List<MateriaItem>> getMateriasPorDocente(int idDocente) async {
    final conn = await getConnection();
    List<MateriaItem> lista = [];
    try {
      var results = await conn.query(
        'SELECT m.id, m.nombre, m.clave, m.id_docente, u.nombre '
        'FROM materia m '
        'JOIN docente d ON m.id_docente = d.id '
        'JOIN usuario u ON d.id_usuario = u.id '
        'WHERE m.id_docente = ? '
        'ORDER BY m.nombre',
        [idDocente],
      );
      for (var row in results) {
        lista.add(MateriaItem(
          id: row[0] as int,
          nombre: row[1] as String,
          clave: row[2] as String,
          idDocente: row[3] as int,
          nombreDocente: row[4] as String,
        ));
      }
    } catch (e) {
      print('Error al obtener materias por docente: $e');
    } finally {
      await conn.close();
    }
    return lista;
  }

  // ── CALIFICACIONES ────────────────────────────────────────
  Future<double?> getCalificacion(
      int idEstudiante, int idMateria, int unidad) async {
    final conn = await getConnection();
    try {
      var results = await conn.query(
        'SELECT calificacion FROM calificacion '
        'WHERE id_estudiante = ? AND id_materia = ? AND unidad = ?',
        [idEstudiante, idMateria, unidad],
      );
      if (results.isEmpty) return null;
      final val = results.first[0];
      if (val == null) return null;
      return double.parse(val.toString());
    } catch (e) {
      print('Error al obtener calificación: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  Future<bool> guardarCalificacion({
    required int idEstudiante,
    required int idMateria,
    required int unidad,
    required double calificacion,
  }) async {
    if (calificacion < 0.0 || calificacion > 10.0) return false;
    final conn = await getConnection();
    try {
      var result = await conn.query(
        'UPDATE calificacion SET calificacion = ? '
        'WHERE id_estudiante = ? AND id_materia = ? AND unidad = ?',
        [calificacion, idEstudiante, idMateria, unidad],
      );
      if (result.affectedRows == 0) {
        await conn.query(
          'INSERT INTO calificacion (calificacion, unidad, id_estudiante, id_materia) '
          'VALUES (?, ?, ?, ?)',
          [calificacion, unidad, idEstudiante, idMateria],
        );
      }
      return true;
    } catch (e) {
      print('Error al guardar calificación: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  Future<double?> getPromedio(int idEstudiante, int idMateria) async {
    final conn = await getConnection();
    try {
      var results = await conn.query(
        'SELECT calificacion FROM calificacion '
        'WHERE id_estudiante = ? AND id_materia = ? '
        'ORDER BY unidad',
        [idEstudiante, idMateria],
      );
      if (results.length < 3) return null;
      double suma = 0;
      for (var row in results) {
        suma += double.parse(row[0].toString());
      }
      return suma / results.length;
    } catch (e) {
      print('Error al calcular promedio: $e');
      return null;
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

class Carrera {
  final int id;
  final String nombre;
  Carrera({required this.id, required this.nombre});
}

class DocenteItem {
  final int id;
  final String nombre;
  final String matricula;
  DocenteItem({required this.id, required this.nombre, required this.matricula});
}

class EstudianteItem {
  final int id;
  final String nombre;
  final String matricula;
  final String carrera;
  EstudianteItem({
    required this.id,
    required this.nombre,
    required this.matricula,
    required this.carrera,
  });
}

class MateriaItem {
  final int id;
  final String nombre;
  final String clave;
  final int idDocente;
  final String nombreDocente;
  MateriaItem({
    required this.id,
    required this.nombre,
    required this.clave,
    required this.idDocente,
    required this.nombreDocente,
  });
}