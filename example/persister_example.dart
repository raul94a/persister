import 'package:persister/persister.dart';
import 'package:persister/src/select_builder.dart';

void main() {
  //sql es una forma de accder a la información de una base de datos
  final constructorSentenciaSQL =
      SelectBuilder(selectedTable: 'test').where(field: 'id').contains(values: [5, 6, 1, 'ANAAAA']);
  print(constructorSentenciaSQL.sql);
}
