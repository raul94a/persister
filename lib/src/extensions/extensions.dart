// ignore_for_file: avoid_shadowing_type_parameters

import 'package:mysql_manager/mysql_manager.dart' show Results;

extension ResultsParser<T> on Future<Results> {
  Future<List<Map<String, dynamic>>> toList() {
  
    return then((value) => value.map((e) => e.fields).toList());
  }

  Future<List<T>> deserialize<T>(T Function(Map<String, dynamic> map) fromMap) async {
    return (await toList()).map((e) => fromMap(e)).toList();
  }
}

extension JsonListDeserializer<T> on Future<List<Map<String, dynamic>>> {
  Future<List<T>> deserialize<T>(T Function(Map<String, dynamic>) fromMap) async {
    final list = await this;
    return list.map((e) => fromMap(e)).toList();
  }
}

extension JsonDeserializer<T> on Future<Map<String, dynamic>> {
  Future<T> deserialize<T>(T Function(Map<String, dynamic>) fromMap) async => fromMap(await this);
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