<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->
Persister is a dependency that allows you to declare a model and make every CRUD operation in an easy way. Take a look into the example
and see the power of Persister. Try it and you will not regret.

## Features

Forget about managing the MySQL connection. Provide the credentials inside a .env file, then Persister will make the
heavy lifting for you.

## Getting started

IT'S NEEDED TO CREATE A .env file at your app root. At least it needs this properties:

db=YOUR_DB_NAME
host=YOUR_DB_HOST
user=YOUR_MYSQL_USER
password=YOUR_MYSQL_PASS
port=THE_PORT_WHERE_DB_IS_RUNNING

Once you have this configuration of above you can read Usage.

## Usage 

```dart
import 'package:persister/persister.dart';

//This is a sample class using Persister.
//Though the order of the attributes of a class does not matter,
//It's very important to define the primary key fieldname at the first position of columns array, within super constructor
//Also, you have to define the primary key value at the first position of the values getter array.

//IMPORTANT
//values and columns need to have the same order. This mean they have to be related by position
//for example if I had:
// values: [1, 'Raul']
// columns: ['id', 'name']
// the first position (0) of both arrays corresponds to the fieldname id and the value 1.
// the second position (1) corresponds to fieldname 'name' and value 'raul'.
//You have to respect the order. Maybe in  the future the arrays're being replaced by a Map...

//So, the super construction will have METADATA about the TABLE: NAME, FIELDNAME and if the pk field is AUTOINCREMENTABLE
//you have to
class Test extends Persister<Test> {
  //id is the primary key of test table
  int id;
  String text;
  //IMPORTANT!!!!!
  //be sure to declare the id field in the first position of the columns array
  Test({this.id = -1, required this.text})
      : super(
            columns: ['id', 'text'],
            table: 'test',
            isIdAutoIncrementable: true);

  //fromMap and toMap methods, you maybe want to implement then!
  static Test fromMap(Map<String, dynamic> map) =>
      Test(id: map['id'], text: map['text']);
  Map<String, dynamic> toMap() => {'id': id, 'text': text};

  @override
  String toString() => 'Test(id: $id, text: $text)';

  @override
  //IMPORTANT!!!!!!
  //be sure to declare de id value in the first position of the values array
  List<dynamic> get values => [id, text];
}

//Now we have prepared the model let's start with the use of this pacakge, but first there's one thing you have to do
//As this library uses mysql_manager dependency, written also by me, you need to configure the .env file at the root of your
//project. This .env file can contain the properties you desire. However the following are needed in order to connect to your
//mysql

// db=YOUR_DB_NAME
// host=YOUR_DB_HOST
// user=YOUR_MYSQL_USER
// password=YOUR_MYSQL_PASS
// port=THE_PORT_WHERE_DB_IS_RUNNING

//WHEN THIS .env file is well configured you can use Persister as shown within main function.
void main() async {
  //INSERT A ROW INSIDE test TABLE
  Test test = Test(text: 'this is a new test');
  //save method will return a Map<String,dynamic>. You can concatenate this with deserialize()
  //In order to parse this Map into a Test object (or the Model you are using with Persister)
  //AutoIncrementable primary keys will be returned with the save method.
  test = await test
      .save(values: test.values)
      .deserialize((map) => Test.fromMap(map));

  //Using toMap method updates the data of the correct row inside your db.
  test.text = 'updated the new test';
  await test.update(data: test.toMap());

  //selecting data
  //For selecting data we use the static methods from Persister
  //Again, deserialize will return a callback containin every fetched row as a Map. You can use
  // that map in order to parse the data directly to a List of Models you're using.

  //Deleting one element
  await test.delete(data: test.toMap());

  //Using the nativeQuery
  //You can use your own sql queries with the folling static method from Persister
  //And again, deserialize allow you to easily parse the Results into a model you have defined.
  List<Test> testsNative =
      await Persister.nativeQuery(sql: 'select * from test')
          .deserialize((map) => Test.fromMap(map));
  print(testsNative);
}

```
