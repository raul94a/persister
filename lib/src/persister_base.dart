import 'dart:async';

import 'package:mysql_manager/mysql_manager.dart';
import 'package:persister/src/select_builder.dart';

///[Persister] will manager the connection for yourself.
///You will only have to worry about advanced SQL queries
///and declare the models in a good way. Examples are provided in order there's no problem with this dependency usage.
///Please when declaring the model, the primary key should be the first element both columns and values arrays. If not, you will have several problems;
abstract class Persister<T> {
  final String table;
  final bool isIdAutoIncrementable;
  final List<String> columns;
  static final MySQLManager _mySQLManager = MySQLManager.instance;
  late final SelectBuilder selectBuilder;

  Persister(
      {required this.table,
      required this.columns,
      required this.isIdAutoIncrementable}) {
    selectBuilder = SelectBuilder(selectedTable: table);
  }

  //should be setted on the children
  List<Object?> get values;

  T fromMap(Map<String, dynamic> data);

  ///Children which extends Persister could access this method. It only needs
  ///the [values] getter from the child as argument. [values] correspond to
  /// the actual values of every attribute from the child
  /// for example if we had a class called Test:
  /// ```dart
  ///   class Test extends Persister<Test>{
  ///         //if the primary key is autoincrementable and is set just before of being inserted within the database,
  ///         //you can declare a posible null atribute (int? id, for example), or you can do as the example, providing
  ///         //a default id. This default id isn't used when you save the object into MySql, at least always when isAutoIncrementable
  ///         //is true. It's highly recomended to define a default id that will never be used by your DB.
  ///         int id;
  ///         String str;
  ///         Test({this.id = -1, required this.str}) : super(columns: ['id', 'str'], table: 'test', isAutoIncrementable: true);
  ///
  ///         static Test fromMap(Map<String,dynamic> map) => Test(id: map['id'], str: map['str']);
  ///         ...
  ///       @override
  ///       List<Object> values = [id, str];
  ///     }
  ///
  ///   main() async {
  ///      Test test = Test(str: 'test-string');
  ///      //the save method will return the data of every inserted element, including the primary key
  ///      //in the case it was autoIncrementable
  ///      //Parsing this data is easy as call the deserialize method to parse this Map<String,dynamic> into the object
  ///      //YOU SHOULD CREATE A fromMap static method or constructor in order to use deserialize!!!
  ///      test =  await test.save(values: test.values).deserialize((map) => Test.fromMap(map));
  ///
  ///   }
  /// ```

  Future<T> save() async {
    int insertedId = 0;
    final conn = await _mySQLManager
        .init()
        .onError((error, stackTrace) => throw Exception(error.toString()));

    final insertionQuery =
        _InsertionQuery(table: table, columns: columns, values: values);

    String sql = isIdAutoIncrementable
        ? insertionQuery.queryWithoutId
        : insertionQuery.query;

    try {
      final res = await conn.query(
          sql, isIdAutoIncrementable ? values.sublist(1) : values);

      if (isIdAutoIncrementable) {
        insertedId = res.insertId!;
        values.first = insertedId;
        print('insertedID $insertedId');
        print(values);
      }
    } catch (err) {
      throw Exception(err.toString());
    } finally {
      await conn.close();
    }

    final data =
        isIdAutoIncrementable ? _createUpdatedMap(insertedId) : _createMap();
    return fromMap(data);
  }

  ///To use the update method the best practice is to create the toMap() method
  ///in your model, in order to pass the data easily. In the future, this method maybe can return a Map<String,dynamic>
  /// ```dart
  ///   class Test extends Persister<Test>{
  ///         //if the primary key is autoincrementable and is set just before of being inserted within the database,
  ///         //you can declare a posible null atribute (int? id, for example), or you can do as the example, providing
  ///         //a default id. This default id isn't used when you save the object into MySql, at least always when isAutoIncrementable
  ///         //is true. It's highly recomended to define a default id that will never be used by your DB.
  ///         int id;
  ///         String str;
  ///         Test({this.id = -1, required this.str}) : super(columns: ['id', 'str'], table: 'test', isAutoIncrementable: true);
  ///
  ///         static Test fromMap(Map<String,dynamic> map) => Test(id: map['id'], str: map['str']);
  ///         Map<String,dynamic> toMap() => {'id': id, 'str': str};
  ///         ...
  ///       @override
  ///       List<Object> values = [id, str];
  ///     }
  ///
  ///   main() async {
  ///      Test test = Test(str: 'test-string');
  ///      //the save method will return the data of every inserted element, including the primary key
  ///      //in the case it was autoIncrementable
  ///      //Parsing this data is easy as call the deserialize method to parse this Map<String,dynamic> into the object
  ///      //YOU SHOULD CREATE A fromMap static method or constructor in order to use deserialize!!!
  ///      test =  await test.save(values: test.values).deserialize((map) => Test.fromMap(map));
  ///      test.str = 'updated-string';
  ///      await test.update(data: test.toMap());
  ///
  ///
  ///   }
  /// ```
  Future<void> update() async {
    final conn = await _mySQLManager
        .init()
        .onError((error, stackTrace) => throw Exception(error.toString()));
    try {
      final updateQuery = _UpdateQuery(data: _createMap(), table: table);

      List<dynamic> updateValues = values.sublist(1)..add(values[0]);
      print(updateValues);
      print(updateQuery.updateQuery);
      await conn.query(updateQuery.updateQuery, updateValues);
    } catch (error) {
      throw Exception(error.toString());
    } finally {
      await conn.close();
    }
  }

  ///Deletes the row associated with the object ID.
  Future<void> delete() async {
    final data = _createMap();

    String idField = columns.first;
    dynamic idValue = data[idField];
    final conn = await _mySQLManager
        .init()
        .onError((error, stackTrace) => throw Exception(error.toString()));
    try {
      await conn.query('DELETE from $table WHERE $idField=$idValue');
    } catch (err) {
      throw Exception(err.toString());
    } finally {
      await conn.close();
    }
  }

  ///Select data and return a List of object. To have success using this method,
  ///your model has to own a [fromMap] method that will parse every row fetched with
  ///the selection query.
  ///
  ///How to implement a fromMap method in your model?
  ///```dart
  /// class Test extends Persister<Test>{
  ///   int? id;
  ///   String str;
  ///   Test({this.id, required this.str}) : super({columns: ['id', 'str'], isIdAutoIncrementable: true, table: 'test'});
  ///
  ///   //factory fromMap constructor
  ///   factory Test.fromMap(Map<String,dynamic> map) => Test(id: map['id'], str: map['str']);
  ///
  ///   //overriden fromMap method from Persister
  ///   @override
  ///   Test fromMap(Map<String,dynami> map)) => Test.fromMap(map);
  ///
  ///   @override
  ///   List<Object?> get values => [id,str];
  /// }
  ///```
  static Future<List<T>> selectWithConversion<T>(
      {required String sql,
      required T Function(Map<String, dynamic>) fromMap}) async {
    if (!sql.toLowerCase().contains('select')) {
      throw Exception('Query does not contain select clause');
    }
    final conn = await _mySQLManager
        .init()
        .onError((error, stackTrace) => throw Exception(error.toString()));
    final res = await conn.query(sql);
    List<T> tes = [];
    for (var r in res) {
      tes.add(fromMap(r.fields));
    }

    return tes;
  }

  ///[table] references the table where every row is gonna be fetched.
  ///[returns] a Future<List<Map<String,dynamic>>> which can be parsed concatenating
  ///[deserialize] method. Deserialize needs the developer to code the [fromMap] method
  ///
  ///Example:
  ///```dart
  /// final tests = await Persister.selectAll(table: 'test').deserialize((map) => Test.fromMap(map));
  ///
  ///```
  static Future<List<Map<String, dynamic>>> selectAll(
      {required String table}) async {
    final conn = await _mySQLManager
        .init()
        .onError((error, stackTrace) => throw Exception(error.toString()));
    List<Map<String, dynamic>> results = [];

    final res = await conn
        .query('select * from $table')
        .onError((error, stackTrace) async {
      await conn.close();
      throw Exception(error);
    });
    results = res.map((e) => e.fields).toList();
    await conn.close();
    return results;
  }

  ///```dart
  /// class Test extends Persister<Test>{
  ///   int? id;
  ///   String str;
  ///   Test({this.id, required this.str}) : super({columns: ['id', 'str'], isIdAutoIncrementable: true, table: 'test'});
  ///
  ///   //factory fromMap constructor
  ///   factory Test.fromMap(Map<String,dynamic> map) => Test(id: map['id'], str: map['str']);
  ///
  ///   //overriden fromMap method from Persister
  ///   @override
  ///   Test fromMap(Map<String,dynami> map)) => Test.fromMap(map);
  ///
  ///   @override
  ///   List<Object?> get values => [id,str];
  /// }
  ///```
  static Future<List<T>> selectAllWithConversion<T>(
      {required String table,
      required T Function(Map<String, dynamic>) fromMap}) async {
    final selectionList = await selectAll(table: table);
    List<T> list = [];
    for (Map<String, dynamic> map in selectionList) {
      list.add(fromMap(map));
    }
    return list;
  }

  ///You can set your own [sql] sentence. [sql] may use placeholders in order to use prepared statements.
  ///Placeholders values need to be passed into [values] array
  ///
  ///
  ///[nativeQuery] can be parsed directly into a List of objects with [deserialize] method
  ///This method needs the fromMap function from your model. There's a example on how to do id.
  ///
  ///```dart
  /// class Test extends Persister<Test>{
  ///   int? id;
  ///   String str;
  ///   Test({this.id, required this.str}) : super({columns: ['id', 'str'], isIdAutoIncrementable: true, table: 'test'});
  ///
  ///   //factory fromMap constructor
  ///   factory Test.fromMap(Map<String,dynamic> map) => Test(id: map['id'], str: map['str']);
  ///
  ///   //overriden fromMap method from Persister
  ///   @override
  ///   Test fromMap(Map<String,dynami> map)) => Test.fromMap(map);
  ///
  ///   @override
  ///   List<Object?> get values => [id,str];
  /// }
  ///```
  static Future<Results> nativeQuery(
      {required String sql, List<Object>? values}) async {
    final conn = await _mySQLManager.init();
    final results = await conn.query(sql, values);
    await conn.close();
    return results;
  }

  Map<String, dynamic> _createMap() {
    int length = columns.length;
    if (columns.length != values.length) {
      throw Exception('values and columns have different length');
    }
    Map<String, dynamic> map = {};

    for (int i = 0; i < length; i++) {
      map.addAll({columns[i]: values[i]});
    }
    return map;
  }

  Map<String, dynamic> _createUpdatedMap(int insertedId) {
    final data = _createMap();
    data[columns.first] = insertedId;
    return data;
  }
}

class _UpdateQuery {
  final String table;
  List<String> columns = const [];
  List<Object> values = const [];
  late String idField;
  late Object idValue;
  _UpdateQuery({required Map<String, dynamic> data, required this.table}) {
    columns = data.keys.toList();
    values = data.values.toList().cast();
    idField = columns.first;
    idValue = values.first;
  }

  String _generateQuery() =>
      'UPDATE $table SET ${_generatePreparedStatement(columns: columns)}';

  String _generatePreparedStatement({required List<String> columns}) {
    String preparedStatement = '';
    List<String> updateColumns = columns.sublist(1);
    for (int i = 0; i < updateColumns.length; i++) {
      if (i < updateColumns.length - 1) {
        preparedStatement += '${updateColumns[i]}=?, ';
      } else {
        preparedStatement += '${updateColumns[i]}=? WHERE ${columns[0]}=?';
      }
    }
    return preparedStatement;
  }

  String get updateQuery => _generateQuery();
}

class _InsertionQuery {
  final String table;
  final List<String> columns;
  final List<dynamic> values;
  const _InsertionQuery(
      {required this.table, required this.columns, required this.values});
  String _generateQuery() {
    if (columns.length != values.length) {
      throw Exception(
          'Columns and values must have the same number of members');
    }
    String columnString = columns.join(',');
    String placeHolder = '';
    int placerHolderIterations = values.length;
    for (int i = 0; i < placerHolderIterations; i++) {
      if (i < placerHolderIterations - 1) {
        placeHolder += '?,';
      } else {
        placeHolder += '?';
      }
    }
    return 'INSERT INTO $table ($columnString) VALUES ($placeHolder)';
  }

  String get query => _generateQuery();
  String get queryWithoutId {
    List<String> newColumns = columns.sublist(1);

    String columnString = newColumns.join(',');
    String placeHolder = '';
    int placerHolderIterations = values.length - 1;
    for (int i = 0; i < placerHolderIterations; i++) {
      if (i < placerHolderIterations - 1) {
        placeHolder += '?,';
      } else {
        placeHolder += '?';
      }
    }
    return 'INSERT INTO $table ($columnString) VALUES ($placeHolder)';
  }
}
