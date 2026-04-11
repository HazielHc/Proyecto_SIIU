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
    _tabController = TabController(length: 5, vsync: this);
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Registrar'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.work), text: 'Profesiones'),
            Tab(icon: Icon(Icons.menu_book), text: 'Materias'),
            Tab(icon: Icon(Icons.school_outlined), text: 'Carreras'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabRegistrar(db: _db),
          _TabUsuarios(db: _db),
          _TabProfesiones(db: _db),
          _TabMaterias(db: _db),
          _TabCarreras(db: _db),
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
  String _rolSeleccionado = 'estudiante';
  bool _cargando = false;
  bool _verContrasena = false;

  List<Profesion> _profesiones = [];
  List<int> _profesionesSeleccionadas = [];
  List<Carrera> _carreras = [];
  Carrera? _carreraSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarProfesiones();
    _cargarCarreras();
  }

  Future<void> _cargarProfesiones() async {
    final lista = await widget.db.getProfesiones();
    setState(() => _profesiones = lista);
  }

  Future<void> _cargarCarreras() async {
    final lista = await widget.db.getCarreras();
    setState(() => _carreras = lista);
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

    if (_rolSeleccionado == 'estudiante' && _carreraSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una carrera'),
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
      carrera: _rolSeleccionado == 'estudiante'
          ? _carreraSeleccionada?.nombre
          : null,
      idsProfesiones:
          _rolSeleccionado == 'docente' ? _profesionesSeleccionadas : null,
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
    setState(() {
      _rolSeleccionado = 'estudiante';
      _profesionesSeleccionadas = [];
      _carreraSeleccionada = null;
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

            _campo(_nombreCtrl, 'Nombre completo', Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 12),

            _campo(_correoCtrl, 'Correo electrónico', Icons.email_outlined,
                tipo: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Campo requerido';
                  if (!v.contains('@')) return 'Correo no válido';
                  return null;
                }),
            const SizedBox(height: 12),

            TextFormField(
              controller: _contrasenaCtrl,
              obscureText: !_verContrasena,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _verContrasena ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _verContrasena = !_verContrasena),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

            _campo(_matriculaCtrl, 'Matrícula', Icons.badge_outlined,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 16),

            _seccionTitulo('Rol del usuario'),
            const SizedBox(height: 12),
            _selectorRol(),
            const SizedBox(height: 16),

            if (_rolSeleccionado == 'estudiante') ...[
              _seccionTitulo('Datos del estudiante'),
              const SizedBox(height: 12),
              _carreras.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No hay carreras registradas. Ve a la pestaña "Carreras" para agregar.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ]),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Carrera>(
                          isExpanded: true,
                          hint: const Text('Selecciona una carrera'),
                          value: _carreraSeleccionada,
                          items: _carreras
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.nombre),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _carreraSeleccionada = val),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
            ],

            if (_rolSeleccionado == 'docente') ...[
              _seccionTitulo('Profesiones del docente'),
              const SizedBox(height: 8),
              _checkboxProfesiones(),
              const SizedBox(height: 16),
            ],

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
                _carreraSeleccionada = null;
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
                      rol == 'estudiante' ? Icons.person : Icons.school,
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

// ── TAB 4: MATERIAS ───────────────────────────────────────────
class _TabMaterias extends StatefulWidget {
  final DatabaseHelper db;
  const _TabMaterias({required this.db});

  @override
  State<_TabMaterias> createState() => _TabMateriasState();
}

class _TabMateriasState extends State<_TabMaterias> {
  late Future<List<MateriaItem>> _futureMaterias;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _futureMaterias = widget.db.getMaterias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final creada = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => _FormMateria(db: widget.db)),
          );
          if (creada == true) _recargar();
        },
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Nueva Materia', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<MateriaItem>>(
        future: _futureMaterias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final materias = snapshot.data ?? [];
          if (materias.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No hay materias registradas',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('Presiona + para crear una',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: materias.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final m = materias[index];
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
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EAF6),
                    child: Icon(Icons.menu_book, color: Color(0xFF1A237E)),
                  ),
                  title: Text(m.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                      Text('Clave: ${m.clave}  •  Docente: ${m.nombreDocente}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── TAB 5: CARRERAS ───────────────────────────────────────────
class _TabCarreras extends StatefulWidget {
  final DatabaseHelper db;
  const _TabCarreras({required this.db});

  @override
  State<_TabCarreras> createState() => _TabCarrerasState();
}

class _TabCarrerasState extends State<_TabCarreras> {
  final _ctrl = TextEditingController();
  late Future<List<Carrera>> _futureCarreras;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _futureCarreras = widget.db.getCarreras();
    });
  }

  Future<void> _agregar() async {
    final nombre = _ctrl.text.trim();
    if (nombre.isEmpty) return;
    final exito = await widget.db.agregarCarrera(nombre);
    if (exito) {
      _ctrl.clear();
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carrera agregada'),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    labelText: 'Nueva carrera',
                    prefixIcon: const Icon(Icons.school_outlined),
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
          Expanded(
            child: FutureBuilder<List<Carrera>>(
              future: _futureCarreras,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lista = snapshot.data ?? [];
                if (lista.isEmpty) {
                  return const Center(
                    child: Text('No hay carreras registradas'),
                  );
                }
                return ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = lista[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8EAF6),
                          child:
                              Icon(Icons.school, color: Color(0xFF1A237E)),
                        ),
                        title: Text(c.nombre),
                        subtitle: Text('ID: ${c.id}'),
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

// ── FORMULARIO NUEVA MATERIA ──────────────────────────────────
class _FormMateria extends StatefulWidget {
  final DatabaseHelper db;
  const _FormMateria({required this.db});

  @override
  State<_FormMateria> createState() => _FormMateriaState();
}

class _FormMateriaState extends State<_FormMateria> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();

  List<DocenteItem> _docentes = [];
  List<EstudianteItem> _estudiantes = [];
  DocenteItem? _docenteSeleccionado;
  List<int> _estudiantesSeleccionados = [];
  bool _cargando = false;
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final docentes = await widget.db.getDocentes();
    final estudiantes = await widget.db.getEstudiantes();
    setState(() {
      _docentes = docentes;
      _estudiantes = estudiantes;
      _cargandoDatos = false;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_docenteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona un docente'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_estudiantesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona al menos un estudiante'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _cargando = true);
    final exito = await widget.db.crearMateria(
      nombre: _nombreCtrl.text.trim(),
      clave: _claveCtrl.text.trim(),
      idDocente: _docenteSeleccionado!.id,
      idsEstudiantes: _estudiantesSeleccionados,
    );
    setState(() => _cargando = false);
    if (exito) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error. ¿La clave ya existe?'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Nueva Materia'),
      ),
      body: _cargandoDatos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _seccion('Datos de la materia'),
                    const SizedBox(height: 12),
                    _campo(_nombreCtrl, 'Nombre de la materia',
                        Icons.menu_book_outlined,
                        validator: (v) =>
                            v!.isEmpty ? 'Campo requerido' : null),
                    const SizedBox(height: 12),
                    _campo(_claveCtrl, 'Clave (única)', Icons.tag,
                        validator: (v) =>
                            v!.isEmpty ? 'Campo requerido' : null),
                    const SizedBox(height: 20),

                    _seccion('Docente asignado'),
                    const SizedBox(height: 12),
                    _docentes.isEmpty
                        ? _aviso('No hay docentes. Regístralos primero.')
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<DocenteItem>(
                                isExpanded: true,
                                hint: const Text('Selecciona un docente'),
                                value: _docenteSeleccionado,
                                items: _docentes
                                    .map((d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(
                                              '${d.nombre} (${d.matricula})'),
                                        ))
                                    .toList(),
                                onChanged: (val) => setState(
                                    () => _docenteSeleccionado = val),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),

                    _seccion('Estudiantes inscritos'),
                    const SizedBox(height: 8),
                    _estudiantes.isEmpty
                        ? _aviso('No hay estudiantes. Regístralos primero.')
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: _estudiantes.map((est) {
                                final sel =
                                    _estudiantesSeleccionados.contains(est.id);
                                return CheckboxListTile(
                                  title: Text(est.nombre),
                                  subtitle: Text(
                                      '${est.matricula} • ${est.carrera}'),
                                  value: sel,
                                  activeColor: const Color(0xFF1A237E),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _estudiantesSeleccionados.add(est.id);
                                      } else {
                                        _estudiantesSeleccionados
                                            .remove(est.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _cargando ? null : _guardar,
                        icon: _cargando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label:
                            Text(_cargando ? 'Guardando...' : 'Crear Materia'),
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
            ),
    );
  }

  Widget _seccion(String titulo) => Text(titulo,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A237E)));

  Widget _aviso(String msg) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(msg, style: const TextStyle(color: Colors.orange))),
        ]),
      );

  Widget _campo(TextEditingController ctrl, String label, IconData icono,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
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
}
