//query
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
