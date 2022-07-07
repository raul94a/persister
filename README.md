# Persister
Persister is a dependency that allows you to declare data models and make every CRUD operation in an easy way. Take a look into the example and see the power of Persister. Try it and you will not regret.

## Features

Forget about managing the MySQL connection. Provide the credentials inside a .env file, then Persister will make the
heavy lifting for you.

## Getting started

### 1. Configure a .env file at the root of your dart server application

In order to use this package is necessary to create and configure a .env file with your database credentials.
This repository has a in-built env reader that will perform the reading of this file. You can add others properties within
this file, but you will need to use a external dependency or build a reader to access them.

Database connection credentials (inside .env file):

db=YOUR_DB_NAME
host=YOUR_DB_HOST
user=YOUR_MYSQL_USER
password=YOUR_MYSQL_PASS
port=THE_PORT_WHERE_DB_IS_RUNNING

Once you have this configuration of above you can read Usage.

## Usage 
### A. Declare your models!

Persister needs you to create your own data models, which must be related to your MySql / MariaDB tables.
Here I provide an example with a dart class called Test (and which is related to a table with the same name).

It's crucial for Persister to follow these steps:
1. Extend your model with Persister< Model>
2. Declare the attributes your model will have, which should be related to your mysql table.
3. Pass the columns name to the super constructor. These columns name are, indeed, the name of the columns of your table. Here is important to <b>PASS THE PRIMARY KEY FIELD NAME AT THE FIRST POSITION OF THE COLUMNS ARRAY.</b> 
4. Pass to the super constructor the table name and if the primary key is auto incrementable or not.
5. Override values getter and fromMap method.
6. You must pass the values (the attributes of the class) <b>in the same order as the field names were passed at the columns array.</b>
7. See the example below.

```dart
class Test extends Persister<Test> {
  //id is the primary key of test table
  int id;
  String text;

  //IMPORTANT!!!!!
  //be sure to declare the id field in the first position of the columns array (inside super constructor)
  Test({this.id = -1, required this.text})
  //super constructor
  //as you see, columns will contain the field names of the table.
      : super(columns: ['id', 'text'], table: 'test', isIdAutoIncrementable: true);

  //It's not mandatory, but it will help if you have
  //this factory constructor. It will receive a map
  //and use the values inside it to generate the object.
  //You can extend this functionality to every model you declare.
  factory Test.fromMap(Map<String, dynamic> map) {
    return Test(id: map['id'], text: map['text']);
  }
  //The fromMap method will use your factory constructor in order to parse a Map to an object, Test in this case. You can use your custom fromMap function with no problem. 
  //It's mandatory to set it up. 
  @override
  Test fromMap(Map<String, dynamic> map) => Test.fromMap(map);
  Map<String, dynamic> toMap() => {'id': id, 'text': text};

  //Not necessary but maybe useful
  @override
  String toString() => 'Test(id: $id, text: $text)';

  //Mandatory to override. Pass the attributes of the class that represent the table in the exactly same order as you did
  @override
  List<dynamic> get values => [id, text];
}

```
This Test class maybe is a good template for you to create your own models

### 2. Use the power of Persister
Once you have configured the .env file and declared your models, you can use your Model to perform CRUD operations in your database. You don't have to worry about DB Connection Management. Persister will make the dirty work for you. This is the philosophy: <b>To focus in accessing and persisting data.</b>

This example will be enclosed in the main function. You can use this approach in wherever you want inside your dart server.

###### Persistence of data
With your model ander Persister extension, you can access to the methods save, update and delete to perform the persistance task. 

###### Fetching data
For selecting data, Persister has some static methods that will help you in this task. See the example below.

###### The example provides how to use save, update, delete methods from your declared classes extending Persister. Also how to use the static methods selectAll and nativeQuery from Persister.
```dart

void main() async {

  //INSERT A ROW INSIDE test TABLE
  Test test = Test(text: 'this is a new test');
  //Save method will insert the data in a row within the database. 
  //If you have passed the attribute  isAutoIncrementable = true, the autogenerated id will be returned, so the object will have this id. 
  //In order words. If the test object below is inserted with an id of 1000, it will be returned and set into this same object. You don't have to worry about this auto incrementable ids.
  test = await test
      .save();


  test.text = 'updated the new test';
  //update method will update the object inside your table
  await test.update();

  //Deleting one element. Deletes by id.
  await test.delete();

  //selecting data

  //For selecting data we use the static methods from Persister
  
  //selecting all data
  //for selecting all the data you should use Persister
  // selectAll method, which will return a List<Map<String,dynamic>>. This raw data can be parsed
  // to a List<Model> (List<Test> in this case) using concatenating this selectAll with deserialize method.
  //You have to use a function / constructor in order to parse each Map of the list into a Object.
  //As you can see in this example I am using the same Test.fromMap factory constructor I've declared in the class construction.
  List<Test> tests =
      await Persister.selectAll(table: 'test').deserialize((map) => Test.fromMap(map));


  //Using the nativeQuery
  //You can use your own sql queries with the folling static method from Persister
  //And again, deserialize allow you to easily parse the Results into a model you have defined.

  //this is a way to use prepared statements. When you use prepared statements you HAVE to pass the values array in the same order of ? aparition.
  List<Test> testsNative =
      await Persister.nativeQuery(sql: 'select * from test where id > ?', values: [5])
          .deserialize((map) => Test.fromMap(map));
 
  
  // if you do not wanna use prepared statements you can use nativeQuery in this way (same as former example)
 List<Test> testsNative2 =
      await Persister.nativeQuery(sql: 'select * from test where id > 5')
          .deserialize((map) => Test.fromMap(map));




}


```
