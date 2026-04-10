// lib/estudiante_screen.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';

class EstudianteScreen extends StatefulWidget {
  final Usuario usuario;
  const EstudianteScreen({super.key, required this.usuario});

  @override
  State<EstudianteScreen> createState() => _EstudianteScreenState();
}

class _EstudianteScreenState extends State<EstudianteScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  List<MateriaItem> _materias = [];
  Map<String, String>? _datosEstudiante;
  int? _idEstudiante;
  bool _cargando = true;

  // Paleta idéntica a docente_screen y docente_materia_screen
  static const Color _azulOscuro = Color(0xFF1B2A4A);
  static const Color _azulMedio  = Color(0xFF2D4A7A);
  static const Color _azulClaro  = Color(0xFF4A7CC7);
  static const Color _fondoGris  = Color(0xFFF4F6FB);
  static const Color _verde      = Color(0xFF3D7A5E);
  static const Color _verdeClaro = Color(0xFFE8F5EE);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final datos = await _db.getDatosEstudiante(widget.usuario.id);
      if (datos != null) {
        final idEst = int.parse(datos['id']!);
        final materias = await _db.getMateriasPorEstudiante(idEst);
        setState(() {
          _datosEstudiante = datos;
          _idEstudiante = idEst;
          _materias = materias;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos estudiante: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoGris,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _azulClaro))
                  : RefreshIndicator(
                      onRefresh: _cargarDatos,
                      color: _azulClaro,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCardPerfil(),
                            const SizedBox(height: 24),
                            _buildSeccionMaterias(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B3A2A), Color(0xFF2D5A3D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido/a',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.usuario.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIcon(
                Icons.person_outline,
                onTap: () => _mostrarPerfil(context),
              ),
              const SizedBox(width: 8),
              _buildHeaderIcon(
                Icons.logout_rounded,
                onTap: () => _confirmarCerrarSesion(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── CARD PERFIL ───────────────────────────────────────────
  Widget _buildCardPerfil() {
    final matricula = _datosEstudiante?['matricula'] ?? '—';
    final carrera   = _datosEstudiante?['carrera']   ?? '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _azulOscuro.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar con inicial
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _verdeClaro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                widget.usuario.nombre.isNotEmpty
                    ? widget.usuario.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: _verde,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.usuario.nombre,
                  style: const TextStyle(
                    color: _azulOscuro,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  matricula,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  carrera,
                  style: const TextStyle(color: _verde, fontSize: 12),
                ),
              ],
            ),
          ),
          // Badge de rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _verdeClaro,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Estudiante',
              style: TextStyle(
                color: _verde,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN MATERIAS ──────────────────────────────────────
  Widget _buildSeccionMaterias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Materias',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _azulOscuro,
              ),
            ),
            Text(
              '${_materias.length} inscrita${_materias.length != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_materias.isEmpty)
          _buildEstadoVacio()
        else
          ..._materias.map((m) => _buildTarjetaMateria(m)),
      ],
    );
  }

  Widget _buildEstadoVacio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.library_books_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Sin materias inscritas',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Contacta al administrador',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Colores para las tarjetas (mismo ciclo que en docente_screen)
  static const List<List<Color>> _coloresTarjetas = [
    [Color(0xFF1B3A2A), Color(0xFF2D5A3D)],
    [Color(0xFF1B2A4A), Color(0xFF2D4A7A)],
    [Color(0xFF4A2D6B), Color(0xFF6B3D8A)],
    [Color(0xFF7A3D2D), Color(0xFFA05A3D)],
    [Color(0xFF2D4A7A), Color(0xFF3D6AB0)],
  ];

  Widget _buildTarjetaMateria(MateriaItem materia) {
    final index = _materias.indexOf(materia);
    final colores = _coloresTarjetas[index % _coloresTarjetas.length];

    return GestureDetector(
      onTap: () {
        if (_idEstudiante != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _EstudianteCalificacionesScreen(
                usuario: widget.usuario,
                materia: materia,
                idEstudiante: _idEstudiante!,
                db: _db,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colores,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colores[0].withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.class_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materia.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prof. ${materia.nombreDocente}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Clave: ${materia.clave}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── DIÁLOGOS ──────────────────────────────────────────────
  void _mostrarPerfil(BuildContext context) {
    final matricula = _datosEstudiante?['matricula'] ?? '—';
    final carrera   = _datosEstudiante?['carrera']   ?? '—';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: _verdeClaro,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  widget.usuario.nombre.isNotEmpty
                      ? widget.usuario.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: _verde,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.usuario.nombre,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _azulOscuro),
            ),
            const SizedBox(height: 4),
            Text(widget.usuario.correo,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text('Matrícula: $matricula',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 2),
            Text('Carrera: $carrera',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _verdeClaro,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Estudiante',
                style:
                    TextStyle(color: _verde, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5A3D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PANTALLA DE CALIFICACIONES DEL ESTUDIANTE (solo lectura)
// ══════════════════════════════════════════════════════════════
class _EstudianteCalificacionesScreen extends StatefulWidget {
  final Usuario usuario;
  final MateriaItem materia;
  final int idEstudiante;
  final DatabaseHelper db;

  const _EstudianteCalificacionesScreen({
    required this.usuario,
    required this.materia,
    required this.idEstudiante,
    required this.db,
  });

  @override
  State<_EstudianteCalificacionesScreen> createState() =>
      _EstudianteCalificacionesScreenState();
}

class _EstudianteCalificacionesScreenState
    extends State<_EstudianteCalificacionesScreen> {
  static const int _totalUnidades = 3;
  Map<int, double?> _calificaciones = {};
  bool _cargando = true;

  static const Color _azulOscuro = Color(0xFF1B2A4A);
  static const Color _azulClaro  = Color(0xFF4A7CC7);
  static const Color _fondoGris  = Color(0xFFF4F6FB);
  static const Color _verde      = Color(0xFF3D7A5E);
  static const Color _verdeClaro = Color(0xFFE8F5EE);
  static const Color _rojo       = Color(0xFFB03D3D);
  static const Color _rojoClaro  = Color(0xFFF5E8E8);

  @override
  void initState() {
    super.initState();
    _cargarCalificaciones();
  }

  Future<void> _cargarCalificaciones() async {
    setState(() => _cargando = true);
    try {
      for (int u = 1; u <= _totalUnidades; u++) {
        final cal = await widget.db
            .getCalificacion(widget.idEstudiante, widget.materia.id, u);
        _calificaciones[u] = cal;
      }
    } catch (e) {
      debugPrint('Error al cargar calificaciones estudiante: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  double? _calcularPromedio() {
    final vals = <double>[];
    for (int u = 1; u <= _totalUnidades; u++) {
      if (_calificaciones[u] == null) return null;
      vals.add(_calificaciones[u]!);
    }
    if (vals.length < _totalUnidades) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  @override
  Widget build(BuildContext context) {
    final promedio = _calcularPromedio();
    final aprobado = promedio != null && promedio >= 6.0;

    return Scaffold(
      backgroundColor: _fondoGris,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _azulClaro))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildCardPromedio(promedio, aprobado),
                          const SizedBox(height: 20),
                          _buildSeccionUnidades(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B3A2A), Color(0xFF2D5A3D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.materia.nombre,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Mis Calificaciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPromedio(double? promedio, bool aprobado) {
    final colorEstado = promedio == null
        ? Colors.grey
        : aprobado ? _verde : _rojo;
    final bgEstado = promedio == null
        ? Colors.grey.shade100
        : aprobado ? _verdeClaro : _rojoClaro;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _azulOscuro.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.materia.nombre,
                  style: const TextStyle(
                    color: _azulOscuro,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prof. ${widget.materia.nombreDocente}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clave: ${widget.materia.clave}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: bgEstado,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  promedio != null ? promedio.toStringAsFixed(1) : '--',
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  promedio == null
                      ? 'Promedio'
                      : aprobado ? 'Aprobado' : 'Reprobado',
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionUnidades() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calificaciones por Unidad',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _azulOscuro,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_totalUnidades, (i) => _buildFilaUnidad(i + 1)),
      ],
    );
  }

  Widget _buildFilaUnidad(int unidad) {
    final cal = _calificaciones[unidad];
    final tiene = cal != null;

    Color colorIndicador;
    if (!tiene) {
      colorIndicador = Colors.grey.shade300;
    } else if (cal >= 8.0) {
      colorIndicador = _verde;
    } else if (cal >= 6.0) {
      colorIndicador = const Color(0xFF8A7A2D);
    } else {
      colorIndicador = _rojo;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _azulOscuro.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge de unidad
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorIndicador.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'U$unidad',
                style: TextStyle(
                  color: tiene ? colorIndicador : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Unidad $unidad',
              style: const TextStyle(
                color: _azulOscuro,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Calificación (solo lectura)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorIndicador.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tiene ? cal.toStringAsFixed(1) : 'Pendiente',
              style: TextStyle(
                color: tiene ? colorIndicador : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}