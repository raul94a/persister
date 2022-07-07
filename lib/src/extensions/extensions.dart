// ignore_for_file: avoid_shadowing_type_parameters

import 'package:mysql_manager/mysql_manager.dart' show Results;


extension ResultsParser<T> on Future<Results> {
  Future<List<Map<String, dynamic>>> toList() {
    return then((value) => value.map((e) => e.fields).toList());
  }
///deserialize will return a List of objects. To make it work you have to declare into your model a fromMap method that returns
///an Object. Here's an example on how to to it.
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
///
/// USING DESERIALIZE
///
/// void main() async {
///   final tests = await Persister.selectAll(table:'test').deserialize((map) => Test.fromMap(map));
/// }
///```
  Future<List<T>> deserialize<T>(
      T Function(Map<String, dynamic> map) fromMap) async {
    return (await toList()).map((e) => fromMap(e)).toList();
  }
}


extension JsonListDeserializer<T> on Future<List<Map<String, dynamic>>> {
  ///deserialize will return a List of objects. To make it work you have to declare into your model a fromMap method that returns
///an Object. Here's an example on how to to it.
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
///
/// USING DESERIALIZE
///
/// void main() async {
///   final tests = await Persister.selectAll(table:'test').deserialize((map) => Test.fromMap(map));
/// }
///```
  Future<List<T>> deserialize<T>(
      T Function(Map<String, dynamic>) fromMap) async {
    final list = await this;
    return list.map((e) => fromMap(e)).toList();
  }
}

extension JsonDeserializer<T> on Future<Map<String, dynamic>> {
  Future<T> deserialize<T>(T Function(Map<String, dynamic>) fromMap) async =>
      fromMap(await this);
}

extension ListConcatenation<T> on List<T> {
  String concatenate({String separator = ','}) {
    String s = '';
    int length = this.length;
    for (int i = 0; i < length; i++) {
      dynamic currentValue = this[i];
      bool isString = isValueAString(index: i);
      s += i < length - 1
          ? '${isString ? '"$currentValue",' : currentValue},'
          : '${isString ? '"$currentValue"' : currentValue}';
    }
    return s;
  }

  bool isValueAString({required int index}) {
    return this[index] is String;
  }
}
