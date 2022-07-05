import 'package:persister/persister.dart';
import 'package:persister/src/select_builder.dart';

void main() async {
  //sql es una forma de accder a la información de una base de datos
  final constructorSentenciaSQL = SelectBuilder(selectedTable: 'test')
      .where(field: 'id')
      .contains(values: [5, 6, 1, '0']);
  print(constructorSentenciaSQL.sql);

  print(await Persister.nativeQuery(sql: 'select * from test')
      .deserialize((map) => Test.fromMap(map)));

 final List<Test> tests =  await Persister.selectAll(table: 'test').deserialize<Test>((map){
    print(map);
    return Test.fromMap(map);
  });
  print(tests);
}


class Test {
  int id;
  String text;
  Test({required this.id, required this.text});

  static Test fromMap(Map<String,dynamic> map) => Test(id: map['id'], text: map['text']);

  @override
  String toString() => 'Test(id: $id, text: $text)';
}
