import 'package:firedart/firedart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:project_desktop/table_page.dart';
import 'package:intl/intl.dart';


class Navigation extends StatefulWidget {
  const Navigation({Key? key, required this.restaurantId}) : super(key: key);

  final String restaurantId;

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: NavigationView(
        appBar: NavigationAppBar(
          leading: const SizedBox(),
          title: RestaurantNameText(
            restaurantId: widget.restaurantId,
          ),
        ),
        pane: NavigationPane(
            selected: index,
            onChanged: (newIndex){
              setState(() {
                index = newIndex;
              });
            },
            displayMode: PaneDisplayMode.compact,
            items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text("Home"),
            body: Home(
              restaurantID: widget.restaurantId,
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.timer),
            title: const Text("Orders"),
            body: SubmittedNotServicedOrders(
              restaurantID: widget.restaurantId,
            ),
          ),
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
                          if(!document['unAuthorizedUsers'].isEmpty || !document['users'].isEmpty)
                            IconButton(
                              icon: const Icon(FluentIcons.cancel, size: 24),
                              onPressed: () async {
                                final tableOrdersRef = document.reference.collection('Orders');
                                final tableOrdersSnapshot = await tableOrdersRef.get();

                                //reset table
                                await document.reference.update({
                                  'users': [],
                                  'unAuthorizedUsers': [],
                                  'newNotification': false,
                                  'notifications': [],
                                });
                                for (final orderSnapshot in tableOrdersSnapshot) {
                                  await tableOrdersRef
                                      .document(orderSnapshot.id)
                                      .delete(); // Delete from table orders
                                }
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

class SubmittedNotServicedOrders extends StatefulWidget {
  final String restaurantID;

  const SubmittedNotServicedOrders({super.key, required this.restaurantID});

  @override
  SubmittedNotServicedOrdersState createState() =>
      SubmittedNotServicedOrdersState();
}

class SubmittedNotServicedOrdersState
    extends State<SubmittedNotServicedOrders> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Firestore.instance
          .collection("/Restaurants/${widget.restaurantID}/Tables")
          .get().asStream(),
      builder: (context, tableSnapshot) {
        if (!tableSnapshot.hasData) {
          return const Center(child: ProgressRing());
        }

        return ListView.builder(
          itemCount: tableSnapshot.data!.length,
          itemBuilder: (context, index) {
            var tableDoc = tableSnapshot.data![index];

            return StreamBuilder(
              stream: tableDoc.reference.collection('Orders')
                  .get().asStream(),
              builder: (context, orderSnapshot) {
                if (!orderSnapshot.hasData) {
                  return const SizedBox();
                }

                return Column(
                  children: orderSnapshot.data!.map((orderDoc) {
                    if (orderDoc['quantity_Submitted_notServiced'] > 0) {
                      return FutureBuilder(
                        future: Firestore.instance
                            .document(orderDoc['itemRef'].toString().split(": ").last)
                            .get(),
                        builder: (context, itemSnapshot) {
                          if (!itemSnapshot.hasData) {
                            return const SizedBox();
                          }
                          DateTime orderedDateTime = orderDoc['orderedTime'];
                          String formattedOrderedTime = DateFormat.yMd().add_jm().format(orderedDateTime);

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              child: ListTile(
                                title: Text(
                                    'Table ${tableDoc['number']} - ${itemSnapshot.data!['name']}'),
                                subtitle: Text(
                                    'Quantity: ${orderDoc['quantity_Submitted_notServiced']} - Ordered Time: $formattedOrderedTime'),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }).toList(),
                );
              },
            );
          },
        );
      },
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