import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'paginaBienvenida.dart'; // Importa la página a la que deseas redirigir al cerrar sesión

class PantallaCerrarSesion extends StatelessWidget {
  const PantallaCerrarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerrar Sesión'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Estás seguro de que deseas cerrar sesión?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Cerrar sesión en Firebase
                await FirebaseAuth.instance.signOut();

                // Cerrar sesión en Google
                GoogleSignIn googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();

                // Navegar a la pantalla de bienvenida
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InicioPrincipal()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
