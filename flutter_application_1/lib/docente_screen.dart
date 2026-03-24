// lib/docente_screen.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';
import 'docente_materia_screen.dart';

class DocenteScreen extends StatefulWidget {
  final Usuario usuario;
  const DocenteScreen({super.key, required this.usuario});

  @override
  State<DocenteScreen> createState() => _DocenteScreenState();
}

class _DocenteScreenState extends State<DocenteScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<MateriaItem> _materias = [];
  bool _cargando = true;
  int? _idDocente;

  // Paleta de colores coherente con el borrador del estudiante
  static const Color _azulOscuro  = Color(0xFF1B2A4A);
  static const Color _azulMedio   = Color(0xFF2D4A7A);
  static const Color _azulClaro   = Color(0xFF4A7CC7);
  static const Color _fondoGris   = Color(0xFFF4F6FB);
  static const Color _verde       = Color(0xFF3D7A5E);
  static const Color _verdeClaro  = Color(0xFFE8F5EE);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final idDocente = await _db.getIdDocente(widget.usuario.id);
      if (idDocente != null) {
        final materias = await _db.getMateriasPorDocente(idDocente);
        setState(() {
          _idDocente = idDocente;
          _materias = materias;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos docente: $e');
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
                            _buildResumenCard(),
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
                      letterSpacing: 0.2,
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

  // ── CARD RESUMEN ──────────────────────────────────────────
  Widget _buildResumenCard() {
    final totalMaterias = _materias.length;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Materias Asignadas',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalMaterias ${totalMaterias == 1 ? 'materia' : 'materias'}',
                  style: const TextStyle(
                    color: _azulOscuro,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.usuario.correo,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _verdeClaro,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: _verde,
              size: 28,
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
        const Text(
          'Mis Materias',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _azulOscuro,
          ),
        ),
        const SizedBox(height: 14),
        if (_materias.isEmpty)
          _buildEstadoVacio()
        else
          ...List.generate(
            _materias.length,
            (i) => _buildTarjetaMateria(_materias[i], i),
          ),
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
            'Sin materias asignadas',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contacta al administrador',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Colores para las tarjetas de materias (cicla entre varios)
  static const List<List<Color>> _coloresTarjetas = [
    [Color(0xFF1B2A4A), Color(0xFF2D4A7A)],
    [Color(0xFF2D5A3D), Color(0xFF3D7A5E)],
    [Color(0xFF4A2D6B), Color(0xFF6B3D8A)],
    [Color(0xFF7A3D2D), Color(0xFFA05A3D)],
    [Color(0xFF2D4A7A), Color(0xFF3D6AB0)],
  ];

  Widget _buildTarjetaMateria(MateriaItem materia, int index) {
    final colores = _coloresTarjetas[index % _coloresTarjetas.length];
    return GestureDetector(
      onTap: () {
        if (_idDocente != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DocenteMateriaScreen(
                usuario: widget.usuario,
                materia: materia,
                idDocente: _idDocente!,
              ),
            ),
          ).then((_) => _cargarDatos());
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
              child: const Icon(
                Icons.class_outlined,
                color: Colors.white,
                size: 24,
              ),
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
                    'Clave: ${materia.clave}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
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
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFFE3EDF9),
              child: Icon(Icons.school_rounded,
                  size: 36, color: _azulMedio),
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
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE3EDF9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Docente',
                style: TextStyle(
                    color: _azulMedio, fontWeight: FontWeight.w600),
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
              backgroundColor: _azulMedio,
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