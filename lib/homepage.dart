import 'package:firedart/firedart.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:fluent_ui/fluent_ui.dart';

class Navigation extends StatelessWidget {
  const Navigation({Key? key, required this.restaurantId}) : super(key: key);

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: NavigationView(
        appBar: NavigationAppBar(
          title: Text("Restaurant"),
        ),
        pane: NavigationPane(displayMode: PaneDisplayMode.compact, items: [
          PaneItem(
              icon: const Icon(FluentIcons.home),
              title: const Text("Home"),
              body: Home(
                restaurantID: restaurantId,
              ),),
        ]),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key, required this.restaurantID}) : super(key: key);
  final String restaurantID;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool isFirstLoading = true;

  void initState() {

    super.initState();

    final ref = Firestore.instance.collection("/Restaurants/${widget.restaurantID}/Tables");
    ref.stream.listen((document) {
      setState(() {
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder(
        stream: Firestore.instance
            .collection("/Restaurants/${widget.restaurantID}/Tables")
            .get()
            .asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && isFirstLoading) {
            isFirstLoading = false;
            return const Center(child: ProgressRing());
          } else {
            return GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              primary: false,
              shrinkWrap: true,
              children: snapshot.data!.map((document) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[50]),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: ListTile(
                    title: Text("Table ${document['number']}"),
                    onPressed: () {
                      var value = document["OrderList"];
                      print("OrderList from firebase: $value");
                    },
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}
