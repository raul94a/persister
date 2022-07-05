import 'dart:async';

import 'package:mysql_manager/mysql_manager.dart';
import 'package:persister/src/select_builder.dart';


abstract class Persister<T> {
  final String table;
  final bool isIdAutoIncrementable;
  final List<String> columns;
  static final MySQLManager _mySQLManager = MySQLManager.instance;
  late final SelectBuilder selectBuilder;

  Persister({required this.table, required this.columns, required this.isIdAutoIncrementable}) {
    selectBuilder = SelectBuilder(selectedTable: table);
  }

  List<Object> get values => [];
  Map<String, dynamic> toMap();
  T fromMap(Map<String, dynamic> map);

  ///It
  Future<Map<String, dynamic>> save({List<Object> values = const []}) async {
    int insertedId = 0;
    final conn = await _mySQLManager
        .init()
        .onError((error, stackTrace) => throw Exception(error.toString()));

    final insertionQuery = _InsertionQuery(table: table, columns: columns, values: values);

    String sql = isIdAutoIncrementable ? insertionQuery.queryWithoutId : insertionQuery.query;

    try {
      final res = await conn.query(sql, isIdAutoIncrementable ? values.sublist(1) : values);

      if (isIdAutoIncrementable) {
        insertedId = res.insertId!;
        values.first = insertedId;
      }
    } catch (err) {
      throw Exception(err.toString());
    } finally {
      await conn.close();
    }
    return _createMap(values: values);
  }

  update({required Map<String, dynamic> data}) async {
    final conn = await _mySQLManager
        .init()
        .onError((error, stackTrace) => throw Exception(error.toString()));
    try {
      final updateQuery = _UpdateQuery(data: data, table: table);
      print(updateQuery.updateQuery);
      List<Object> updateValues = values.sublist(1)..add(values[0]);
      await conn.query(updateQuery.updateQuery, updateValues);
    } catch (error) {
      throw Exception(error.toString());
    } finally {
      await conn.close();
    }
  }

  delete({required Map<String, dynamic> data}) async {
    String idField = columns.first;
    Object idValue = data[idField];
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

  static Future<List<T>> selectWithConversion<T>(
      {required String sql, required T Function(Map<String, dynamic>) fromMap}) async {
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

  // static Future<List<Map<String,dynamic>>> select() async{}

  static Future<List<Map<String, dynamic>>> selectAll({required String table}) async {
    final conn = await _mySQLManager
        .init()
        .onError((error, stackTrace) => throw Exception(error.toString()));
    List<Map<String, dynamic>> results = [];

    final res = await conn.query('select * from $table').onError((error, stackTrace) async {
      await conn.close();
      throw Exception(error);
    });
    results = res.map((e) => e.fields).toList();
    await conn.close();
    return results;
  }

  static Future<List<T>> selectAllWithConversion<T>(
      {required String table, required T Function(Map<String, dynamic>) fromMap}) async {
    final selectionList = await selectAll(table: table);
    List<T> list = [];
    for (Map<String, dynamic> map in selectionList) {
      list.add(fromMap(map));
    }
    return list;
  }

  static Future<Results> nativeQuery({required String sql}) async {
    final conn = await _mySQLManager.init();
    final results = await conn.query(sql);
    await conn.close();
    return results;
  }

  Map<String, dynamic> _createMap({required List<Object> values}) {
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

  String _generateQuery() => 'UPDATE $table SET ${_generatePreparedStatement(columns: columns)}';

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
  final List<Object> values;
  const _InsertionQuery({required this.table, required this.columns, required this.values});
  String _generateQuery() {
    if(columns.length != values.length){
      throw Exception('Columns and values must have the same number of members');
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
    List<Object> newValues = values.sublist(1);
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
