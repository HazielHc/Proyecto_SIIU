// lib/main.dart
import 'package:flutter/material.dart';
import 'database_helper.dart'; // Importa el helper y el modelo Usuario
 
void main() {
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conexión MySQL Local',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UsuariosScreen(), // La pantalla principal ahora es UsuariosScreen
    );
  }
}
 
// StatefulWidget porque su estado puede cambiar (cuando llegan los datos)
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
 
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}
 
class _UsuariosScreenState extends State<UsuariosScreen> {
  // Instancia del helper para poder llamar a getUsuarios()
  final DatabaseHelper _dbHelper = DatabaseHelper();
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios desde MySQL'),
      ),
 
      // FutureBuilder espera a que getUsuarios() termine y luego construye la UI
      body: FutureBuilder<List<Usuario>>(
        future: _dbHelper.getUsuarios(), // La consulta asíncrona
        builder: (context, snapshot) {
 
          // Estado 1: todavía esperando respuesta → mostrar spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
 
          // Estado 2: hubo un error en la conexión o consulta
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
 
          // Estado 3: llegaron los datos pero la tabla está vacía
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay usuarios en la base de datos'));
          }
 
          // Estado 4: todo bien, tenemos datos → dibujar la lista
          final usuarios = snapshot.data!;
 
          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return ListTile(
                leading: CircleAvatar(child: Text(usuario.id.toString())),
                title: Text(usuario.nombre),
                subtitle: Text(usuario.email),
              );
            },
          );
        },
      ),
    );
  }
}
 