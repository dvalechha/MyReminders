import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subscription.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('subscriptions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY,
        serviceName TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        renewalDate TEXT NOT NULL,
        billingCycle TEXT NOT NULL,
        reminder TEXT NOT NULL,
        reminderType TEXT NOT NULL,
        reminderDaysBefore INTEGER NOT NULL,
        notificationId TEXT,
        notes TEXT,
        paymentMethod TEXT
      )
    ''');
  }

  // Insert subscription
  Future<String> insertSubscription(Subscription subscription) async {
    final db = await database;
    await db.insert('subscriptions', subscription.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return subscription.id;
  }

  // Get all subscriptions
  Future<List<Subscription>> getAllSubscriptions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subscriptions',
      orderBy: 'renewalDate ASC',
    );

    return List.generate(maps.length, (i) => Subscription.fromMap(maps[i]));
  }

  // Get subscription by ID
  Future<Subscription?> getSubscriptionById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Subscription.fromMap(maps.first);
  }

  // Update subscription
  Future<int> updateSubscription(Subscription subscription) async {
    final db = await database;
    return await db.update(
      'subscriptions',
      subscription.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  // Delete subscription
  Future<int> deleteSubscription(String id) async {
    final db = await database;
    return await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all subscriptions
  Future<int> deleteAllSubscriptions() async {
    final db = await database;
    return await db.delete('subscriptions');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

