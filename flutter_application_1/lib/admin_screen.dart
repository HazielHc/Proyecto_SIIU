// lib/admin_screen.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  final Usuario usuario;
  const AdminScreen({super.key, required this.usuario});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel Administrador',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Bienvenido, ${widget.usuario.nombre}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Registrar'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.work), text: 'Profesiones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabRegistrar(db: _db),
          _TabUsuarios(db: _db),
          _TabProfesiones(db: _db),
        ],
      ),
    );
  }
}

// ── TAB 1: REGISTRAR USUARIO ──────────────────────────────────
class _TabRegistrar extends StatefulWidget {
  final DatabaseHelper db;
  const _TabRegistrar({required this.db});

  @override
  State<_TabRegistrar> createState() => _TabRegistrarState();
}

class _TabRegistrarState extends State<_TabRegistrar> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _carreraCtrl = TextEditingController();
  String _rolSeleccionado = 'estudiante';
  bool _cargando = false;
  bool _verContrasena = false;

  List<Profesion> _profesiones = [];
  List<int> _profesionesSeleccionadas = [];

  @override
  void initState() {
    super.initState();
    _cargarProfesiones();
  }

  Future<void> _cargarProfesiones() async {
    final lista = await widget.db.getProfesiones();
    setState(() => _profesiones = lista);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rolSeleccionado == 'docente' && _profesionesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una profesión para el docente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    final exito = await widget.db.registrarUsuario(
      nombre: _nombreCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      contrasena: _contrasenaCtrl.text.trim(),
      rol: _rolSeleccionado,
      matricula: _matriculaCtrl.text.trim(),
      carrera: _rolSeleccionado == 'estudiante' ? _carreraCtrl.text.trim() : null,
      idsProfesiones: _rolSeleccionado == 'docente' ? _profesionesSeleccionadas : null,
    );

    setState(() => _cargando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      _limpiarFormulario();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar. ¿El correo ya existe?'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _limpiarFormulario() {
    _nombreCtrl.clear();
    _correoCtrl.clear();
    _contrasenaCtrl.clear();
    _matriculaCtrl.clear();
    _carreraCtrl.clear();
    setState(() {
      _rolSeleccionado = 'estudiante';
      _profesionesSeleccionadas = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _seccionTitulo('Datos del usuario'),
            const SizedBox(height: 16),

            // Nombre
            _campo(_nombreCtrl, 'Nombre completo', Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 12),

            // Correo
            _campo(_correoCtrl, 'Correo electrónico', Icons.email_outlined,
                tipo: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Campo requerido';
                  if (!v.contains('@')) return 'Correo no válido';
                  return null;
                }),
            const SizedBox(height: 12),

            // Contraseña
            TextFormField(
              controller: _contrasenaCtrl,
              obscureText: !_verContrasena,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_verContrasena ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verContrasena = !_verContrasena),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) {
                if (v!.isEmpty) return 'Campo requerido';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Matrícula
            _campo(_matriculaCtrl, 'Matrícula', Icons.badge_outlined,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 16),

            // Rol
            _seccionTitulo('Rol del usuario'),
            const SizedBox(height: 12),
            _selectorRol(),
            const SizedBox(height: 16),

            // Campos según rol
            if (_rolSeleccionado == 'estudiante') ...[
              _seccionTitulo('Datos del estudiante'),
              const SizedBox(height: 12),
              _campo(_carreraCtrl, 'Carrera', Icons.school_outlined,
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
              const SizedBox(height: 16),
            ],

            if (_rolSeleccionado == 'docente') ...[
              _seccionTitulo('Profesiones del docente'),
              const SizedBox(height: 8),
              _checkboxProfesiones(),
              const SizedBox(height: 16),
            ],

            // Botón registrar
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _registrar,
                icon: _cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add),
                label: Text(_cargando ? 'Registrando...' : 'Registrar Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A237E),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icono, {
    TextInputType tipo = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _selectorRol() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: ['estudiante', 'docente'].map((rol) {
          final seleccionado = _rolSeleccionado == rol;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _rolSeleccionado = rol;
                _profesionesSeleccionadas = [];
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? const Color(0xFF1A237E)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      rol == 'estudiante'
                          ? Icons.person
                          : Icons.school,
                      color: seleccionado ? Colors.white : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rol[0].toUpperCase() + rol.substring(1),
                      style: TextStyle(
                        color: seleccionado ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _checkboxProfesiones() {
    if (_profesiones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No hay profesiones registradas. Ve a la pestaña "Profesiones" para agregar.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _profesiones.map((prof) {
          final seleccionada = _profesionesSeleccionadas.contains(prof.id);
          return CheckboxListTile(
            title: Text(prof.nombre),
            value: seleccionada,
            activeColor: const Color(0xFF1A237E),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _profesionesSeleccionadas.add(prof.id);
                } else {
                  _profesionesSeleccionadas.remove(prof.id);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}

// ── TAB 2: VER USUARIOS ───────────────────────────────────────
class _TabUsuarios extends StatefulWidget {
  final DatabaseHelper db;
  const _TabUsuarios({required this.db});

  @override
  State<_TabUsuarios> createState() => _TabUsuariosState();
}

class _TabUsuariosState extends State<_TabUsuarios> {
  late Future<List<Usuario>> _futureUsuarios;

  @override
  void initState() {
    super.initState();
    _futureUsuarios = widget.db.getUsuarios();
  }

  Color _colorRol(String rol) {
    switch (rol) {
      case 'administrador':
        return Colors.red.shade700;
      case 'docente':
        return Colors.blue.shade700;
      case 'estudiante':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _iconoRol(String rol) {
    switch (rol) {
      case 'administrador':
        return Icons.admin_panel_settings;
      case 'docente':
        return Icons.school;
      case 'estudiante':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>>(
      future: _futureUsuarios,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error al cargar usuarios'));
        }
        final usuarios = snapshot.data!;
        if (usuarios.isEmpty) {
          return const Center(child: Text('No hay usuarios registrados'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: usuarios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final u = usuarios[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colorRol(u.rol).withOpacity(0.15),
                  child: Icon(_iconoRol(u.rol), color: _colorRol(u.rol)),
                ),
                title: Text(u.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(u.correo),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colorRol(u.rol).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    u.rol,
                    style: TextStyle(
                      color: _colorRol(u.rol),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── TAB 3: PROFESIONES ────────────────────────────────────────
class _TabProfesiones extends StatefulWidget {
  final DatabaseHelper db;
  const _TabProfesiones({required this.db});

  @override
  State<_TabProfesiones> createState() => _TabProfesionesState();
}

class _TabProfesionesState extends State<_TabProfesiones> {
  final _ctrl = TextEditingController();
  late Future<List<Profesion>> _futureProfesiones;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _futureProfesiones = widget.db.getProfesiones();
    });
  }

  Future<void> _agregar() async {
    final nombre = _ctrl.text.trim();
    if (nombre.isEmpty) return;

    final exito = await widget.db.agregarProfesion(nombre);
    if (exito) {
      _ctrl.clear();
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profesión agregada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo para agregar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    labelText: 'Nueva profesión',
                    prefixIcon: const Icon(Icons.work_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _agregar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de profesiones
          Expanded(
            child: FutureBuilder<List<Profesion>>(
              future: _futureProfesiones,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = snapshot.data ?? [];
                if (lista.isEmpty) {
                  return const Center(
                    child: Text('No hay profesiones registradas'),
                  );
                }
                return ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = lista[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8EAF6),
                          child: Icon(Icons.work, color: Color(0xFF1A237E)),
                        ),
                        title: Text(p.nombre),
                        subtitle: Text('ID: ${p.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}