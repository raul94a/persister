import 'package:persister/persister.dart';

import 'persister_example.dart';

void main(List<String> args) async {
  Test ts = Test(text: 'test dev-simplicity');

  ts = await ts.save().deserialize((p0) {
  
  print(p0);
  return Test.fromMap(p0);

  });
  ts.text = 'test dev-simplicity is updated';
  await ts.update();
  await ts.delete();
  print(await Persister.selectAll(table: 'test').deserialize((p0) => Test.fromMap(p0)));
}
