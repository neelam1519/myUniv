// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:findany_flutter/utils/LoadingDialog.dart';
// import 'package:findany_flutter/xerox/xeroxdetailsview.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import '../Firebase/firestore.dart';
// import '../utils/utils.dart';
//
// class XeroxHistory extends StatefulWidget {
//   const XeroxHistory({super.key});
//
//   @override
//   State<XeroxHistory> createState() => _XeroxHistoryState();
// }
//
// class _XeroxHistoryState extends State<XeroxHistory> {
//   Utils utils = Utils();
//   FireStoreService fireStoreService = FireStoreService();
//   LoadingDialog loadingDialog = LoadingDialog();
//   List<Map<String, dynamic>> historyData = [];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchHistoryData();
//   }
//
//   Future<void> fetchHistoryData() async {
//     loadingDialog.showDefaultLoading("Getting history...");
//     try {
//
//       QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('UserDetails/${utils.getCurrentUserUID()}/XeroxHistory/').get();
//       for (QueryDocumentSnapshot doc in snapshot.docs) {
//         historyData.add(doc.data() as Map<String, dynamic>);
//       }
//       // Sort the historyData list based on the 'ID' value in each map
//       historyData.sort((a, b) => a['ID'].compareTo(b['ID']));
//
//       // Reverse the sorted list
//       historyData = historyData.reversed.toList();
//       print('History: $historyData');
//
//       setState(() {
//         historyData;
//       });
//       EasyLoading.dismiss();
//     } catch (e) {
//       print('Error fetching history data: $e');
//       EasyLoading.dismiss();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (historyData.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Xerox History'),
//         ),
//         body: const Center(child: Text('No history found')),
//       );
//     } else {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Xerox History'),
//         ),
//         body: ListView.builder(
//           itemCount: historyData.length,
//           itemBuilder: (context, index) {
//             Map<String, dynamic> data = historyData[index];
//             return GestureDetector(
//               child: Card(
//                 child: ListTile(
//                   title: Text(data['Name'] ?? ''),
//                   subtitle: Text('Date: ${data['Date']}'),
//                   onTap: () {
//                     // Handle onTap event
//                     try {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => XeroxDetailView(data: data),
//                         ),
//                       );
//                     } catch (e) {
//                       print('Navigation error: $e');
//                     }
//                   },
//                 ),
//               ),
//             );
//           },
//         ),
//       );
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/xeroxhistory_provider.dart';
import 'xeroxdetailsview.dart';

class XeroxHistory extends StatelessWidget {
  const XeroxHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<XeroxHistoryProvider>(context, listen: false);

    // Call fetchHistoryData if not already called
    if (provider.historyData.isEmpty && !provider.isLoading) {
      provider.fetchHistoryData();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xerox History'),
      ),
      body: Consumer<XeroxHistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return provider.historyData.isEmpty
              ? const Center(child: Text('No history found'))
              : ListView.builder(
                  itemCount: provider.historyData.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data = provider.historyData[index];
                    return GestureDetector(
                      child: Card(
                        child: ListTile(
                          title: Text(data['Name'] ?? ''),
                          subtitle: Text('Date: ${data['Date']}'),
                          onTap: () {
                            // Handle onTap event
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => XeroxDetailView(data: data),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
