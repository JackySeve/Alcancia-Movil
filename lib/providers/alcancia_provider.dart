// ignore_for_file: avoid_print, deprecated_member_use, avoid_function_literals_in_foreach_calls

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../views/metas.dart';

class Moneda {
  final int valor;
  int cantidad;

  Moneda(this.valor, {this.cantidad = 0});

  int get total => valor * cantidad;

  Map<String, dynamic> toMap() {
    return {
      'valor': valor,
      'cantidad': cantidad,
    };
  }

  Moneda.fromMap(Map<String, dynamic> map)
      : valor = map['valor'],
        cantidad = map['cantidad'];
}

class Billete {
  final int valor;
  int cantidad;

  Billete(this.valor, {this.cantidad = 0});

  int get total => valor * cantidad;

  Map<String, dynamic> toMap() {
    return {
      'valor': valor,
      'cantidad': cantidad,
    };
  }

  Billete.fromMap(Map<String, dynamic> map)
      : valor = map['valor'],
        cantidad = map['cantidad'];
}

class AlcanciaProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _userId;
  String? _userEmail;
  String? _userName;

  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  set userId(String? value) {
    _userId = value;
    notifyListeners();
  }

  set userEmail(String? value) {
    _userEmail = value;
    notifyListeners();
  }

  set userName(String? value) {
    _userName = value;
    notifyListeners();
  }

  User? _user;

  User? get user => _user;

  List<Transaccion> _transacciones = [];

  List<Transaccion> get transacciones => _transacciones;

  List<Moneda> _monedas = [
    Moneda(50),
    Moneda(100),
    Moneda(200),
    Moneda(500),
    Moneda(1000),
  ];

  List<Billete> _billetes = [
    Billete(1000),
    Billete(2000),
    Billete(5000),
    Billete(10000),
    Billete(20000),
    Billete(50000),
    Billete(100000),
  ];

  List<Moneda> get monedas => _monedas;
  List<Billete> get billetes => _billetes;

  double _montoTotalAhorrado = 0.0;

  double get montoTotalAhorrado => _montoTotalAhorrado;

  void actualizarCantidadMoneda(int index, int cantidad, String email) {
    if (index >= 0 && index < _monedas.length) {
      _monedas[index].cantidad = cantidad < 0 ? 0 : cantidad;
      notifyListeners();
      actualizarValoresAhorradosMetas(email);
    } else {
      print('Índice de moneda fuera de rango');
    }
  }

  void actualizarCantidadBillete(int index, int cantidad, String email) {
    if (index >= 0 && index < _billetes.length) {
      _billetes[index].cantidad = cantidad < 0 ? 0 : cantidad;
      notifyListeners();
      actualizarValoresAhorradosMetas(email);
    } else {
      print('Índice de billete fuera de rango');
    }
  }

  int get totalAhorrado {
    int total = 0;
    for (var moneda in _monedas) {
      total += moneda.total;
    }
    for (var billete in _billetes) {
      total += billete.total;
    }
    return total;
  }

  int get totalAhorradoMonedas {
    int total = 0;
    for (var moneda in _monedas) {
      total += moneda.total;
    }
    return total;
  }

  int get totalAhorradoBilletes {
    int total = 0;
    for (var billete in _billetes) {
      total += billete.total;
    }
    return total;
  }

  Future<void> agregarTransaccion(
      double monto, bool esIngreso, String email) async {
    if (esIngreso) {
      _montoTotalAhorrado += monto;
    } else {
      if (_montoTotalAhorrado >= monto) {
        _montoTotalAhorrado -= monto;
      } else {
        print("No hay suficiente dinero ahorrado para retirar $monto");
        return;
      }
    }
    Transaccion transaccion = Transaccion(monto, esIngreso, DateTime.now());
    _transacciones.add(transaccion);
    await guardarTransaccionEnFirestore(transaccion, email);
    notifyListeners();
  }

  Future<void> guardarTransaccionEnFirestore(
      Transaccion transaccion, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('usuarios')
          .doc(email)
          .collection('transacciones')
          .add(transaccion.toMap());
    } catch (e) {
      print(e);
    }
  }

  double calcularMedia() {
    double total = 0;
    int count = 0;
    for (var moneda in _monedas) {
      total += moneda.valor * moneda.cantidad;
      count += moneda.cantidad;
    }
    for (var billete in _billetes) {
      total += billete.valor * billete.cantidad;
      count += billete.cantidad;
    }
    return total / count;
  }

  double calcularMediana() {
    List<double> valores = [];
    for (var moneda in _monedas) {
      for (int i = 0; i < moneda.cantidad; i++) {
        valores.add(moneda.valor.toDouble());
      }
    }
    for (var billete in _billetes) {
      for (int i = 0; i < billete.cantidad; i++) {
        valores.add(billete.valor.toDouble());
      }
    }
    valores.sort();
    int n = valores.length;
    if (n == 0) {
      return 0.0;
    } else if (n % 2 == 0) {
      return (valores[n ~/ 2 - 1] + valores[n ~/ 2]) / 2;
    } else {
      return valores[n ~/ 2];
    }
  }

  double calcularModa() {
    Map<double, int> frecuencias = {};
    for (var moneda in _monedas) {
      frecuencias[moneda.valor.toDouble()] =
          (frecuencias[moneda.valor.toDouble()] ?? 0) + moneda.cantidad;
    }
    for (var billete in _billetes) {
      frecuencias[billete.valor.toDouble()] =
          (frecuencias[billete.valor.toDouble()] ?? 0) + billete.cantidad;
    }
    double moda = 0;
    int maxFrecuencia = 0;
    frecuencias.forEach((valor, frecuencia) {
      if (frecuencia > maxFrecuencia) {
        maxFrecuencia = frecuencia;
        moda = valor;
      }
    });
    return moda;
  }

  double calcularDesviacionEstandar() {
    double media = calcularMedia();
    double suma = 0;
    int count = 0;
    for (var moneda in _monedas) {
      suma += pow(moneda.valor - media, 2) * moneda.cantidad;
      count += moneda.cantidad;
    }
    for (var billete in _billetes) {
      suma += pow(billete.valor - media, 2) * billete.cantidad;
      count += billete.cantidad;
    }
    return sqrt(suma / count);
  }

  double calcularRangoIntercuartil() {
    List<double> valores = [];
    for (var moneda in _monedas) {
      for (int i = 0; i < moneda.cantidad; i++) {
        valores.add(moneda.valor.toDouble());
      }
    }
    for (var billete in _billetes) {
      for (int i = 0; i < billete.cantidad; i++) {
        valores.add(billete.valor.toDouble());
      }
    }
    valores.sort();
    int n = valores.length;
    if (n == 0) {
      return 0.0;
    } else {
      int q1 = (n + 1) ~/ 4;
      int q3 = 3 * (n + 1) ~/ 4;
      return valores[q3 - 1] - valores[q1 - 1];
    }
  }

  double calcularCoeficienteVariacion() {
    double media = calcularMedia();
    double desviacionEstandar = calcularDesviacionEstandar();
    return desviacionEstandar / media;
  }

  List<Meta> _metas = [];

  List<Meta> get metas => _metas;

  void agregarMeta(Meta meta) {
    _metas.add(meta);
    notifyListeners();
    _guardarMetaEnFirebase(meta);
  }

  void crearMeta(
      String nombre, double valorObjetivo, DateTime fechaLimite) async {
    await FirebaseFirestore.instance.collection('metas').add({
      'nombre': nombre,
      'valorObjetivo': valorObjetivo,
      'fechaLimite': fechaLimite,
      'cumplida': false,
    });
  }

  Future<void> verificarFechaMetas() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('metas').get();

    querySnapshot.docs.forEach((doc) async {
      DateTime fechaLimite =
          DateTime.fromMillisecondsSinceEpoch(doc['fechaLimite']);
      if (DateTime.now().isAfter(fechaLimite)) {
        await FirebaseFirestore.instance
            .collection('metas')
            .doc(doc.id)
            .update({
          'cumplida': true,
        });
      }
    });
  }

  Future<void> _guardarMetaEnFirebase(Meta meta) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('metas').doc(meta.id).set({
        'nombre': meta.nombre,
        'valorObjetivo': meta.valorObjetivo,
        'fechaLimite': meta.fechaLimite.millisecondsSinceEpoch,
        'cumplida': meta.cumplida,
      });
      print('Meta actualizada en Firebase');
    } catch (e) {
      print('Error al actualizar meta en Firebase: $e');
    }
  }

  void editarMeta(Meta meta) async {
    try {
      final metaDocument =
          FirebaseFirestore.instance.collection('metas').doc(meta.id);
      await metaDocument.update({
        'nombre': meta.nombre,
        'valorObjetivo': meta.valorObjetivo,
        'fechaLimite': meta.fechaLimite.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error editing meta: $e');
    }
  }

  void eliminarMeta(String id) {
    _metas.removeWhere((meta) => meta.id == id);
    notifyListeners();
    if (userEmail != null) {
      eliminarMetaEnFirebase(id, userEmail!);
    } else {
      print("Error: userEmail is null. Cannot save metas to Firebase.");
    }
  }

  void actualizarValoresAhorradosMetas(String email) async {
    int totalAhorrado = this.totalAhorrado;
    for (var meta in _metas) {
      if (totalAhorrado >= meta.valorObjetivo) {
        meta.valorAhorrado = meta.valorObjetivo;
        meta.cumplida = true;
      } else {
        meta.valorAhorrado = totalAhorrado;
        meta.cumplida = false;
      }
    }
    notifyListeners();
    await guardarMetasEnFirebase(_metas, email);
  }

  void verificarMetasCumplidas() {
    final DateTime ahora = DateTime.now();
    for (var meta in _metas) {
      if (ahora.isAfter(meta.fechaLimite)) {
        if (meta.valorAhorrado >= meta.valorObjetivo) {
          meta.cumplida = true;
        } else {
          meta.cumplida = false;
        }
      }
    }
    notifyListeners();
  }

  Map<String, int> obtenerMetasCumplidasEIncumplidas() {
    int metasCumplidas = 0;
    int metasIncumplidas = 0;

    for (var meta in _metas) {
      if (meta.cumplida) {
        metasCumplidas++;
      } else {
        metasIncumplidas++;
      }
    }

    return {
      'metasCumplidas': metasCumplidas,
      'metasIncumplidas': metasIncumplidas,
    };
  }

  Future<void> guardarDatosEnFirebase(List<Moneda> monedas,
      List<Billete> billetes, double totalAhorrado, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final datosAlcancia = {
        'monedas': monedas.map((moneda) => moneda.toMap()).toList(),
        'billetes': billetes.map((billete) => billete.toMap()).toList(),
        'totalAhorrado': totalAhorrado,
      };

      await firestore
          .collection('usuarios')
          .doc(email)
          .collection('alcancia')
          .doc('datos')
          .set(datosAlcancia);
    } catch (e) {
      print('Error al guardar datos en Firebase: $e');
    }
  }

  Future<void> cargarDatosDesdeFirebase(String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docSnapshot = await firestore
          .collection('usuarios')
          .doc(email)
          .collection('alcancia')
          .doc('datos')
          .get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        _monedas = (data?['monedas'] as List<dynamic>?)
                ?.map((monedaMap) => Moneda.fromMap(monedaMap))
                .toList() ??
            [];
        _billetes = (data?['billetes'] as List<dynamic>?)
                ?.map((billeteMap) => Billete.fromMap(billeteMap))
                .toList() ??
            [];
        _montoTotalAhorrado = data?['totalAhorrado']?.toDouble() ?? 0.0;
        notifyListeners();
        print('Datos cargados desde Firebase');
      } else {
        print('No se encontraron datos en Firebase');
      }
    } catch (e) {
      print('Error al cargar datos desde Firebase: $e');
    }
  }

  Future<void> guardarTransaccionesEnFirebase(
      List<Transaccion> transacciones, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final transaccionesRef = firestore
          .collection('usuarios')
          .doc(email)
          .collection('transacciones');

      final snapshot = await transaccionesRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      transacciones.sort((a, b) => a.fecha.compareTo(b.fecha));

      for (var transaccion in transacciones) {
        await transaccionesRef.add(transaccion.toMap());
      }
    } catch (e) {
      print('Error al guardar transacciones en Firebase: $e');
    }
  }

  Future<void> cargarTransaccionesDesdeFirebase(String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final transaccionesRef = firestore
          .collection('usuarios')
          .doc(email)
          .collection('transacciones');
      final snapshot = await transaccionesRef.get();
      final transacciones =
          snapshot.docs.map((doc) => Transaccion.fromMap(doc.data())).toList();
      _transacciones = transacciones;
      notifyListeners();
    } catch (e) {
      print('Error al cargar transacciones desde Firebase: $e');
    }
  }

  Future<void> guardarMetasEnFirebase(List<Meta> metas, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final metasRef =
          firestore.collection('usuarios').doc(email).collection('metas');

      for (var meta in metas) {
        if (meta.id == null) {
          final docRef = await metasRef.add(meta.toMap());
          meta.id = docRef.id; // Asignar el ID generado por Firestore
        } else {
          await metasRef
              .doc(meta.id)
              .set(meta.toMap(), SetOptions(merge: true));
        }
      }
    } catch (e) {
      print('Error al guardar metas en Firebase: $e');
    }
  }

  Future<void> cargarMetasDesdeFirebase(String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final metasRef =
          firestore.collection('usuarios').doc(email).collection('metas');
      final metaSnapshot = await metasRef.get();

      _metas = metaSnapshot.docs
          .map((doc) {
            final meta = Meta.fromMap(doc.data());
            meta.id = doc.id; // Asignar el ID del documento a la meta
            return meta;
          })
          .where((meta) => meta != null)
          .toList();

      notifyListeners();
    } catch (error) {
      if (error is FirebaseException) {
        print('Error cargando metas desde Firebase: ${error.message}');
      } else {
        print('Error cargando metas: $error');
      }
    }
  }

  Future<void> eliminarMetaEnFirebase(String idMeta, String userEmail) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final metaRef = firestore
          .collection('usuarios')
          .doc(userEmail)
          .collection('metas')
          .doc(idMeta);

      await metaRef.delete();
      print('Meta deleted from Firebase');
    } catch (e) {
      print('Error al eliminar meta en Firebase: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    _user = userCredential.user;
    notifyListeners();

    return userCredential;
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser(
      String username, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      // Inicializar los valores de monedas y billetes a cero en Firestore
      await _firestore.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'monedas': 0,
        'billetes': 0,
      });

      return userId;
    } catch (error) {
      print("Error al registrar usuario: $error");
      return null;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        return user;
      } else {
        print('Error: el objeto user es nulo');
        return null;
      }
    } catch (error) {
      print('Error al iniciar sesión: $error');
      return null;
    }
  }

  Future<void> loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await cargarDatosDesdeFirebase(userEmail!);
        await cargarMetasDesdeFirebase(userEmail!);
        await cargarTransaccionesDesdeFirebase(userEmail!);
      }
    } catch (error) {
      print('Error al cargar los datos del usuario: $error');
    }
  }
}

class Transaccion {
  final double monto;
  final bool esIngreso;
  final DateTime fecha;

  Transaccion(this.monto, this.esIngreso, this.fecha);

  Map<String, dynamic> toMap() {
    return {
      'monto': monto,
      'esIngreso': esIngreso,
      'fecha': fecha.millisecondsSinceEpoch,
    };
  }

  factory Transaccion.fromMap(Map<String, dynamic> map) {
    return Transaccion(
      map['monto'],
      map['esIngreso'],
      DateTime.fromMillisecondsSinceEpoch(map['fecha']),
    );
  }
}
