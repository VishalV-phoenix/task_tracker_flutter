// =============================================
// DATABASE_HELPER.DART
// 
// This is the core database setup file.
// Handles:
// - Creating the SQLite database file on device
// - Creating all tables on first run
// - Database version management (migrations)
// - Providing database instance to all DAOs
// =============================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // ── Singleton Pattern ──────────────────────
  // Only ONE database instance ever exists
  // (like how AppState is one global object)
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  // Private constructor - prevents creating new instances
  DatabaseHelper._internal();

  // Factory constructor - always returns the same instance
  factory DatabaseHelper() => instance;

  // ── Database Configuration ─────────────────
  static const String _databaseName = 'productivity_app.db';

  // Increment this number whenever you change the schema
  // Flutter will call onUpgrade automatically
  static const int _databaseVersion = 1;

  // ── Get Database Instance ──────────────────
  // Creates database if it doesn't exist
  // Returns existing database if already open
  Future<Database> get database async {
    // Return existing database if already open
    if (_database != null) return _database!;

    // Otherwise create/open it
    _database = await _initDatabase();
    return _database!;
  }

  // ── Initialize Database ────────────────────
  // Finds the correct file path on device and opens database
  Future<Database> _initDatabase() async {
    // getDatabasesPath() returns the correct database directory
    // for the current platform (Android/iOS)
    // e.g., /data/data/com.example.productivity_app/databases/
    final dbPath = await getDatabasesPath();

    // join() safely combines path parts
    // Result: /data/.../databases/productivity_app.db
    final path = join(dbPath, _databaseName);

    // Open the database
    // onCreate runs when database is created for the first time
    // onUpgrade runs when databaseVersion increases
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      // Enable foreign keys (for CASCADE deletes)
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ── CREATE ALL TABLES ──────────────────────
  // Runs only ONCE when app is first installed
  // Creates all tables in the correct order
  // (tables with foreign keys must come after their referenced tables)
  Future<void> _createTables(Database db, int version) async {
    // Use a batch for better performance
    // All statements execute as one transaction
    final batch = db.batch();

    // ── Table 1: Settings ──────────────────
    // Single row table for user preferences
    // Equivalent to AppState.settings in JavaScript
    batch.execute('''
      CREATE TABLE settings (
        id                    INTEGER PRIMARY KEY DEFAULT 1,
        theme                 TEXT    NOT NULL DEFAULT 'light',
        final_goal            TEXT    NOT NULL DEFAULT 'Bioinformatics',
        default_notify_before REAL    NOT NULL DEFAULT 3.0,
        auto_archive_days     INTEGER NOT NULL DEFAULT 7,
        notifications_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Insert default settings row immediately
    batch.execute('''
      INSERT INTO settings (
        id, theme, final_goal, default_notify_before,
        auto_archive_days, notifications_enabled
      ) VALUES (1, 'light', 'Bioinformatics', 3.0, 7, 1)
    ''');

    // ── Table 2: Categories ────────────────
    // Dashboard cards - Learning, Projects, etc.
    batch.execute('''
      CREATE TABLE categories (
        id          TEXT    PRIMARY KEY,
        name        TEXT    NOT NULL,
        icon        TEXT    NOT NULL DEFAULT '📁',
        color       TEXT    NOT NULL DEFAULT '#4F46E5',
        type        TEXT    NOT NULL DEFAULT 'kanban',
        sort_order  INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT    NOT NULL
      )
    ''');

    // ── Table 3: Tasks ─────────────────────
    // Main tasks in kanban categories
    // REFERENCES categories(id) ON DELETE CASCADE means:
    // when a category is deleted, all its tasks are auto-deleted
    batch.execute('''
      CREATE TABLE tasks (
        id              TEXT    PRIMARY KEY,
        category_id     TEXT    NOT NULL,
        title           TEXT    NOT NULL,
        description     TEXT,
        status          TEXT    NOT NULL DEFAULT 'todo',
        estimated_time  TEXT,
        due_date        TEXT,
        notify_before   REAL    NOT NULL DEFAULT 3.0,
        notified        INTEGER NOT NULL DEFAULT 0,
        completed_at    TEXT,
        archived_at     TEXT,
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL,
        FOREIGN KEY (category_id) 
          REFERENCES categories(id) 
          ON DELETE CASCADE
      )
    ''');

    // ── Table 4: Subtasks ──────────────────
    // Individual checklist items inside a task
    // CASCADE: deleting a task deletes all its subtasks
    batch.execute('''
      CREATE TABLE subtasks (
        id          TEXT    PRIMARY KEY,
        task_id     TEXT    NOT NULL,
        title       TEXT    NOT NULL,
        completed   INTEGER NOT NULL DEFAULT 0,
        note        TEXT,
        timestamp   TEXT,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (task_id) 
          REFERENCES tasks(id) 
          ON DELETE CASCADE
      )
    ''');

    // ── Table 5: Task Links (URLs) ─────────
    // External links attached to tasks
    // e.g., YouTube videos, GitHub repos
    batch.execute('''
      CREATE TABLE task_links (
        id          TEXT PRIMARY KEY,
        task_id     TEXT NOT NULL,
        label       TEXT NOT NULL,
        url         TEXT NOT NULL,
        link_type   TEXT,
        added_at    TEXT NOT NULL,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (task_id) 
          REFERENCES tasks(id) 
          ON DELETE CASCADE
      )
    ''');

    // ── Table 6: Linked Tasks (Junction) ───
    // Tracks which tasks are linked to each other
    // Many-to-many: Task A ←→ Task B ←→ Task C
    // Equivalent to task.linkedTaskIds in JavaScript
    batch.execute('''
      CREATE TABLE linked_tasks (
        task_id         TEXT NOT NULL,
        linked_task_id  TEXT NOT NULL,
        PRIMARY KEY (task_id, linked_task_id),
        FOREIGN KEY (task_id) 
          REFERENCES tasks(id) 
          ON DELETE CASCADE,
        FOREIGN KEY (linked_task_id) 
          REFERENCES tasks(id) 
          ON DELETE CASCADE
      )
    ''');

    // ── Table 7: Notes ─────────────────────
    // Simple checkbox items for notes-type categories
    batch.execute('''
      CREATE TABLE notes (
        id          TEXT    PRIMARY KEY,
        category_id TEXT    NOT NULL,
        title       TEXT    NOT NULL,
        content     TEXT,
        completed   INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT    NOT NULL,
        updated_at  TEXT    NOT NULL,
        FOREIGN KEY (category_id) 
          REFERENCES categories(id) 
          ON DELETE CASCADE
      )
    ''');

    // ── Table 8: Checkpoints ───────────────
    // Roadmap milestones (Programming Basics, Python Mastery, etc.)
    batch.execute('''
      CREATE TABLE checkpoints (
        id          TEXT    PRIMARY KEY,
        title       TEXT    NOT NULL,
        description TEXT,
        notes       TEXT,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        completed   INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT    NOT NULL
      )
    ''');

    // ── Table 9: Checkpoint Tasks ──────────
    // Which tasks are linked to which checkpoint
    // Many-to-many junction table
    batch.execute('''
      CREATE TABLE checkpoint_tasks (
        checkpoint_id TEXT NOT NULL,
        task_id       TEXT NOT NULL,
        PRIMARY KEY (checkpoint_id, task_id),
        FOREIGN KEY (checkpoint_id) 
          REFERENCES checkpoints(id) 
          ON DELETE CASCADE,
        FOREIGN KEY (task_id) 
          REFERENCES tasks(id) 
          ON DELETE CASCADE
      )
    ''');

    // ── Table 10: Notifications ────────────
    // In-app notification center items
    batch.execute('''
      CREATE TABLE notifications (
        id              TEXT    PRIMARY KEY,
        task_id         TEXT    NOT NULL,
        task_title      TEXT    NOT NULL,
        category_name   TEXT,
        category_icon   TEXT,
        type            TEXT,
        due_date        TEXT,
        message         TEXT,
        created_at      TEXT    NOT NULL,
        dismissed       INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── Indexes for Performance ────────────
    // Like a book's index - makes queries faster
    // Create index on columns we filter/sort by often

    // Find tasks by category quickly
    batch.execute('''
      CREATE INDEX idx_tasks_category 
      ON tasks(category_id)
    ''');

    // Find tasks by status quickly (for kanban columns)
    batch.execute('''
      CREATE INDEX idx_tasks_status 
      ON tasks(status)
    ''');

    // Find archived tasks quickly
    batch.execute('''
      CREATE INDEX idx_tasks_archived 
      ON tasks(archived_at)
    ''');

    // Find tasks with due dates quickly (for notification checks)
    batch.execute('''
      CREATE INDEX idx_tasks_due_date 
      ON tasks(due_date)
    ''');

    // Find subtasks by parent task quickly
    batch.execute('''
      CREATE INDEX idx_subtasks_task 
      ON subtasks(task_id)
    ''');

    // Find notes by category quickly
    batch.execute('''
      CREATE INDEX idx_notes_category 
      ON notes(category_id)
    ''');

    // Find undismissed notifications quickly
    batch.execute('''
      CREATE INDEX idx_notifications_dismissed 
      ON notifications(dismissed)
    ''');

    // Execute all statements together
    await batch.commit(noResult: true);

    // Insert default data after tables are created
    await _insertDefaultData(db);
  }

  // ── INSERT DEFAULT DATA ────────────────────
  // Seeds the database with initial categories and roadmap
  // Same as DefaultData in your JavaScript app
  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    // ── Default Categories ─────────────────
    final defaultCategories = [
      {
        'id': 'cat_1',
        'name': 'Learning',
        'icon': '📚',
        'color': '#4F46E5',
        'type': 'kanban',
        'sort_order': 0,
        'created_at': now,
      },
      {
        'id': 'cat_2',
        'name': 'Projects',
        'icon': '🚀',
        'color': '#10B981',
        'type': 'kanban',
        'sort_order': 1,
        'created_at': now,
      },
      {
        'id': 'cat_3',
        'name': 'College Work',
        'icon': '🎓',
        'color': '#F59E0B',
        'type': 'kanban',
        'sort_order': 2,
        'created_at': now,
      },
      {
        'id': 'cat_4',
        'name': 'Entertainment',
        'icon': '🎮',
        'color': '#EC4899',
        'type': 'kanban',
        'sort_order': 3,
        'created_at': now,
      },
      {
        'id': 'cat_5',
        'name': 'Quick Notes',
        'icon': '📝',
        'color': '#06B6D4',
        'type': 'notes',
        'sort_order': 4,
        'created_at': now,
      },
    ];

    for (final cat in defaultCategories) {
      batch.insert('categories', cat);
    }

    // ── Default Roadmap Checkpoints ────────
    final defaultCheckpoints = [
      {
        'id': 'cp_1',
        'title': 'Programming Basics',
        'description': 'Master fundamental programming concepts',
        'notes': 'Focus on Python and data structures',
        'sort_order': 0,
        'completed': 1, // 1 = true in SQLite
        'created_at': now,
      },
      {
        'id': 'cp_2',
        'title': 'Python Mastery',
        'description': 'Advanced Python programming skills',
        'notes': 'Learn libraries like NumPy, Pandas',
        'sort_order': 1,
        'completed': 1,
        'created_at': now,
      },
      {
        'id': 'cp_3',
        'title': 'Algorithms',
        'description': 'Understanding algorithms and complexity',
        'notes': 'Important for processing biological data',
        'sort_order': 2,
        'completed': 0, // 0 = false in SQLite
        'created_at': now,
      },
      {
        'id': 'cp_4',
        'title': 'Machine Learning',
        'description': 'ML fundamentals and applications',
        'notes': 'Focus on supervised learning first',
        'sort_order': 3,
        'completed': 0,
        'created_at': now,
      },
      {
        'id': 'cp_5',
        'title': 'Genomics Fundamentals',
        'description': 'Basic understanding of genetics and genomics',
        'notes': 'Learn about DNA, RNA, proteins',
        'sort_order': 4,
        'completed': 0,
        'created_at': now,
      },
      {
        'id': 'cp_6',
        'title': 'Bioinformatics Tools',
        'description': 'Master common bioinformatics tools',
        'notes': 'BLAST, sequence alignment tools',
        'sort_order': 5,
        'completed': 0,
        'created_at': now,
      },
    ];

    for (final cp in defaultCheckpoints) {
      batch.insert('checkpoints', cp);
    }

    await batch.commit(noResult: true);
  }

  // ── DATABASE MIGRATIONS ────────────────────
  // Called when you increase _databaseVersion
  // Used to add new columns or tables in future updates
  // Without breaking existing user data
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example: if you add a new column in version 2
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE tasks ADD COLUMN priority TEXT');
    // }

    // Example: if you add a new table in version 3
    // if (oldVersion < 3) {
    //   await db.execute('CREATE TABLE tags (...)');
    // }

    // For now: nothing to migrate (version 1 is the first version)
  }

  // ── UTILITY METHODS ───────────────────────

  // Close database connection
  // Call this when app closes (usually not needed in Flutter)
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Delete entire database (for testing or reset)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}