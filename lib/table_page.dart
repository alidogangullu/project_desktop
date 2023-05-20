import 'package:fluent_ui/fluent_ui.dart';
import 'package:firedart/firedart.dart';
import 'package:intl/intl.dart';

class TableManagementPage extends StatefulWidget {
  const TableManagementPage(
      {Key? key, required this.tableNo, required this.ordersRef})
      : super(key: key);
  final String ordersRef;
  final int tableNo;

  @override
  State<TableManagementPage> createState() => _TableManagementPageState();
}

class _TableManagementPageState extends State<TableManagementPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: NavigationView(
        appBar: NavigationAppBar(
          leading: IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text("Table ${widget.tableNo}"),
        ),
        pane: NavigationPane(
            selected: index,
            displayMode: PaneDisplayMode.top,
            items: [
              PaneItem(
                  icon: const Icon(FluentIcons.list),
                  title: const Text("Orders"),
                  body: TablePage(
                      tableNo: widget.tableNo, ordersRef: widget.ordersRef),
                  onTap: () {
                    setState(() {
                      index = 0;
                    });
                  }),
              PaneItem(
                  icon: const Icon(FluentIcons.payment_card),
                  title: const Text("Payment"),
                  body: PaymentPage(
                    tableNo: widget.tableNo,
                    ordersRef: widget.ordersRef,
                  ),
                  onTap: () {
                    setState(() {
                      index = 1;
                    });
                  }),
            ]),
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key, required this.tableNo, required this.ordersRef})
      : super(key: key);
  final int tableNo;
  final String ordersRef;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isFirstLoading = true;
  double totalAmount = 0.0;

  void listenRestaurantData() {
    final ref = Firestore.instance.collection(widget.ordersRef);

    ref.stream.listen((document) {
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    calculateTotalAmount();
    listenRestaurantData();
  }

  void calculateTotalAmount() {
    totalAmount = 0.0;
    final ref = Firestore.instance.collection(widget.ordersRef);

    ref.get().then((querySnapshot) {
      if (!mounted) return;
      final documents = querySnapshot;
      final filteredDocuments = documents.where((document) {
        final quantitySubmittedNotServiced =
        document['quantity_Submitted_notServiced'] as int;
        final quantityServiced =
        document['quantity_Submitted_Serviced'] as int;
        return quantitySubmittedNotServiced != 0 || quantityServiced != 0;
      }).toList();

      filteredDocuments.forEach((document) async {
        if (!mounted) return;
        final itemRef = document['itemRef'] as DocumentReference;
        final quantitySubmittedNotServiced =
        document['quantity_Submitted_notServiced'] as int;
        final quantityServiced = document['quantity_Submitted_Serviced'] as int;
        final totalQuantity = quantityServiced + quantitySubmittedNotServiced;

        final itemSnapshot = await itemRef.get();
        final itemPrice = itemSnapshot['price'];
        final itemTotalPrice = totalQuantity * itemPrice;

        if (!mounted) return;
        setState(() {
          totalAmount += itemTotalPrice;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Table ${widget.tableNo}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy h:mm a').format(
                              DateTime.now()),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder(
                      stream: Firestore.instance
                          .collection(widget.ordersRef)
                          .get()
                          .asStream(),
                      builder: (BuildContext context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                            isFirstLoading) {
                          isFirstLoading = false;
                          return const Center(child: ProgressRing());
                        }
                        final documents = snapshot.data!;
                        final filteredDocuments = documents.where((document) {
                          final quantitySubmittedNotServiced =
                          document['quantity_Submitted_notServiced'] as int;
                          final quantityServiced =
                          document['quantity_Submitted_Serviced'] as int;
                          return quantitySubmittedNotServiced != 0 ||
                              quantityServiced != 0;
                        }).toList();

                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: ListView.builder(
                            primary: false,
                            shrinkWrap: true,
                            itemCount: filteredDocuments.length,
                            itemBuilder: (BuildContext context, int index) {
                              final document = filteredDocuments[index];
                              final itemRef =
                              document['itemRef'] as DocumentReference;
                              final quantitySubmittedNotServiced =
                              document['quantity_Submitted_notServiced']
                              as int;
                              final quantityServiced =
                              document['quantity_Submitted_Serviced']
                              as int;
                              final totalQuantity = quantityServiced +
                                  quantitySubmittedNotServiced;
                              return FutureBuilder(
                                future: itemRef.get(),
                                builder: (BuildContext context, itemSnapshot) {
                                  if (itemSnapshot.hasError ||
                                      itemSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                    return const SizedBox();
                                  }

                                  final itemName =
                                  itemSnapshot.data!['name'] as String;
                                  final itemPrice = itemSnapshot.data!['price'];
                                  final itemTotalPrice =
                                      totalQuantity * itemPrice;

                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('$itemName (${totalQuantity}x)'),
                                        Text(
                                          '\$${itemTotalPrice.toStringAsFixed(
                                              2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Payment Options',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    // handle collecting payment by card
                  },
                  child: const Text('Collect Payment by Card'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    // handle collecting payment in cash
                  },
                  child: const Text('Collect Payment in Cash'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    // handle printing receipt
                  },
                  child: const Text('Print Receipt'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



    class TablePage extends StatefulWidget {
  const TablePage({Key? key, required this.tableNo, required this.ordersRef})
      : super(key: key);
  final int tableNo;
  final String ordersRef;

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  bool isFirstLoading = true;

  void listenRestaurantData() {
    final ref = Firestore.instance.collection(widget.ordersRef);

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

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StreamBuilder(
            stream: Firestore.instance
                .collection(widget.ordersRef)
                .get()
                .asStream(),
            builder: (BuildContext context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  isFirstLoading) {
                isFirstLoading == false;
                return const Center(child: ProgressRing());
              }
              final documents = snapshot.data!;
              final filteredDocuments = documents.where((document) {
                final quantitySubmittedNotServiced =
                    document['quantity_Submitted_notServiced'] as int;
                final quantityServiced =
                    document['quantity_Submitted_Serviced'] as int;
                return quantitySubmittedNotServiced != 0 ||
                    quantityServiced != 0;
              }).toList();
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.88,
                  ),
                  primary: false,
                  shrinkWrap: true,
                  itemCount: filteredDocuments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final document = filteredDocuments[index];
                    final itemRef = document['itemRef'] as DocumentReference;
                    final quantitySubmittedNotServiced =
                        document['quantity_Submitted_notServiced'] as int;
                    final quantityServiced =
                        document['quantity_Submitted_Serviced'] as int;
                    return FutureBuilder(
                      future: itemRef.get(),
                      builder: (BuildContext context, itemSnapshot) {
                        if (itemSnapshot.hasError ||
                            itemSnapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const SizedBox();
                        }
                        final itemName = itemSnapshot.data!['name'] as String;
                        return Card(
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  itemName,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      color: Colors.grey,
                                      width: double.infinity,
                                      height: 2,
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    if (quantitySubmittedNotServiced != 0)
                                      Column(
                                        children: [
                                          Text(
                                            'Not Serviced: $quantitySubmittedNotServiced',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.red),
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          FilledButton(
                                            child: const Text("Reduce Amount"),
                                            onPressed: () {
                                              if (quantitySubmittedNotServiced !=
                                                  0) {
                                                final newQuantitySubmittedNotServiced =
                                                    quantitySubmittedNotServiced -
                                                        1;
                                                document.reference.update({
                                                  'quantity_Submitted_notServiced':
                                                      newQuantitySubmittedNotServiced,
                                                  if (newQuantitySubmittedNotServiced==0)
                                                    'orderedTime': 0,
                                                });
                                              }
                                            },
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          FilledButton(
                                            onPressed: () async {
                                              final newQuantityServiced =
                                                  quantityServiced +
                                                      quantitySubmittedNotServiced;
                                              const newQuantitySubmittedNotServiced =
                                                  0;

                                              final orderedTime = document['orderedTime'];
                                              final servicedTime = DateTime.now();

                                              final difference = servicedTime.difference(orderedTime);
                                              final calculatedTime = difference.inSeconds ~/ quantitySubmittedNotServiced;

                                              var itemDoc = await itemRef.get();
                                              final orderCount = await itemDoc["orderCount"];
                                              final estimatedTime = await itemDoc["estimatedTime"];

                                              final totalTime = estimatedTime*orderCount;
                                              final newEstimatedTime = (totalTime+calculatedTime)/(orderCount+quantitySubmittedNotServiced);

                                              await itemRef.update({
                                                "orderCount": orderCount+quantitySubmittedNotServiced,
                                                "estimatedTime": newEstimatedTime,
                                              });

                                              await document.reference.update({
                                                'quantity_Submitted_notServiced':
                                                newQuantitySubmittedNotServiced,
                                                'quantity_Submitted_Serviced':
                                                newQuantityServiced,
                                                'orderedTime': 0,
                                              });

                                            },
                                            child:
                                                const Text('Set as Serviced'),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    if (quantitySubmittedNotServiced == 0)
                                      Text(
                                        'Not Serviced: $quantitySubmittedNotServiced',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    Text(
                                      'Serviced: $quantityServiced',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              FilledButton(
                                onPressed: () {
                                  document.reference.delete();
                                },
                                child: const Text("Delete All"),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        Container(
            color: Colors.grey, width: 1, padding: const EdgeInsets.all(8)),
        Expanded(
          child: Row(
            children: [
              RestaurantMenu(
                  restaurantId: widget.ordersRef.split("/")[2],
                  tableNo: widget.tableNo.toString()),
            ],
          ),
        ),
      ],
    );
  }
}

class RestaurantMenu extends StatefulWidget {
  const RestaurantMenu(
      {Key? key, required this.restaurantId, required this.tableNo})
      : super(key: key);
  final String restaurantId;
  final String tableNo;

  @override
  State<RestaurantMenu> createState() => _RestaurantMenuState();
}

class _RestaurantMenuState extends State<RestaurantMenu> {
  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  String selected = "";
  String _searchQuery = '';
  final searchController = TextEditingController();

  Future<List> getItemsForAllCategories(List categories) async {
    List allDocuments = [];
    for (var doc in categories) {
      final items = await Firestore.instance
          .collection(
              'Restaurants/${widget.restaurantId}/MenuCategory/${doc.id}/list')
          .get();
      allDocuments.addAll(items);
    }
    return allDocuments;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Text(
                  "Search:",
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextBox(
                      controller: searchController,
                      onChanged: _onSearchQueryChanged),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 5, 0, 0),
            child: SizedBox(
              height: 35,
              child: StreamBuilder(
                stream: Firestore.instance
                    .collection(
                        "Restaurants/${widget.restaurantId}/MenuCategory")
                    .get()
                    .asStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading categories...');
                  }
                  final categories =
                      snapshot.data!.map((doc) => doc.id).toList();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () => setState(() => selected == category
                            ? selected = ''
                            : selected = category),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selected == category
                                ? Colors.blue
                                : const Color(0xFFCDCDCD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: selected == category
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
              child: StreamBuilder(
                stream: Firestore.instance
                    .collection(
                        "Restaurants/${widget.restaurantId}/MenuCategory")
                    .get()
                    .asStream(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: ProgressRing());
                  }

                  final categories = snapshot.data;
                  return FutureBuilder(
                    future: getItemsForAllCategories(categories),
                    builder: (BuildContext context,
                        AsyncSnapshot<List> itemsSnapshot) {
                      if (itemsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: ProgressRing());
                      }
                      final items = itemsSnapshot.data!;
                      final visibleItems = selected.isEmpty
                          ? items
                          : items
                              .where((item) => item.reference.path.startsWith(
                                  'Restaurants/${widget.restaurantId}/MenuCategory/$selected'))
                              .toList();
                      final filteredItems = visibleItems.where((item) {
                        final name = item['name'].toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();
                      return ItemsGrid(
                        documents: filteredItems,
                        collection:
                            "Restaurants/${widget.restaurantId}/MenuCategory",
                        context: context,
                        id: widget.restaurantId,
                        selected: selected,
                        tableNo: widget.tableNo,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemsGrid extends StatefulWidget {
  final List documents;
  final dynamic context;
  final dynamic selected;
  final String collection;
  final String id;
  final String tableNo;

  const ItemsGrid({
    super.key,
    required this.documents,
    required this.context,
    required this.selected,
    required this.collection,
    required this.id,
    required this.tableNo,
  });

  @override
  _ItemsGridState createState() => _ItemsGridState();
}

class _ItemsGridState extends State<ItemsGrid> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      childAspectRatio: 0.65,
      children: widget.documents.map((document) {
        return GestureDetector(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: Image.network(
                      document["image_url"],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      document['name'],
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    child: Text(
                      "\$ ${document['price']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(7.5, 0, 5, 0),
                      child: Row(
                        children: [
                          FilledButton(
                            child: const Text("Add to Orders"),
                            onPressed: () async {

                              var table = await Firestore.instance.document("Restaurants/${widget.id}/Tables/${widget.tableNo}").get();
                              List users =  List.from(table['users']);
                              if(users.isEmpty){
                                users.add("waiter");
                                Firestore.instance.document("Restaurants/${widget.id}/Tables/${widget.tableNo}").update({
                                  "users" : users,
                                });
                              }

                              final querySnapshot = await Firestore.instance
                                  .collection("Restaurants/${widget.id}/Tables")
                                  .document(widget.tableNo)
                                  .collection("Orders")
                                  .where("itemRef",
                                      isEqualTo: document.reference)
                                  .get();
                              if (querySnapshot.isNotEmpty) {
                                // Item already exists in order, update its quantity
                                final orderDoc = querySnapshot.first;
                                final oldQuantity = orderDoc["quantity_Submitted_notServiced"];
                                final quantity =
                                    oldQuantity +
                                        1;
                                orderDoc.reference.update({
                                  "quantity_Submitted_notServiced": quantity,
                                  if(oldQuantity==0) "orderedTime": DateTime.now(),
                                });
                              } else {
                                // Item doesn't exist in order, add it with quantity 1
                                Firestore.instance
                                    .collection(
                                        "Restaurants/${widget.id}/Tables")
                                    .document(widget.tableNo)
                                    .collection("Orders")
                                    .document(DateTime.now().toString())
                                    .set({
                                  "itemRef": document.reference,
                                  "quantity_notSubmitted_notServiced": 0,
                                  "quantity_Submitted_notServiced": 1,
                                  "quantity_Submitted_Serviced": 0,
                                  "orderedTime": DateTime.now(),
                                });
                              }
                            },
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
