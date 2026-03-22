// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'admin_screen.dart';
import 'docente_screen.dart';
import 'estudiante_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _cargando = false;
  bool _verContrasena = false;
  final DatabaseHelper _db = DatabaseHelper();

  @override
  void dispose() {
    _correoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final usuario = await _db.login(
      _correoCtrl.text.trim(),
      _contrasenaCtrl.text.trim(),
    );

    setState(() => _cargando = false);

    if (usuario == null) {
      // Credenciales incorrectas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo o contraseña incorrectos'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Redirigir según el rol
    Widget pantalla;
    switch (usuario.rol) {
      case 'administrador':
        pantalla = AdminScreen(usuario: usuario);
        break;
      case 'docente':
        pantalla = DocenteScreen(usuario: usuario);
        break;
      case 'estudiante':
        pantalla = EstudianteScreen(usuario: usuario);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rol no reconocido')),
        );
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // azul oscuro
              Color(0xFF283593),
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / ícono
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  'SIIU',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  'Sistema Integral de Información\nUniversitaria',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),

                // Tarjeta translúcida
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Campo correo
                        TextFormField(
                          controller: _correoCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Correo electrónico',
                            Icons.email_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu correo';
                            if (!v.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo contraseña
                        TextFormField(
                          controller: _contrasenaCtrl,
                          obscureText: !_verContrasena,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Contraseña',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _verContrasena
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white60,
                              ),
                              onPressed: () =>
                                  setState(() => _verContrasena = !_verContrasena),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Botón ingresar
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A237E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF1A237E),
                                    ),
                                  )
                                : const Text(
                                    'Ingresar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icono) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icono, color: Colors.white60),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
    );
  }
}