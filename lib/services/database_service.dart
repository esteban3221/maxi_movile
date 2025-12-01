import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:maxi_movile/models/ip_addres.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'maxicajero.db');
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ip_addresses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alias TEXT,
        address TEXT UNIQUE,
        description TEXT,
        date_added TEXT
      )
    ''');
  }

  // ✅ INSERTAR IP
  Future<int> insertIp(IpAddress ip) async {
    final db = await database;
    return await db.insert('ip_addresses', ip.toJson());
  }

  // ✅ OBTENER TODAS LAS IPs
  Future<List<IpAddress>> getAllIps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('ip_addresses');
    return List.generate(maps.length, (i) {
      return IpAddress.fromJson(maps[i]);
    });
  }

  // ✅ ELIMINAR IP
  Future<int> deleteIp(String address) async {
    final db = await database;
    return await db.delete(
      'ip_addresses',
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  // ✅ ELIMINAR TODAS LAS IPs
  Future<int> deleteAllIps() async {
    final db = await database;
    return await db.delete('ip_addresses');
  }

  // ✅ ACTUALIZAR IP
  Future<int> updateIp(IpAddress ip) async {
    final db = await database;
    return await db.update(
      'ip_addresses',
      ip.toJson(),
      where: 'address = ?',
      whereArgs: [ip.address],
    );
  }
}
