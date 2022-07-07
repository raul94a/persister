///[persister] is a library that will make the construction of your dart server
///a better experience. With only a .env file that must be placed at the root of your
///application, Persister will manage under the hood the connection to your MySQL / MariaDB database,
///opening and closing it when it is necessary.
///
///This dependency is thought to be used to persist data in an easy way.
///Build your REST API and deserialize / serialize the data on demand, without thinking
///about managing your database connection.

library persister;

export 'src/persister_base.dart';
export 'package:mysql_manager/mysql_manager.dart';
export 'src/extensions/extensions.dart';
