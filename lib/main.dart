import 'package:fluent_ui/fluent_ui.dart';
import 'package:firedart/firedart.dart';
import 'package:project_desktop/authentication.dart';

//firebase database bağlantısı için
const apiKey = 'AIzaSyB-kvN9Ldpzmk343X0h95tD9yxzrC9Lelg';
const projectId = 'restaurantapp-2a43d';

void main() {
  FirebaseAuth.initialize(apiKey, VolatileStore());
  Firestore.initialize(projectId);
  runApp(const WaiterApp());
}

class WaiterApp extends StatelessWidget {
  const WaiterApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const FluentApp(
      home: AuthScreen(),
    );
  }
}