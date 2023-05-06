import 'package:fluent_ui/fluent_ui.dart';
import 'package:firedart/firedart.dart';

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
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
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
                                title: Text(itemName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (quantitySubmittedNotServiced != 0)
                                      Text(
                                        'Not Serviced: $quantitySubmittedNotServiced',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    if (quantitySubmittedNotServiced == 0)
                                      Text(
                                          'Not Serviced: $quantitySubmittedNotServiced'),
                                    Text('Serviced: $quantityServiced'),
                                  ],
                                ),
                              ),
                              if (quantitySubmittedNotServiced != 0)
                                Button(
                                  onPressed: () {
                                    final newQuantityServiced =
                                        quantityServiced +
                                            quantitySubmittedNotServiced;
                                    const newQuantitySubmittedNotServiced = 0;
                                    document.reference.update({
                                      'quantity_Submitted_notServiced':
                                          newQuantitySubmittedNotServiced,
                                      'quantity_Submitted_Serviced':
                                          newQuantityServiced,
                                    });
                                  },
                                  child: const Text('Set as Serviced'),
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
        Container(
            color: Colors.grey, width: 1, padding: const EdgeInsets.all(8)),
        Expanded(
          child: Row(
            children: [
              RestaurantMenu(restaurantId: widget.ordersRef.split("/")[2], tableNo: widget.tableNo.toString()),
            ],
          ),
        ),
      ],
    );
  }
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({Key? key, required this.tableNo}) : super(key: key);
  final int tableNo;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Payment, adisyon, fatura vb. işlemler"),
    );
  }
}

class RestaurantMenu extends StatefulWidget {
  const RestaurantMenu({Key? key, required this.restaurantId, required this.tableNo})
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
                const Text("Search:", style: TextStyle(fontSize: 18),),
                const SizedBox(width: 8),
                Expanded(
                  child: TextBox(
                      controller: searchController, onChanged: _onSearchQueryChanged),
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
                                : Color(0xFFCDCDCD),
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
                    .collection("Restaurants/${widget.restaurantId}/MenuCategory")
                    .get().asStream(),
                builder: (BuildContext context,
                    AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: ProgressRing());
                  }

                  final categories = snapshot.data;
                  return FutureBuilder(
                    future: getItemsForAllCategories(categories),
                    builder: (BuildContext context,
                        AsyncSnapshot<List>
                        itemsSnapshot) {
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
                        collection: "Restaurants/${widget.restaurantId}/MenuCategory",
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

  const ItemsGrid({super.key,
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
                      fit: BoxFit.fitWidth,
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
                        FilledButton(child: const Text("Add to Orders"), onPressed: () async {
                          final querySnapshot = await Firestore
                              .instance
                              .collection("Restaurants/${widget.id}/Tables")
                              .document(widget.tableNo)
                              .collection("Orders")
                              .where("itemRef", isEqualTo: document.reference)
                              .get();
                          if (querySnapshot.isNotEmpty) {
                            // Item already exists in order, update its quantity
                            final orderDoc = querySnapshot.first;
                            final quantity = orderDoc[
                            "quantity_Submitted_notServiced"] + 1;
                            orderDoc.reference.update({
                              "quantity_Submitted_notServiced": quantity
                            });
                          } else {
                            // Item doesn't exist in order, add it with quantity 1
                            Firestore.instance
                                .collection("Restaurants/${widget.id}/Tables")
                                .document(widget.tableNo)
                                .collection("Orders")
                                .document(DateTime.now().toString())
                                .set({
                              "itemRef": document.reference,
                              "quantity_notSubmitted_notServiced": 0,
                              "quantity_Submitted_notServiced": 1,
                              "quantity_Submitted_Serviced": 0,
                            });
                          }
                        },),
                      ],
                    )
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}