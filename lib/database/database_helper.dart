import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lost_found.db');

    // Delete existing database to force recreation with new schema
    try {
      await deleteDatabase(path);
    } catch (e) {
      // Ignore errors if database doesn't exist
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        userType TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create items table for lost and found items
    await db.execute('''
       CREATE TABLE items (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         title TEXT NOT NULL,
         description TEXT,
         category TEXT NOT NULL,
         location TEXT,
         contactInfo TEXT,
         status TEXT NOT NULL,
         userId INTEGER,
         imagePath TEXT,
         createdAt TEXT NOT NULL,
         claimedByUserId INTEGER,
         FOREIGN KEY (userId) REFERENCES users (id),
         FOREIGN KEY (claimedByUserId) REFERENCES users (id)
       )
     ''');

    // Create comments table
    await db.execute('''
       CREATE TABLE comments (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         itemId INTEGER NOT NULL,
         userId INTEGER NOT NULL,
         comment TEXT NOT NULL,
         createdAt TEXT NOT NULL,
         FOREIGN KEY (itemId) REFERENCES items (id),
         FOREIGN KEY (userId) REFERENCES users (id)
       )
     ''');
  }

  // Database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add claimedByUserId column to items table
      await db.execute('ALTER TABLE items ADD COLUMN claimedByUserId INTEGER');
    }
  }

  // User registration
  Future<int> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String userType,
  }) async {
    final db = await database;

    // Hash the password
    final hashedPassword = _hashPassword(password);

    return await db.insert('users', {
      'fullName': fullName,
      'email': email.toLowerCase(),
      'password': hashedPassword,
      'userType': userType,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // User login
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);

    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email.toLowerCase(), hashedPassword],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    return results.isNotEmpty;
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Report lost/found item
  Future<int> reportItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required String status, // 'lost' or 'found'
    required int userId,
    String? imagePath,
    String? contactInfo,
  }) async {
    final db = await database;

    return await db.insert('items', {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'status': status,
      'userId': userId,
      'imagePath': imagePath,
      'contactInfo': contactInfo,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Get all items (lost or found)
  Future<List<Map<String, dynamic>>> getItems({String? status}) async {
    final db = await database;

    if (status != null) {
      return await db.query(
        'items',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'createdAt DESC',
      );
    }

    return await db.query('items', orderBy: 'createdAt DESC');
  }

  // Get items by user
  Future<List<Map<String, dynamic>>> getItemsByUser(int userId) async {
    final db = await database;

    return await db.query(
      'items',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  // Search items
  Future<List<Map<String, dynamic>>> searchItems({
    String? query,
    String? category,
    String? status,
  }) async {
    final db = await database;

    String whereClause = '';
    List<String> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause += 'title LIKE ? OR description LIKE ?';
      whereArgs.addAll(['%$query%', '%$query%']);
    }

    if (category != null && category.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    if (status != null && status.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(status);
    }

    return await db.query(
      'items',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
    );
  }

  // Update item status (for claiming)
  Future<int> updateItemStatus(
    int itemId,
    String newStatus, {
    int? claimedByUserId,
  }) async {
    final db = await database;

    final Map<String, dynamic> updateData = {'status': newStatus};
    if (claimedByUserId != null) {
      updateData['claimedByUserId'] = claimedByUserId;
    }

    return await db.update(
      'items',
      updateData,
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // Get item by ID
  Future<Map<String, dynamic>?> getItemById(int itemId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [itemId],
    );

    return results.isNotEmpty ? results.first : null;
  }

  // Add comment to item
  Future<int> addComment({
    required int itemId,
    required int userId,
    required String comment,
  }) async {
    final db = await database;

    // Ensure comments table exists
    await _ensureCommentsTableExists(db);

    return await db.insert('comments', {
      'itemId': itemId,
      'userId': userId,
      'comment': comment,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Ensure comments table exists
  Future<void> _ensureCommentsTableExists(Database db) async {
    try {
      // Check if comments table exists
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='comments'",
      );

      if (result.isEmpty) {
        // Create comments table if it doesn't exist
        await db.execute('''
          CREATE TABLE comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            itemId INTEGER NOT NULL,
            userId INTEGER NOT NULL,
            comment TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (itemId) REFERENCES items (id),
            FOREIGN KEY (userId) REFERENCES users (id)
          )
        ''');
      }
    } catch (e) {
      // If there's an error, try to create the table anyway
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          itemId INTEGER NOT NULL,
          userId INTEGER NOT NULL,
          comment TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (itemId) REFERENCES items (id),
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');
    }
  }

  // Get comments for an item
  Future<List<Map<String, dynamic>>> getCommentsForItem(int itemId) async {
    final db = await database;

    // Ensure comments table exists
    await _ensureCommentsTableExists(db);

    return await db.rawQuery(
      '''
       SELECT c.*, u.fullName, u.email, u.userType
       FROM comments c
       JOIN users u ON c.userId = u.id
       WHERE c.itemId = ?
       ORDER BY c.createdAt DESC
     ''',
      [itemId],
    );
  }

  // Delete comment
  Future<int> deleteComment(int commentId) async {
    final db = await database;

    // Ensure comments table exists
    await _ensureCommentsTableExists(db);

    return await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
  }

  // Delete all comments for an item (when item is deleted)
  Future<int> deleteCommentsForItem(int itemId) async {
    final db = await database;

    // Ensure comments table exists
    await _ensureCommentsTableExists(db);

    return await db.delete(
      'comments',
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
  }

  // Delete item and its comments
  Future<int> deleteItem(int itemId) async {
    final db = await database;

    // First delete all comments for this item
    await deleteCommentsForItem(itemId);

    // Then delete the item
    return await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
