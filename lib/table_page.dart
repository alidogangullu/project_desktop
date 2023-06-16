import 'package:fluent_ui/fluent_ui.dart';
import 'package:firedart/firedart.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:project_desktop/homepage.dart';

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
  DateTime receiptTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    calculateTotalAmount();
    listenRestaurantData();
  }

  void listenRestaurantData() {
    final ref = Firestore.instance.collection(widget.ordersRef);

    ref.stream.listen((document) {
      setState(() {});
    });
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
        final quantityServiced = document['quantity_Submitted_Serviced'] as int;
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

  Future<void> receiptDesign(NetworkPrinter printer) async {
    //todo get these variables from firestore
    String restaurantName = 'test';
    String addressLine1 = 'test';
    String addressLine2 = 'test';
    List orderList = [];

    // Print image
    //final ByteData data = await rootBundle.load('assets/rabbit_black.jpg');
    //final Uint8List bytes = data.buffer.asUint8List();
    //final Image image = decodeImage(bytes);
    //printer.image(image);

    printer.text(restaurantName,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    printer.text(addressLine1, styles: const PosStyles(align: PosAlign.center));
    printer.text(addressLine2, styles: const PosStyles(align: PosAlign.center));
    //printer.text('Tel: 830-221-1234',
    //styles: PosStyles(align: PosAlign.center));
    //printer.text('Web: www.example.com',
    //styles: PosStyles(align: PosAlign.center), linesAfter: 1);

    printer.hr();

    printer.row([
      PosColumn(text: 'Qty', width: 1),
      PosColumn(text: 'Item', width: 7),
      PosColumn(
          text: 'Price',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
      PosColumn(
          text: 'Total',
          width: 2,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    orderList.forEach((element) {
      printer.row([
        PosColumn(text: '2', width: 1),
        PosColumn(text: 'ONION RINGS', width: 7),
        PosColumn(
            text: '0.99',
            width: 2,
            styles: const PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '1.98',
            width: 2,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    });

    printer.hr();

    printer.row([
      PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
      PosColumn(
          text: totalAmount.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )),
    ]);

    printer.hr(ch: '=', linesAfter: 1);

    printer.feed(2);
    printer.text('Thank you!',
        styles: const PosStyles(align: PosAlign.center, bold: true));

    final formatter = DateFormat('MM/dd/yyyy H:m');
    final String timestamp = formatter.format(receiptTime);
    printer.text(timestamp,
        styles: const PosStyles(align: PosAlign.center), linesAfter: 2);

    printer.feed(1);
    printer.cut();
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
                          DateFormat('MMM d, yyyy h:mm a').format(receiptTime),
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
                                          '\$${itemTotalPrice.toStringAsFixed(2)}',
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
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final usersRef = Firestore.instance.collection('users');
                    final String restaurantID = widget.ordersRef.split('/')[2];
                    final tableRef = Firestore.instance
                        .collection("Restaurants/$restaurantID/Tables")
                        .document(widget.tableNo.toString());

                    // Get the list of user IDs from the table.
                    final tableSnapshot = await tableRef.get();
                    final userIds = List<String>.from(tableSnapshot['users']);

                    for (final userID in userIds) {
                      // Get a reference to the orders collection for this table.
                      final tableOrdersRef = tableRef.collection('Orders');
                      final restaurantRef = Firestore.instance
                          .collection("Restaurants")
                          .document(restaurantID);

                      // Loop through the orders for this table and transfer them to the user's orders collection.
                      final tableOrdersSnapshot = await tableOrdersRef.get();

                      String completedOrderId = 'waiterApp-${DateTime.now()}';

                      //split "-" because of -admin
                      String userId = userID.split("-").first;

                      if (!userId.contains("web") &&
                          !userId.contains("waiter")) {
                        //registered userid add to completed orders then delete order
                        await usersRef
                            .document(userId)
                            .collection('completedOrders')
                            .document(completedOrderId)
                            .set({
                          'restaurantRef': restaurantRef,
                          'timestamp': DateTime.now(),
                          'items': [],
                          'totalPrice': totalAmount,
                        });

                        for (final orderSnapshot in tableOrdersSnapshot) {
                          final orderData = orderSnapshot.map;
                          final submittedServiced =
                              orderData['quantity_Submitted_Serviced'] as int;
                          final submittedNotServiced =
                              orderData['quantity_Submitted_notServiced']
                                  as int;
                          if (submittedServiced > 0 ||
                              submittedNotServiced > 0) {
                            final document = await usersRef
                                .document(userId)
                                .collection('completedOrders')
                                .document(completedOrderId)
                                .get();
                            List<dynamic> items =
                                List.from(document['items'] ?? []);

                            items.add(orderData);

                            await usersRef
                                .document(userId)
                                .collection('completedOrders')
                                .document(completedOrderId)
                                .update({'items': items});
                          }
                          await tableOrdersRef
                              .document(orderSnapshot.id)
                              .delete(); // Delete from table orders
                        }
                      } else {
                        //unregistered userid just delete order
                        for (final orderSnapshot in tableOrdersSnapshot) {
                          await tableOrdersRef
                              .document(orderSnapshot.id)
                              .delete(); // Delete from table orders
                        }
                      }

                      //reset table users after transferring order data
                      await tableRef.update({
                        'users': [],
                        'unAuthorizedUsers': [],
                        'newNotification': false,
                        'notifications': [],
                      });

                      // Get the current date for stats
                      final currentDate = DateTime.now();
                      final currentDay = currentDate.day.toString().padLeft(2, '0');
                      final currentMonth = currentDate.month.toString().padLeft(2, '0');
                      final currentYear = currentDate.year.toString();

                      // Get the current document.
                      final restDoc = await restaurantRef.get();
                      Map<String, dynamic> totalSales = restDoc['totalSales'] ?? {};
                      Map<String, dynamic> yearData = totalSales[currentYear] ?? {};
                      Map<String, dynamic> monthData = yearData[currentMonth] ?? {};

                      double daySales = monthData[currentDay] ?? 0.0;
                      daySales += totalAmount;

                      // Put the new day sales back into the data.
                      monthData[currentDay] = daySales;
                      yearData[currentMonth] = monthData;
                      totalSales[currentYear] = yearData;

                      // Update the total sales
                      await restaurantRef.update({
                        'totalSales': totalSales,
                      });

                      Navigator.pushReplacement(
                        context,
                        FluentPageRoute(
                            builder: (context) =>
                                Navigation(restaurantId: restaurantID)),
                      );
                    }
                  },
                  child: const Text('Payment Completed & Reset Table'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    const PaperSize paper = PaperSize.mm80;
                    final profile = await CapabilityProfile.load();
                    final printer = NetworkPrinter(paper, profile);

                    final PosPrintResult res =
                        await printer.connect('192.168.0.123', port: 9100);

                    if (res == PosPrintResult.success) {
                      receiptDesign(printer);
                      printer.disconnect();
                    }
                    print('Print result: ${res.msg}');
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
                    childAspectRatio: 0.85,
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
                                                  if (newQuantitySubmittedNotServiced ==
                                                      0)
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

                                              final orderedTime =
                                                  document['orderedTime'];
                                              final servicedTime =
                                                  DateTime.now();

                                              final difference = servicedTime
                                                  .difference(orderedTime);
                                              final calculatedTime = difference
                                                      .inSeconds ~/
                                                  quantitySubmittedNotServiced;

                                              var itemDoc = await itemRef.get();
                                              final orderCount =
                                                  await itemDoc["orderCount"];
                                              final estimatedTime =
                                                  await itemDoc[
                                                      "estimatedTime"];

                                              final totalTime =
                                                  estimatedTime * orderCount;
                                              final newEstimatedTime = (totalTime +
                                                      calculatedTime) /
                                                  (orderCount +
                                                      quantitySubmittedNotServiced);

                                              await itemRef.update({
                                                "orderCount": orderCount +
                                                    quantitySubmittedNotServiced,
                                                "estimatedTime":
                                                    newEstimatedTime,
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
  ItemsGridState createState() => ItemsGridState();
}

class ItemsGridState extends State<ItemsGrid> {
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
                              var table = await Firestore.instance
                                  .document(
                                      "Restaurants/${widget.id}/Tables/${widget.tableNo}")
                                  .get();
                              List users = List.from(table['users']);
                              if (users.isEmpty) {
                                users.add("waiter");
                                Firestore.instance
                                    .document(
                                        "Restaurants/${widget.id}/Tables/${widget.tableNo}")
                                    .update({
                                  "users": users,
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
                                final oldQuantity =
                                    orderDoc["quantity_Submitted_notServiced"];
                                final quantity = oldQuantity + 1;
                                orderDoc.reference.update({
                                  "quantity_Submitted_notServiced": quantity,
                                  if (oldQuantity == 0)
                                    "orderedTime": DateTime.now(),
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
