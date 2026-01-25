import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subscription.dart';
import '../models/appointment.dart';
import '../models/task.dart';

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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        paymentMethod TEXT,
        isRenewed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT,
        dateTime TEXT NOT NULL,
        location TEXT,
        notes TEXT,
        reminderOffset INTEGER NOT NULL,
        notificationId TEXT,
        createdDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT,
        dueDate TEXT,
        priority TEXT,
        notes TEXT,
        reminderOffset INTEGER NOT NULL,
        notificationId TEXT,
        createdDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS appointments (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          category TEXT,
          dateTime TEXT NOT NULL,
          location TEXT,
          notes TEXT,
          reminderOffset INTEGER NOT NULL,
          notificationId TEXT,
          createdDate TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          category TEXT,
          dueDate TEXT,
          priority TEXT,
          notes TEXT,
          reminderOffset INTEGER NOT NULL,
          notificationId TEXT,
          createdDate TEXT NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Add isCompleted column to tasks table
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN isCompleted INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        // Column might already exist, ignore error
        print('Note: isCompleted column may already exist: $e');
      }
    }
    
    if (oldVersion < 4) {
      // Add isRenewed column to subscriptions table
      try {
        await db.execute('ALTER TABLE subscriptions ADD COLUMN isRenewed INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        print('Note: isRenewed column may already exist: $e');
      }
    }
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

  // ========== APPOINTMENTS ==========
  Future<String> insertAppointment(Appointment appointment) async {
    final db = await database;
    await db.insert('appointments', appointment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return appointment.id;
  }

  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<Appointment?> getAppointmentById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Appointment.fromMap(maps.first);
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> deleteAppointment(String id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // ========== TASKS ==========
  Future<String> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return task.id;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'dueDate ASC, createdDate DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }


}

