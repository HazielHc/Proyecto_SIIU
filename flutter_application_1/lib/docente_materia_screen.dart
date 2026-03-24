// lib/docente_materia_screen.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'docente_calificaciones_screen.dart';

class DocenteMateriaScreen extends StatefulWidget {
  final Usuario usuario;
  final MateriaItem materia;
  final int idDocente;

  const DocenteMateriaScreen({
    super.key,
    required this.usuario,
    required this.materia,
    required this.idDocente,
  });

  @override
  State<DocenteMateriaScreen> createState() => _DocenteMateriaScreenState();
}

class _DocenteMateriaScreenState extends State<DocenteMateriaScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<EstudianteItem> _estudiantes = [];
  // Promedios finales por id de estudiante
  Map<int, double?> _promedios = {};
  bool _cargando = true;
  String _busqueda = '';

  static const Color _azulOscuro = Color(0xFF1B2A4A);
  static const Color _azulMedio  = Color(0xFF2D4A7A);
  static const Color _azulClaro  = Color(0xFF4A7CC7);
  static const Color _fondoGris  = Color(0xFFF4F6FB);
  static const Color _verde      = Color(0xFF3D7A5E);
  static const Color _rojo       = Color(0xFFB03D3D);

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() => _cargando = true);
    try {
      final estudiantes =
          await _db.getEstudiantesPorMateria(widget.materia.id);
      final Map<int, double?> promedios = {};
      for (final est in estudiantes) {
        final p = await _db.getPromedio(est.id, widget.materia.id);
        promedios[est.id] = p;
      }
      setState(() {
        _estudiantes = estudiantes;
        _promedios = promedios;
      });
    } catch (e) {
      debugPrint('Error al cargar estudiantes: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  List<EstudianteItem> get _estudiantesFiltrados {
    if (_busqueda.isEmpty) return _estudiantes;
    final q = _busqueda.toLowerCase();
    return _estudiantes
        .where((e) =>
            e.nombre.toLowerCase().contains(q) ||
            e.matricula.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoGris,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildBuscador(),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _azulClaro))
                  : RefreshIndicator(
                      onRefresh: _cargarEstudiantes,
                      color: _azulClaro,
                      child: _estudiantesFiltrados.isEmpty
                          ? _buildVacio()
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: _estudiantesFiltrados.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _buildTarjetaEstudiante(
                                  _estudiantesFiltrados[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_azulOscuro, _azulMedio],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    const Text(
                      'Lista de Estudiantes',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.materia.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChip(Icons.tag_rounded, 'Clave: ${widget.materia.clave}'),
              const SizedBox(width: 10),
              _buildChip(Icons.people_outline_rounded,
                  '${_estudiantes.length} alumnos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(texto,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // ── BUSCADOR ──────────────────────────────────────────────
  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: TextField(
        onChanged: (v) => setState(() => _busqueda = v),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o matrícula...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── TARJETA ESTUDIANTE ────────────────────────────────────
  Widget _buildTarjetaEstudiante(EstudianteItem est) {
    final promedio = _promedios[est.id];
    final tienePromedio = promedio != null;
    final aprobado = tienePromedio && promedio >= 6.0;

    Color colorPromedio;
    if (!tienePromedio) {
      colorPromedio = Colors.grey;
    } else if (promedio >= 8.0) {
      colorPromedio = _verde;
    } else if (promedio >= 6.0) {
      colorPromedio = const Color(0xFF8A7A2D);
    } else {
      colorPromedio = _rojo;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocenteCalificacionesScreen(
              usuario: widget.usuario,
              materia: widget.materia,
              estudiante: est,
            ),
          ),
        ).then((_) => _cargarEstudiantes());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _azulOscuro.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar con inicial
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE3EDF9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  est.nombre.isNotEmpty
                      ? est.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: _azulMedio,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Nombre y matrícula
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    est.nombre,
                    style: const TextStyle(
                      color: _azulOscuro,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    est.matricula,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Promedio o badge pendiente
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tienePromedio
                        ? colorPromedio.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tienePromedio
                        ? promedio.toStringAsFixed(1)
                        : 'Pendiente',
                    style: TextStyle(
                      color: tienePromedio ? colorPromedio : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (tienePromedio) ...[
                  const SizedBox(height: 4),
                  Text(
                    aprobado ? 'Aprobado' : 'Reprobado',
                    style: TextStyle(
                      color: colorPromedio,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }

  // ── VACÍO ─────────────────────────────────────────────────
  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            _busqueda.isEmpty
                ? 'No hay estudiantes inscritos'
                : 'Sin resultados para "$_busqueda"',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}