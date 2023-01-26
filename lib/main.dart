import 'package:fluent_ui/fluent_ui.dart';
import 'package:firedart/firedart.dart';
import 'package:flutter/material.dart';
import 'package:project_desktop/homepage.dart';

const apiKey = 'AIzaSyB-kvN9Ldpzmk343X0h95tD9yxzrC9Lelg';
const projectId = 'restaurantapp-2a43d';

void main() {
  Firestore.initialize(projectId);
  runApp(const WaiterApp());
}

class WaiterApp extends StatelessWidget {
  const WaiterApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Restaurant Name',
      home: LoginRestaurant(),
    );
  }
}

class LoginRestaurant extends StatefulWidget {
  const LoginRestaurant({Key? key}) : super(key: key);

  @override
  _LoginRestaurantState createState() => _LoginRestaurantState();
}

class _LoginRestaurantState extends State<LoginRestaurant> {

  CollectionReference collection = Firestore.instance.collection("Restaurants");
  TextEditingController restaurantID = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          child: TextBox(
            header: 'Enter Restaurant ID',
            placeholder: 'id',
            expands: false,
            controller: restaurantID,
          ),
        ),
        Button(
          child: const Text('Login'),
          onPressed: () async {
            final restaurant = await collection.document(restaurantID.text).get();

            if(restaurant!=null){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Navigation(restaurantId: restaurant.id)),
              );
            }
          },
        ),
      ],
    );
  }
}
