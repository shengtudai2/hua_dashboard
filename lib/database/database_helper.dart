import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/beiyun_task.dart';
import '../models/budget.dart';
import '../models/todo.dart';
import '../models/beiyun_extra.dart';

/// 单例数据库助手，管理全部 4 个 App 的数据表
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'hua_todo.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        // 备孕任务
        await db.execute('''
          CREATE TABLE beiyun_tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            stage TEXT NOT NULL,
            done INTEGER DEFAULT 0,
            fav INTEGER DEFAULT 0,
            note TEXT DEFAULT '',
            created_at INTEGER NOT NULL,
            plan_date TEXT,
            pinned INTEGER DEFAULT 0
          )
        ''');
        // 备孕周期事件
        await db.execute('''
          CREATE TABLE cycle_events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            type INTEGER NOT NULL,
            note TEXT DEFAULT ''
          )
        ''');
        // 备孕营养打卡
        await db.execute('''
          CREATE TABLE supplement_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            type TEXT NOT NULL,
            done INTEGER DEFAULT 1
          )
        ''');
        // 备孕财务
        await db.execute('''
          CREATE TABLE beiyun_finance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            note TEXT DEFAULT '',
            category TEXT DEFAULT '一般'
          )
        ''');
        // 备婚预算分类
        await db.execute('''
          CREATE TABLE budget_categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            group TEXT NOT NULL,
            budget REAL DEFAULT 0,
            spent REAL DEFAULT 0,
            pinned INTEGER DEFAULT 0,
            done INTEGER DEFAULT 0,
            icon TEXT DEFAULT ''
          )
        ''');
        // 备婚流水
        await db.execute('''
          CREATE TABLE budget_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL,
            category_name TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            note TEXT DEFAULT ''
          )
        ''');
        // 事项模块
        await db.execute('''
          CREATE TABLE todo_modules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT DEFAULT '#FFB74D',
            icon TEXT DEFAULT '📌'
          )
        ''');
        // 事项任务
        await db.execute('''
          CREATE TABLE todo_tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            module_id INTEGER,
            title TEXT NOT NULL,
            date TEXT,
            done INTEGER DEFAULT 0,
            pinned INTEGER DEFAULT 0,
            order_index INTEGER
          )
        ''');
      },
    );
  }

  // ---------- 通用 CRUD ----------
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> update(String table, Map<String, dynamic> row,
      {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<int> count(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) c FROM $table${where != null ? ' WHERE $where' : ''}',
        whereArgs ?? []);
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  // ---------- 备孕任务 ----------
  Future<List<BeiyunTask>> getBeiyunTasks() async {
    final rows = await query('beiyun_tasks', orderBy: 'pinned DESC, created_at DESC');
    return rows.map(BeiyunTask.fromMap).toList();
  }

  Future<int> addBeiyunTask(BeiyunTask t) => insert('beiyun_tasks', t.toMap());
  Future<int> updateBeiyunTask(BeiyunTask t) =>
      update('beiyun_tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  Future<int> deleteBeiyunTask(int id) =>
      delete('beiyun_tasks', where: 'id = ?', whereArgs: [id]);

  // ---------- 周期事件 ----------
  Future<List<CycleEvent>> getCycleEvents() async {
    final rows = await query('cycle_events', orderBy: 'date');
    return rows.map(CycleEvent.fromMap).toList();
  }

  Future<int> addCycleEvent(CycleEvent e) => insert('cycle_events', e.toMap());
  Future<int> deleteCycleEvent(int id) =>
      delete('cycle_events', where: 'id = ?', whereArgs: [id]);

  // ---------- 营养打卡 ----------
  Future<List<SupplementLog>> getSupplementLogs() async {
    final rows = await query('supplement_logs');
    return rows.map(SupplementLog.fromMap).toList();
  }

  Future<int> addSupplementLog(SupplementLog s) => insert('supplement_logs', s.toMap());

  // ---------- 备孕财务 ----------
  Future<List<BeiyunFinance>> getBeiyunFinance() async {
    final rows = await query('beiyun_finance', orderBy: 'date DESC');
    return rows.map(BeiyunFinance.fromMap).toList();
  }

  Future<int> addBeiyunFinance(BeiyunFinance f) => insert('beiyun_finance', f.toMap());
  Future<int> deleteBeiyunFinance(int id) =>
      delete('beiyun_finance', where: 'id = ?', whereArgs: [id]);

  // ---------- 备婚预算 ----------
  Future<List<BudgetCategory>> getBudgetCategories() async {
    final rows = await query('budget_categories', orderBy: 'pinned DESC, id ASC');
    return rows.map(BudgetCategory.fromMap).toList();
  }

  Future<List<BudgetRecord>> getBudgetRecords() async {
    final rows = await query('budget_records', orderBy: 'date ASC');
    return rows.map(BudgetRecord.fromMap).toList();
  }

  Future<int> addBudgetCategory(BudgetCategory c) =>
      insert('budget_categories', c.toMap());
  Future<int> updateBudgetCategory(BudgetCategory c) =>
      update('budget_categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  Future<int> deleteBudgetCategory(int id) =>
      delete('budget_categories', where: 'id = ?', whereArgs: [id]);

  Future<int> addBudgetRecord(BudgetRecord r) => insert('budget_records', r.toMap());
  Future<int> deleteBudgetRecord(int id) =>
      delete('budget_records', where: 'id = ?', whereArgs: [id]);

  // ---------- 事项 ----------
  Future<List<TodoModule>> getTodoModules() async {
    final rows = await query('todo_modules', orderBy: 'id ASC');
    return rows.map(TodoModule.fromMap).toList();
  }

  Future<List<TodoTask>> getTodoTasks() async {
    final rows = await query('todo_tasks', orderBy: 'pinned DESC, order_index ASC, id DESC');
    return rows.map(TodoTask.fromMap).toList();
  }

  Future<int> addTodoModule(TodoModule m) => insert('todo_modules', m.toMap());
  Future<int> updateTodoModule(TodoModule m) =>
      update('todo_modules', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  Future<int> deleteTodoModule(int id) =>
      delete('todo_modules', where: 'id = ?', whereArgs: [id]);

  Future<int> addTodoTask(TodoTask t) => insert('todo_tasks', t.toMap());
  Future<int> updateTodoTask(TodoTask t) =>
      update('todo_tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  Future<int> deleteTodoTask(int id) =>
      delete('todo_tasks', where: 'id = ?', whereArgs: [id]);
}