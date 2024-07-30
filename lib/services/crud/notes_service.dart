import 'package:flutter/material.dart';
import 'package:mynotes/services/crud/crud_crudexceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class NotesService {
  Database? _db;

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);
    final updatesCount = await db.update(noteTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });

    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      return await getNote(id: note.id);
    }
  }

  Future<Iterable<DatabaseNote>> getAllNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
    );
    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
    // where is noteRow coming from?
    // The noteRow variable is a parameter of the map method. The map method is called on the notes list, which is a list of rows returned by the query method. The map method takes a function as an argument and applies that function to each element of the list. In this case, the function is an anonymous function that takes a row as a parameter and returns a DatabaseNote object created from that row.
    // what is the type of noteRow?
    // The type of noteRow is Map<String, Object?>. This is the type of the rows returned by the query method. Each row is a map where the keys are column names and the values are the corresponding values in the row.
    // but noteRow is not defined in the function getAllNote?
    // The noteRow variable is a parameter of the anonymous function passed to the map method. The map method applies the function to each element of the list and passes the element as an argument to the function. In this case, the element is a row returned by the query method, and the function creates a DatabaseNote object from that row.
  }

  Future<DatabaseNote> getNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      return DatabaseNote.fromRow(notes.first);
    }
  }

  Future<int> deleteAllNotes() async {
    final db = _getDatabaseOrThrow();
    return await db.delete(noteTable);
  }

  Future<void> deleteNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);

    // make sure owner exists in the database with the correct id
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    const text = '';
    // create the note
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );
    return note;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final user = await db.query(
      userTable,
      limit: 1,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (user.isEmpty) {
      throw UserAlreadyExists();
    } else {
      return DatabaseUser.fromRow(user.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(
      userTable,
      {emailColumn: email.toLowerCase()},
    );
    return DatabaseUser(id: userId, email: email);
  }

  Future<void> deleteUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: '$emailColumn = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatebaseNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatebaseNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      // Create the user tables if they don't exist
      await db.execute(createUserTable);
      // Create the notes tables if they don't exist
      await db.execute(createnoteTable);
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      // why Object? and not Object
      // The Object? type allows the value to be null. If the value is null, the map[idColumn] as int expression will throw an exception. If the value is not null, the map[idColumn] as int expression will return the value as an int.
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;
  // where is the fromRow method?
  // The fromRow method is a factory constructor that creates a DatabaseUser object from a row in the database.
  // What is a factory constructor?
  // A factory constructor is a constructor that returns an instance of a class. It is used to create objects of a class without exposing the constructor to the outside world.
  // so can i call fromRow anything? or does it have to be fromRow?
  // You can call the factory constructor anything you want. The name fromRow is a convention used to indicate that the method creates an object from a row in a database.
  // can i name it fromMyRow or fromDatabaseRow?
  // Yes, you can name it fromMyRow. The name of the factory constructor is up to you, but it is a good practice to use a name that describes what the method does.

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  const DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      // what does fromRow do?
      // The fromRow method is a factory constructor that creates a DatabaseNote object from a row in the database.
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;
  // isSyncedWithCloud = map[isSyncedWithCloudColumn] as bool;
  // what is the difference between the two lines above?
  // The first line converts the value of the isSyncedWithCloudColumn to a boolean value by checking if it is equal to 1. If it is equal to 1, it sets the value to true; otherwise, it sets it to false.
  //The second line assumes that the value of the isSyncedWithCloudColumn is already a boolean value and assigns it directly to the isSyncedWithCloud property.
  @override
  String toString() =>
      'Note, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';
}

const dbName = 'notes.db';
const noteTable = 'notes';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = '''
        CREATE TABLE IF NOT EXISTS $userTable (
          $idColumn INTEGER NOT NULL,
          $emailColumn TEXT NOT NULL UNIQUE,
          PRIMARY KEY ($idColumn AUTOINCREMENT)
        );
      ''';
const createnoteTable = '''
        CREATE TABLE IF NOT EXISTS $noteTable (
          $idColumn INTEGER NOT NULL,
          $userIdColumn INTEGER NOT NULL,
          $textColumn TEXT,
          $isSyncedWithCloudColumn INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY ($userIdColumn) REFERENCES $userTable($idColumn),
          PRIMARY KEY ($idColumn AUTOINCREMENT)
        );
      ''';
