import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('impresora.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS contador (
          id INTEGER PRIMARY KEY,
          consecutivos INTEGER DEFAULT 1
        )
      ''');
      final existing = await db.query(
        'contador',
        where: 'id = ?',
        whereArgs: [1],
      );
      if (existing.isEmpty) {
        await db.insert('contador', {'id': 1, 'consecutivos': 1});
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE facturas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero_consecutivo INTEGER NOT NULL,
        codigo_unico TEXT NOT NULL,
        cliente TEXT NOT NULL,
        telefono TEXT,
        direccion TEXT,
        items TEXT NOT NULL,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        fecha_entrega TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE negocio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        logo BLOB,
        nombre TEXT NOT NULL,
        nit TEXT,
        direccion TEXT,
        ciudad TEXT,
        codigo_postal TEXT,
        correo TEXT,
        telefono1 TEXT,
        telefono2 TEXT,
        sitio_web TEXT,
        facebook TEXT,
        instagram TEXT,
        whatsapp TEXT,
        mensaje_pie TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE contador (
        id INTEGER PRIMARY KEY,
        consecutivos INTEGER DEFAULT 1
      )
    ''');

    await db.insert('contador', {'id': 1, 'consecutivos': 1});
  }

  Future<int> getSiguienteConsecutivo() async {
    final db = await database;
    final result = await db.query('contador', where: 'id = ?', whereArgs: [1]);
    return result.first['consecutivos'] as int;
  }

  Future<int> getSiguienteCodigoUnico() async {
    final db = await database;
    final result = await db.query('contador', where: 'id = ?', whereArgs: [1]);
    return result.first['consecutivos'] as int;
  }

  Future<void> incrementarContador() async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE contador SET consecutivos = consecutivos + 1 WHERE id = 1',
    );
  }

  // Facturas CRUD
  Future<int> insertFactura(Map<String, dynamic> factura) async {
    final db = await database;
    final data = {
      'numero_consecutivo': factura['numero_consecutivo'],
      'codigo_unico': factura['codigo_unico'],
      'cliente': factura['cliente'],
      'telefono': factura['telefono'] ?? '',
      'direccion': factura['direccion'] ?? '',
      'items': jsonEncode(factura['items']),
      'total': factura['total'],
      'fecha': factura['fecha'].toString(),
      'fecha_entrega': factura['fecha_entrega'] ?? '',
    };
    await db.insert('facturas', data);
    await incrementarContador();
    return 1;
  }

  Future<List<Map<String, dynamic>>> getFacturas() async {
    final db = await database;
    final results = await db.query('facturas', orderBy: 'id DESC');
    return results.map((row) {
      return {
        'id': row['id'],
        'numero_consecutivo': row['numero_consecutivo'],
        'codigo_unico': row['codigo_unico'],
        'cliente': row['cliente'],
        'telefono': row['telefono'],
        'direccion': row['direccion'],
        'items': jsonDecode(row['items'] as String),
        'total': row['total'],
        'fecha': DateTime.parse(row['fecha'] as String),
        'fecha_entrega': row['fecha_entrega'],
      };
    }).toList();
  }

  Future<int> updateFactura(int id, Map<String, dynamic> factura) async {
    final db = await database;
    final data = {
      'cliente': factura['cliente'],
      'telefono': factura['telefono'] ?? '',
      'direccion': factura['direccion'] ?? '',
      'items': jsonEncode(factura['items']),
      'total': factura['total'],
      'fecha_entrega': factura['fecha_entrega'] ?? '',
    };
    return await db.update('facturas', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteFactura(int id) async {
    final db = await database;
    return await db.delete('facturas', where: 'id = ?', whereArgs: [id]);
  }

  // Negocio CRUD
  Future<int> saveNegocio(Map<String, dynamic> negocio) async {
    final db = await database;
    final existing = await db.query('negocio', limit: 1);

    final data = {
      'logo': negocio['logo'],
      'nombre': negocio['nombre'] ?? '',
      'nit': negocio['nit'] ?? '',
      'direccion': negocio['direccion'] ?? '',
      'ciudad': negocio['ciudad'] ?? '',
      'codigo_postal': negocio['codigo_postal'] ?? '',
      'correo': negocio['correo'] ?? '',
      'telefono1': negocio['telefono1'] ?? '',
      'telefono2': negocio['telefono2'] ?? '',
      'sitio_web': negocio['sitio_web'] ?? '',
      'facebook': negocio['facebook'] ?? '',
      'instagram': negocio['instagram'] ?? '',
      'whatsapp': negocio['whatsapp'] ?? '',
      'mensaje_pie': negocio['mensaje_pie'] ?? '',
    };

    if (existing.isEmpty) {
      return await db.insert('negocio', data);
    } else {
      return await db.update(
        'negocio',
        data,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<Map<String, dynamic>?> getNegocio() async {
    final db = await database;
    final results = await db.query('negocio', limit: 1);
    if (results.isEmpty) return null;

    final row = results.first;
    return {
      'logo': row['logo'],
      'nombre': row['nombre'],
      'nit': row['nit'],
      'direccion': row['direccion'],
      'ciudad': row['ciudad'],
      'codigo_postal': row['codigo_postal'],
      'correo': row['correo'],
      'telefono1': row['telefono1'],
      'telefono2': row['telefono2'],
      'sitio_web': row['sitio_web'],
      'facebook': row['facebook'],
      'instagram': row['instagram'],
      'whatsapp': row['whatsapp'],
      'mensaje_pie': row['mensaje_pie'],
    };
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
