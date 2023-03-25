import 'package:firedart/firedart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:project_desktop/table_page.dart';

class Navigation extends StatelessWidget {
  const Navigation({Key? key, required this.restaurantId}) : super(key: key);

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: NavigationView(
        appBar: const NavigationAppBar(
          leading: Text(""),
          title:
              Text("Restaurant"), //todo girilen restoranta özel değişen başlık
        ),
        pane: NavigationPane(displayMode: PaneDisplayMode.compact, items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text("Home"),
            body: Home(
              restaurantID: restaurantId,
            ),
          ),
          //todo yeni sekmeler
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

  void listenRestaurantData() {
    final ref = Firestore.instance
        .collection("/Restaurants/${widget.restaurantID}/Tables");

    //databasede değişiklik olduğunda ekranı güncellemek için
    ref.stream.listen((document) {
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    listenRestaurantData();
  }

  void showNotifications(BuildContext context, int number, Document document) async {
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('Table $number'),
        content: const Notifications(),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          FilledButton(
              child: const Text('Okey'),
              onPressed: () async {
                await document.reference.update({'newNotification' : false});
                Navigator.pop(context);
              }
          ),
        ],
      ),
    );
    setState(() {});
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
                //masa listeleme
                //todo masa için sipariş listesi, hesap, süre vb özellikler
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[50]),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: ListTile(
                    title: Center(child: Text("Table ${document['number']}")),
                    onPressed: () {
                      Navigator.push(
                        context,
                        FluentPageRoute(builder: (context) => TableManagementPage(tableNo: document['number']),),
                      );
                    },
                    subtitle: Center(
                      child: IconButton(
                        icon: Icon(document['newNotification'] ? FluentIcons.ringer_active : FluentIcons.ringer),
                        onPressed: () {
                          showNotifications(context, document['number'], document);
                        },
                      ),),
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

class Notifications extends StatelessWidget {
  const Notifications({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text("new order, garson çağırma, hesap isteme, login isteği vb. bildirimler");
  }
}
