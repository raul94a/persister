//query
import 'package:persister/src/extensions/extensions.dart';

///[SelectBuilder] is under construction. If you know something about codeigniter, there exists something called
///queryBuilder which is used for query construction.
///[SelectBuilder] is something like that but with only select sentences. You can concatenate the methods provided by
///SelectBuilder class and create easily, almost without knowing sql, a select query.
class SelectBuilder {
  String _sql = '';

  String get sql => _sql;

  SelectBuilder({required String selectedTable}) {
    _sql = 'select * from $selectedTable ';
  }

  SelectBuilder where({required String field}) {
    _sql += 'WHERE $field ';
    return this;
  }

  SelectBuilder isGreater({required Object value}) {
    _sql += '> ${value.toString()} ';
    return this;
  }

  SelectBuilder isGreaterOrEqual({required Object value}) {
    _sql += '>= ${value.toString()} ';
    return this;
  }

  SelectBuilder isLess({required Object value}) {
    _sql += '< ${value.toString()} ';
    return this;
  }

  SelectBuilder isLessOrEqual({required Object value}) {
    _sql += '<= ${value.toString()} ';
    return this;
  }

  SelectBuilder equalTo({required Object value}) {
    bool isValueAString = value is String;
    if (isValueAString) {
      _sql += '= "${value.toString()}" ';
    } else {
      _sql += '= ${value.toString()} ';
    }
    return this;
  }

  SelectBuilder notEqualTo({required Object value}) {
    bool isValueAString = value is String;
    if (isValueAString) {
      _sql += '!= "${value.toString()}" ';
    } else {
      _sql += '!= ${value.toString()} ';
    }
    return this;
  }

  SelectBuilder get and {
    _sql += 'and ';
    return this;
  }

  SelectBuilder get or {
    _sql += 'or ';
    return this;
  }

  SelectBuilder contains({required List<Object> values}) {
    _sql += 'in (${values.concatenate()}) ';
    return this;
  }
}
