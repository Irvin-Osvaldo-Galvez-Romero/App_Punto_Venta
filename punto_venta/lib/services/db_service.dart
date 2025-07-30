import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/producto.dart';
import '../models/venta.dart';

class DBService {
  static Database? _db;
  static const String _dbName = 'punto_venta.db';
  static const int _dbVersion = 1;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            precioCompra REAL,
            precioVenta REAL,
            codigoBarras TEXT,
            cantidadStock INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE ventas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT,
            productosVendidos TEXT,
            total REAL
          )
        ''');
      },
    );
  }

  // CRUD Productos
  static Future<int> agregarProducto(Producto producto) async {
    final dbClient = await db;
    return await dbClient.insert('productos', producto.toMap());
  }

  static Future<List<Producto>> obtenerProductos() async {
    final dbClient = await db;
    final res = await dbClient.query('productos');
    return res.map((e) => Producto.fromMap(e)).toList();
  }

  static Future<int> actualizarProducto(Producto producto) async {
    final dbClient = await db;
    return await dbClient.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  static Future<int> eliminarProducto(int id) async {
    final dbClient = await db;
    return await dbClient.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Producto?> buscarProductoPorCodigo(String codigo) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'productos',
      where: 'REPLACE(LOWER(codigoBarras), " ", "") = ?',
      whereArgs: [codigo.toLowerCase().replaceAll(' ', '')],
    );
    if (res.isNotEmpty) {
      return Producto.fromMap(res.first);
    }
    return null;
  }

  static Future<List<Producto>> buscarProductosPorNombre(String nombre) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'productos',
      where: 'LOWER(nombre) LIKE ?',
      whereArgs: ['%${nombre.toLowerCase()}%'],
    );
    return res.map((e) => Producto.fromMap(e)).toList();
  }

  // Ventas
  static Future<int> registrarVenta(Venta venta) async {
    final dbClient = await db;
    return await dbClient.insert('ventas', {
      'fecha': venta.fecha.toIso8601String(),
      'productosVendidos': jsonEncode(
        venta.productosVendidos.map((e) => e.toMap()).toList(),
      ),
      'total': venta.total,
    });
  }

  static Future<List<Venta>> obtenerVentas() async {
    final dbClient = await db;
    final res = await dbClient.query('ventas');
    return res
        .map(
          (e) => Venta(
            id: e['id'] as int?,
            fecha: DateTime.parse(e['fecha'] as String),
            productosVendidos:
                (jsonDecode(e['productosVendidos'] as String) as List)
                    .map(
                      (x) => ProductoVendido.fromMap(x as Map<String, dynamic>),
                    )
                    .toList(),
            total: e['total'] as double,
          ),
        )
        .toList();
  }
}
