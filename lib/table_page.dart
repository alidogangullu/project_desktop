import 'package:fluent_ui/fluent_ui.dart';

class TableManagementPage extends StatefulWidget {
  const TableManagementPage({Key? key, required this.tableNo}) : super(key: key);

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
                  title: Text("Orders"), body: TablePage(tableNo: widget.tableNo,),
                onTap: (){setState(() {
                  index = 0;
                });}
              ),
              PaneItem(
                icon: const Icon(FluentIcons.payment_card),
                title: Text("Payment"), body: PaymentPage(tableNo: widget.tableNo,),
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

class TablePage extends StatelessWidget {
  const TablePage({Key? key, required this.tableNo}) : super(key: key);
  final int tableNo;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("yeni sipariş, gönderilen sipariş, garson tarafından ekleme vb. işlemler"),);
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
