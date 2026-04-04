import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:image/image.dart' as img;

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
      version: 8,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clientes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          email TEXT,
          telefono TEXT,
          documento TEXT,
          info_adicional TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS productos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          precio REAL NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      if (!await _columnExists(db, 'facturas', 'info_adicional')) {
        await db.execute('ALTER TABLE facturas ADD COLUMN info_adicional TEXT');
      }
      if (!await _columnExists(db, 'clientes', 'info_adicional')) {
        await db.execute('ALTER TABLE clientes ADD COLUMN info_adicional TEXT');
      }
      if (!await _columnExists(db, 'facturas', 'email')) {
        await db.execute('ALTER TABLE facturas ADD COLUMN email TEXT');
      }
      if (!await _columnExists(db, 'facturas', 'documento')) {
        await db.execute('ALTER TABLE facturas ADD COLUMN documento TEXT');
      }
      if (!await _columnExists(db, 'facturas', 'cliente_id')) {
        await db.execute('ALTER TABLE facturas ADD COLUMN cliente_id INTEGER');
      }
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS productos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          precio REAL NOT NULL
        )
      ''');
    }
    if (oldVersion < 8) {
      if (await _columnExists(db, 'facturas', 'direccion')) {
        try {
          await db.execute('ALTER TABLE facturas DROP COLUMN direccion');
        } catch (e) {
          await db.execute('''
            CREATE TABLE facturas_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              numero_consecutivo INTEGER NOT NULL,
              codigo_unico TEXT NOT NULL,
              cliente_id INTEGER,
              cliente TEXT NOT NULL,
              telefono TEXT,
              email TEXT,
              documento TEXT,
              info_adicional TEXT,
              items TEXT NOT NULL,
              total REAL NOT NULL,
              abono REAL DEFAULT 0,
              saldo REAL DEFAULT 0,
              fecha TEXT NOT NULL,
              estado TEXT NOT NULL DEFAULT 'Abierto',
              atendido_por TEXT,
              modelo TEXT,
              serie TEXT,
              estado_actual TEXT,
              FOREIGN KEY (cliente_id) REFERENCES clientes (id)
            )
          ''');
          await db.execute('''
            INSERT INTO facturas_new (id, numero_consecutivo, codigo_unico, cliente_id, cliente, telefono, email, documento, info_adicional, items, total, abono, saldo, fecha, estado, atendido_por, modelo, serie, estado_actual)
            SELECT id, numero_consecutivo, codigo_unico, cliente_id, cliente, telefono, email, documento, info_adicional, items, total, abono, saldo, fecha, estado, atendido_por, modelo, serie, estado_actual FROM facturas
          ''');
          await db.execute('DROP TABLE facturas');
          await db.execute('ALTER TABLE facturas_new RENAME TO facturas');
        }
      }
    }
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    try {
      final result = await db.rawQuery('PRAGMA table_info($table)');
      return result.any((row) => row['name'] == column);
    } catch (e) {
      return false;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT,
        telefono TEXT,
        documento TEXT,
        info_adicional TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE facturas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero_consecutivo INTEGER NOT NULL,
        codigo_unico TEXT NOT NULL,
        cliente_id INTEGER,
        cliente TEXT NOT NULL,
        telefono TEXT,
        email TEXT,
        documento TEXT,
        info_adicional TEXT,
        items TEXT NOT NULL,
        total REAL NOT NULL,
        abono REAL DEFAULT 0,
        saldo REAL DEFAULT 0,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'Abierto',
        atendido_por TEXT,
        modelo TEXT,
        serie TEXT,
        estado_actual TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
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
    if (result.isEmpty) {
      await db.insert('contador', {'id': 1, 'consecutivos': 1});
      return 1;
    }
    return result.first['consecutivos'] as int;
  }

  Future<void> incrementarContador() async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE contador SET consecutivos = consecutivos + 1 WHERE id = 1',
    );
  }

  Future<int> insertFactura(Map<String, dynamic> factura) async {
    final db = await database;
    final data = {
      'numero_consecutivo': factura['numero_consecutivo'],
      'codigo_unico': factura['codigo_unico'],
      'cliente_id': factura['cliente_id'],
      'cliente': factura['cliente'],
      'telefono': factura['telefono'] ?? '',
      'email': factura['email'] ?? '',
      'documento': factura['documento'] ?? '',
      'info_adicional': factura['info_adicional'] ?? '',
      'items': jsonEncode(factura['items']),
      'total': factura['total'],
      'abono': factura['abono'] ?? 0,
      'saldo': factura['saldo'] ?? 0,
      'fecha': factura['fecha'].toString(),
      'estado': factura['estado'] ?? 'Abierto',
      'atendido_por': factura['atendido_por'] ?? '',
      'modelo': factura['modelo'] ?? '',
      'serie': factura['serie'] ?? '',
      'estado_actual': factura['estado_actual'] ?? '',
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
        'cliente_id': row['cliente_id'],
        'cliente': row['cliente'],
        'telefono': row['telefono'],
        'email': row['email'],
        'documento': row['documento'],
        'info_adicional': row['info_adicional'],
        'items': jsonDecode(row['items'] as String),
        'total': row['total'],
        'abono': row['abono'] ?? 0,
        'saldo': row['saldo'] ?? 0,
        'fecha': DateTime.parse(row['fecha'] as String),
        'estado': row['estado'] ?? 'Abierto',
        'atendido_por': row['atendido_por'] ?? '',
        'modelo': row['modelo'] ?? '',
        'serie': row['serie'] ?? '',
        'estado_actual': row['estado_actual'] ?? '',
      };
    }).toList();
  }

  Future<int> updateFactura(int id, Map<String, dynamic> factura) async {
    final db = await database;
    final data = {
      'cliente': factura['cliente'],
      'telefono': factura['telefono'] ?? '',
      'email': factura['email'] ?? '',
      'documento': factura['documento'] ?? '',
      'info_adicional': factura['info_adicional'] ?? '',
      'items': jsonEncode(factura['items']),
      'total': factura['total'],
      'abono': factura['abono'] ?? 0,
      'saldo': factura['saldo'] ?? 0,
      'estado': factura['estado'] ?? 'Abierto',
      'atendido_por': factura['atendido_por'] ?? '',
      'modelo': factura['modelo'] ?? '',
      'serie': factura['serie'] ?? '',
      'estado_actual': factura['estado_actual'] ?? '',
    };
    return await db.update('facturas', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteFactura(int id) async {
    final db = await database;
    return await db.delete('facturas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> saveNegocio(Map<String, dynamic> negocio) async {
    final db = await database;
    final existing = await db.query('negocio', limit: 1);

    Uint8List? logoBytes;
    if (negocio['logo'] != null) {
      final logoImage = negocio['logo'] as img.Image;
      logoBytes = Uint8List.fromList(img.encodePng(logoImage));
    }

    final data = {
      'logo': logoBytes,
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
    img.Image? logoImage;
    if (row['logo'] != null) {
      final logoBytes = row['logo'] as Uint8List;
      logoImage = img.decodeImage(logoBytes);
    }

    return {
      'logo': logoImage,
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

  Future<int> insertCliente(Map<String, dynamic> cliente) async {
    final db = await database;
    final existing = await db.query(
      'clientes',
      where: 'documento = ?',
      whereArgs: [cliente['documento'] ?? ''],
    );
    final data = {
      'nombre': cliente['nombre'] ?? '',
      'email': cliente['email'] ?? '',
      'telefono': cliente['telefono'] ?? '',
      'documento': cliente['documento'] ?? '',
      'info_adicional': cliente['info_adicional'] ?? '',
    };
    if (existing.isNotEmpty) {
      await db.update(
        'clientes',
        data,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return existing.first['id'] as int;
    }
    return await db.insert('clientes', data);
  }

  Future<List<Map<String, dynamic>>> getClientes() async {
    final db = await database;
    return await db.query('clientes', orderBy: 'nombre ASC');
  }

  Future<Map<String, dynamic>?> getClienteById(int id) async {
    final db = await database;
    final results = await db.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<int> insertProducto(Map<String, dynamic> producto) async {
    final db = await database;
    return await db.insert('productos', {'nombre': producto['nombre'] ?? ''});
  }

  Future<List<Map<String, dynamic>>> getProductos() async {
    final db = await database;
    return await db.query('productos', orderBy: 'nombre ASC');
  }

  Future<int> updateProducto(int id, Map<String, dynamic> producto) async {
    final db = await database;
    return await db.update(
      'productos',
      {'nombre': producto['nombre'] ?? ''},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }
}
