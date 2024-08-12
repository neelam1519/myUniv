import 'package:findany_flutter/provider/xerox_provider.dart';
import 'package:findany_flutter/xerox/showfiles.dart';
import 'package:findany_flutter/xerox/xeroxhistory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class XeroxHome extends StatefulWidget {
  const XeroxHome({super.key});

  @override
  State<XeroxHome> createState() => _XeroxHomeState();
}

class _XeroxHomeState extends State<XeroxHome> {
  XeroxProvider? xeroxProvider;

  @override
  void initState() {
    super.initState();
    xeroxProvider = Provider.of<XeroxProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      xeroxProvider
        ?..getData()
        ..initializeRazorpay()
        ..fetchAnnouncementText();
      xeroxProvider?.totalFileCount = xeroxProvider!.uploadedFiles.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Xerox'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const XeroxHistory()),
                );
              },
            ),
          ],
        ),
        body: Consumer<XeroxProvider>(
          builder: (context, xerProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (xerProvider.announcementText != null && xerProvider.announcementText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
                      child: Linkify(
                        text: xerProvider.announcementText!,
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        linkStyle: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        onOpen: (link) async {
                          if (await canLaunch(link.url)) {
                            await launch(link.url);
                          } else {
                            throw 'Could not launch ${link.url}';
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 15),
                  Text(
                    xerProvider.email,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: xerProvider.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Xerox copy name*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: xerProvider.mobilenumberController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number*',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: xerProvider.pickFile,
                              child: const Text('Upload File'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ShowFiles()),
                                ).then((value) {
                                  if (value != null) {
                                    xerProvider.uploadedFiles.addAll(value);
                                    xerProvider.totalFileCount = xerProvider.uploadedFiles.length;
                                  }
                                });
                              },
                              child: const Text('Select Files'),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int index = 0; index < xerProvider.uploadedFiles.length; index++)
                              ListTile(
                                title: Text('${index + 1}. ${xerProvider.uploadedFiles.keys.toList()[index]}'),
                                onTap: () => xerProvider.viewPdfFullScreen(
                                    xerProvider.uploadedFiles.values.toList()[index],
                                    xerProvider.uploadedFiles.values.toList()[index].split('/').last,
                                    context),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    xerProvider.utils
                                        .deleteFileInCache(xerProvider.uploadedFiles.values.toList()[index]);
                                    xerProvider.uploadedFiles.remove(xerProvider.uploadedFiles.keys.toList()[index]);
                                    xerProvider.totalFileCount = xerProvider.uploadedFiles.length;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: xerProvider.bindingFileController,
                    decoration: const InputDecoration(
                      labelText: 'File numbers for binding (default is no binding)',
                      hintText: 'ex -1,3',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: xerProvider.singleSideFileController,
                    decoration: const InputDecoration(
                      labelText: '2-side print file numbers (default is 1-side print)',
                      hintText: 'ex -2,4',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: xerProvider.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Specify other requirements with file numbers',
                      hintText: 'color ,spiral biniding...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                  const SizedBox(height: 20),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Price')),
                    ],
                    rows: [
                      for (var entry in xerProvider.xeroxDetails!.entries)
                        if (xerProvider.excludedItems.contains(entry.key))
                          DataRow(cells: [
                            DataCell(Text(entry.key)),
                            DataCell(Text(entry.value.toString())),
                          ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: xerProvider.totalAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Total Amount',
                      hintText: 'Calculate the price and enter here',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      xerProvider.totalPrice = double.tryParse(value) ?? 0.0;
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (xerProvider.totalPrice.toInt() < 1) {
                          xerProvider.totalPrice = 2;
                        }
                        int price = xerProvider.totalPrice.round();
                        if (kDebugMode) {
                          print('PayingCost: $price');
                        }
                        xerProvider.onSubmitClicked(price);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Pay & Submit'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }
}
