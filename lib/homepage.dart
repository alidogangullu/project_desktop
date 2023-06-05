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
        appBar: NavigationAppBar(
          leading: const SizedBox(),
          title: RestaurantNameText(
            restaurantId: restaurantId,
          ),
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
  var stream;

  void listenRestaurantData() {
    final ref = Firestore.instance
        .collection("/Restaurants/${widget.restaurantID}/Tables");

    //databasede değişiklik olduğunda ekranı güncellemek için
    stream = ref.stream.listen((document) {
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    listenRestaurantData();
  }

  @override
  void dispose() {
    stream.cancel;
    super.dispose();
  }

  void showNotifications(
      BuildContext context, Document document) async {
    await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('Table ${document['number']}'),
        content: Notifications(
          tableRef: document.reference.path,
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          FilledButton(
            child: const Text('Mark as read'),
            onPressed: () async {
              await document.reference.update({
                'newNotification': false,
                'notifications': [],
              });
              Navigator.pop(context);
            },
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              isFirstLoading) {
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
                Color getBorderColor() {
                  if (!document['users'].isEmpty) {
                    return Colors.green;
                  } else if (!document['unAuthorizedUsers'].isEmpty){
                    return Colors.red;
                  } else {
                    return Colors.grey[50];
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: getBorderColor(),
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if(!document['unAuthorizedUsers'].isEmpty && document['users'].isEmpty)
                          IconButton(
                            icon: const Icon(FluentIcons.accept, size: 24),
                            onPressed: () async {
                              final unAuthUserIds = List<String>.from(document['unAuthorizedUsers']);
                              final users = List<String>.from(document['users']);
                              users.add("${unAuthUserIds.first}-admin");
                              unAuthUserIds.removeAt(0);
                              await document.reference
                                  .update({
                                'users': users,
                                'unAuthorizedUsers': unAuthUserIds,
                                  });
                            },
                          ),
                          IconButton(
                            icon: Icon(document['newNotification']
                                ? FluentIcons.ringer_active
                                : FluentIcons.ringer, size: 24,),
                            onPressed: () {
                              showNotifications(
                                context,
                                document,
                              );
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListTile(
                          onPressed: () {
                            Navigator.push(
                              context,
                              FluentPageRoute(
                                builder: (context) => TableManagementPage(
                                  tableNo: document['number'],
                                  ordersRef:
                                  "/Restaurants/${widget.restaurantID}/Tables/${document['number']}/Orders",
                                ),
                              ),
                            );
                          },
                          title: Text(
                            "Table ${document['number']}",
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ],
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
  const Notifications({Key? key, required this.tableRef}) : super(key: key);

  final String tableRef;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Firestore.instance.document(tableRef).get().asStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 50,child: Center(child: ProgressRing()));
        }
        final data = snapshot.data!;
        final notifications = data['notifications'] as List<dynamic>;
        if (notifications.isEmpty) {
          return const Text("No notifications");
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Notifications:", style: TextStyle(fontSize: 20),),
              const SizedBox(height: 8),
              for (final notification in notifications) ...[
                Text("- $notification", style: const TextStyle(fontSize: 18),),
                const SizedBox(height: 4),
              ],
            ],
          ),
        );
      },
    );
  }
}

class RestaurantNameText extends StatelessWidget {
  const RestaurantNameText({Key? key, required this.restaurantId})
      : super(key: key);
  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firestore.instance
          .collection('Restaurants')
          .document(restaurantId)
          .get(),
      builder: (BuildContext context, restaurantSnapshot) {
        if (restaurantSnapshot.hasError ||
            restaurantSnapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading...");
        }
        final restaurantName = restaurantSnapshot.data!['name'] as String;
        return Text(restaurantName, style: const TextStyle(fontSize: 24),);
      },
    );
  }
}