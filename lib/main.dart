import 'package:fluent_ui/fluent_ui.dart';
import 'package:firedart/firedart.dart';

const apiKey = 'AIzaSyB-kvN9Ldpzmk343X0h95tD9yxzrC9Lelg';
const projectId = 'restaurantapp-2a43d';

void main() {
  Firestore.initialize(projectId);
  runApp(const FireStoreApp());
}

class FireStoreApp extends StatelessWidget {
  const FireStoreApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const FluentApp(
      title: 'Cloud Firestore Windows',
      home: FireStoreHome(),
    );
  }
}

class FireStoreHome extends StatefulWidget {
  const FireStoreHome({Key? key}) : super(key: key);

  @override
  _FireStoreHomeState createState() => _FireStoreHomeState();
}

class _FireStoreHomeState extends State<FireStoreHome> {
  CollectionReference collection = Firestore.instance.collection("users");
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Button(
              child: const Text('List Groceries'),
              onPressed: () async {
                final users = await collection.get();

                print(users);
              },
            ),
          ],
        ),
      ),
    );
  }
}
