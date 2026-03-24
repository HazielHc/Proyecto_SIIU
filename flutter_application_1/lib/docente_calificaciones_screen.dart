// lib/docente_calificaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

class DocenteCalificacionesScreen extends StatefulWidget {
  final Usuario usuario;
  final MateriaItem materia;
  final EstudianteItem estudiante;

  const DocenteCalificacionesScreen({
    super.key,
    required this.usuario,
    required this.materia,
    required this.estudiante,
  });

  @override
  State<DocenteCalificacionesScreen> createState() =>
      _DocenteCalificacionesScreenState();
}

class _DocenteCalificacionesScreenState
    extends State<DocenteCalificacionesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  static const int _totalUnidades = 3;

  // Calificaciones actuales: unidad (1-3) → valor o null
  Map<int, double?> _calificaciones = {};
  Map<int, TextEditingController> _controllers = {};
  bool _cargando = true;
  bool _guardando = false;

  static const Color _azulOscuro = Color(0xFF1B2A4A);
  static const Color _azulMedio  = Color(0xFF2D4A7A);
  static const Color _azulClaro  = Color(0xFF4A7CC7);
  static const Color _fondoGris  = Color(0xFFF4F6FB);
  static const Color _verde      = Color(0xFF3D7A5E);
  static const Color _verdeClaro = Color(0xFFE8F5EE);
  static const Color _rojo       = Color(0xFFB03D3D);
  static const Color _rojoClaro  = Color(0xFFF5E8E8);

  @override
  void initState() {
    super.initState();
    for (int u = 1; u <= _totalUnidades; u++) {
      _controllers[u] = TextEditingController();
    }
    _cargarCalificaciones();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCalificaciones() async {
    setState(() => _cargando = true);
    try {
      for (int u = 1; u <= _totalUnidades; u++) {
        final cal = await _db.getCalificacion(
            widget.estudiante.id, widget.materia.id, u);
        _calificaciones[u] = cal;
        _controllers[u]!.text =
            cal != null ? cal.toStringAsFixed(1) : '';
      }
    } catch (e) {
      debugPrint('Error al cargar calificaciones: $e');
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

  Future<void> _guardarCalificacion(int unidad) async {
    final texto = _controllers[unidad]!.text.trim();
    if (texto.isEmpty) return;

    final valor = double.tryParse(texto);
    if (valor == null || valor < 0.0 || valor > 10.0) {
      _mostrarError('La calificación debe estar entre 0.0 y 10.0');
      return;
    }

    // Redondear a 1 decimal
    final valorRedondeado = (valor * 10).round() / 10;

    setState(() => _guardando = true);
    try {
      final exito = await _db.guardarCalificacion(
        idEstudiante: widget.estudiante.id,
        idMateria: widget.materia.id,
        unidad: unidad,
        calificacion: valorRedondeado,
      );

      if (exito) {
        setState(() {
          _calificaciones[unidad] = valorRedondeado;
          _controllers[unidad]!.text = valorRedondeado.toStringAsFixed(1);
        });
        _mostrarExito('Unidad $unidad guardada');
      } else {
        _mostrarError('Error al guardar');
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  Future<void> _reprobarEstudiante() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reprobar estudiante'),
        content: Text(
          '¿Deseas reprobar a ${widget.estudiante.nombre} en ${widget.materia.nombre}?\n\n'
          'Se asignará 0.0 en todas las unidades sin calificación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _rojo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reprobar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _guardando = true);
    try {
      for (int u = 1; u <= _totalUnidades; u++) {
        if (_calificaciones[u] == null) {
          await _db.guardarCalificacion(
            idEstudiante: widget.estudiante.id,
            idMateria: widget.materia.id,
            unidad: u,
            calificacion: 0.0,
          );
          setState(() {
            _calificaciones[u] = 0.0;
            _controllers[u]!.text = '0.0';
          });
        }
      }
      _mostrarExito('Estudiante reprobado');
    } finally {
      setState(() => _guardando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _rojo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _verde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                          _buildCardEstudiante(promedio, aprobado),
                          const SizedBox(height: 20),
                          _buildSeccionUnidades(),
                          const SizedBox(height: 20),
                          _buildBotonReprobar(),
                          const SizedBox(height: 20),
                        ],
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
                      color: Colors.white60,
                      fontSize: 12,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Calificaciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_guardando)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  // ── CARD ESTUDIANTE + PROMEDIO ────────────────────────────
  Widget _buildCardEstudiante(double? promedio, bool aprobado) {
    final colorEstado = promedio == null
        ? Colors.grey
        : aprobado
            ? _verde
            : _rojo;
    final bgEstado = promedio == null
        ? Colors.grey.shade100
        : aprobado
            ? _verdeClaro
            : _rojoClaro;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE3EDF9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                widget.estudiante.nombre.isNotEmpty
                    ? widget.estudiante.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: _azulMedio,
                  fontSize: 22,
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
                  widget.estudiante.nombre,
                  style: const TextStyle(
                    color: _azulOscuro,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.estudiante.matricula,
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          // Promedio final
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgEstado,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  promedio != null
                      ? promedio.toStringAsFixed(1)
                      : '--',
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  promedio == null
                      ? 'Promedio'
                      : aprobado
                          ? 'Aprobado'
                          : 'Reprobado',
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 10,
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

  // ── SECCIÓN UNIDADES ──────────────────────────────────────
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
        ...List.generate(
          _totalUnidades,
          (i) => _buildFilaUnidad(i + 1),
        ),
      ],
    );
  }

  Widget _buildFilaUnidad(int unidad) {
    final calActual = _calificaciones[unidad];
    final tieneCalif = calActual != null;

    Color colorIndicador;
    if (!tieneCalif) {
      colorIndicador = Colors.grey.shade300;
    } else if (calActual >= 8.0) {
      colorIndicador = _verde;
    } else if (calActual >= 6.0) {
      colorIndicador = const Color(0xFF8A7A2D);
    } else {
      colorIndicador = _rojo;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          // Indicador de unidad
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
                  color: colorIndicador == Colors.grey.shade300
                      ? Colors.grey
                      : colorIndicador,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Label
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
          // Campo de texto
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controllers[unidad],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,1}')),
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tieneCalif ? colorIndicador : _azulOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle:
                    TextStyle(color: Colors.grey.shade300, fontSize: 16),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _azulClaro, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Botón guardar unidad
          GestureDetector(
            onTap: _guardando ? null : () => _guardarCalificacion(unidad),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _azulMedio,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTÓN REPROBAR ────────────────────────────────────────
  Widget _buildBotonReprobar() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _guardando ? null : _reprobarEstudiante,
        style: OutlinedButton.styleFrom(
          foregroundColor: _rojo,
          side: const BorderSide(color: _rojo),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.block_rounded, size: 20),
        label: const Text(
          'Reprobar estudiante',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}