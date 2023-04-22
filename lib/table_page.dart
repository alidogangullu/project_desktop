import 'package:fluent_ui/fluent_ui.dart';
import 'package:firedart/firedart.dart';

class TableManagementPage extends StatefulWidget {
  const TableManagementPage({Key? key, required this.tableNo, required this.ordersRef}) : super(key: key);
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
          leading: IconButton(icon: const Icon(FluentIcons.back), onPressed: () {Navigator.pop(context);},),
          title:
          Text("Table ${widget.tableNo}"),
        ),
        pane: NavigationPane(
          selected: index,
            displayMode: PaneDisplayMode.top,
            items: [
              PaneItem(
                  icon: const Icon(FluentIcons.list),
                  title: const Text("Orders"), body: TablePage(tableNo: widget.tableNo, ordersRef: widget.ordersRef),
                onTap: (){setState(() {
                  index = 0;
                });}
              ),
              PaneItem(
                icon: const Icon(FluentIcons.payment_card),
                title: const Text("Payment"), body: PaymentPage(tableNo: widget.tableNo,),
                  onTap: (){setState(() {
                    index = 1;
                  });}
              ),
            ]
        ),
      ),

    );
  }
}

class TablePage extends StatefulWidget {
  const TablePage({Key? key, required this.tableNo, required this.ordersRef}) : super(key: key);
  final int tableNo;
  final String ordersRef;

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  bool isFirstLoading = true;

  void listenRestaurantData() {
    final ref = Firestore.instance
        .collection(widget.ordersRef);

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
            stream: Firestore.instance.collection(widget.ordersRef).get().asStream(),
            builder: (BuildContext context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.connectionState == ConnectionState.waiting && isFirstLoading) {
                isFirstLoading == false;
                return const Center(child: ProgressRing());
              }
              final documents = snapshot.data!;
              final filteredDocuments = documents.where((document) {
                final quantitySubmittedNotServiced = document['quantity_Submitted_notServiced'] as int;
                final quantityServiced = document['quantity_Submitted_Serviced'] as int;
                return quantitySubmittedNotServiced != 0 || quantityServiced != 0;
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
                    final quantitySubmittedNotServiced = document['quantity_Submitted_notServiced'] as int;
                    final quantityServiced = document['quantity_Submitted_Serviced'] as int;
                    return FutureBuilder(
                      future: itemRef.get(),
                      builder: (BuildContext context, itemSnapshot) {
                        if (itemSnapshot.hasError || itemSnapshot.connectionState == ConnectionState.waiting) {
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
                                      Text('Not Serviced: $quantitySubmittedNotServiced', style: TextStyle(color: Colors.red),),
                                    if(quantitySubmittedNotServiced == 0)
                                      Text('Not Serviced: $quantitySubmittedNotServiced'),
                                    Text('Serviced: $quantityServiced'),
                                  ],
                                ),
                              ),
                              if (quantitySubmittedNotServiced != 0)
                                Button(
                                  onPressed: () {
                                    final newQuantityServiced = quantityServiced + quantitySubmittedNotServiced;
                                    const newQuantitySubmittedNotServiced = 0;
                                    document.reference.update({
                                      'quantity_Submitted_notServiced': newQuantitySubmittedNotServiced,
                                      'quantity_Submitted_Serviced': newQuantityServiced,
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
        Container(color: Colors.grey, width: 1, padding: const EdgeInsets.all(8)),
        Expanded(child: Text("Ürün ekleme vb garson özellikleri...")), //todo
      ],
    );
  }

}

class PaymentPage extends StatelessWidget {
  const PaymentPage({Key? key, required this.tableNo}) : super(key: key);
  final int tableNo;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Payment, adisyon, fatura vb. işlemler"),);
  }
}
