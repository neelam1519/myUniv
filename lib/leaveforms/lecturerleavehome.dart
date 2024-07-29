  import 'package:findany_flutter/leaveforms/leaveformprovider.dart';
  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:provider/provider.dart';
  import '../Firebase/firestore.dart';
  import 'leaveformdetails.dart';


  class LecturerLeaveHome extends StatefulWidget {
    @override
    _LecturerLeaveHomeState createState() => _LecturerLeaveHomeState();
  }

  class _LecturerLeaveHomeState extends State<LecturerLeaveHome> {
    int _selectedIndex = 0;
    FireStoreService fireStoreService = FireStoreService();

    static const List<String> _collectionNames = [
      'PENDING',
      'ACCEPTED',
      'REJECTED',
    ];

    Stream<List<DocumentSnapshot>> _getLeaveForms(String status) async* {
      DocumentReference documentReference = FirebaseFirestore.instance.doc(
          '/AcademicDetails/3/BRANCHES/CSE/SPECIALIZATIONS/CYBER SECURITY/SECTIONS/S25/LEAVEFORMS/$status');
      Map<String, dynamic>? leaveRef = await fireStoreService.getDocumentDetails(documentReference);

      List<DocumentSnapshot> documents = [];

      if (leaveRef != null) {
        for (var entry in leaveRef.entries) {
          DocumentReference ref = entry.value as DocumentReference;
          DocumentSnapshot doc = await ref.get();
          documents.add(doc);
          print('Document ID: ${doc.id}, Data: ${doc.data()}');
          yield documents;
        }
      } else {
        yield [];
      }
    }

    Widget _buildLeaveFormList(Stream<List<DocumentSnapshot>> stream, String status) {
      return StreamBuilder<List<DocumentSnapshot>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No $status leave forms found.'));
          } else {
            return ListView(
              children: snapshot.data!.map((DocumentSnapshot document) {
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    Provider.of<LeaveFormProvider>(context, listen: false).setLeaveData(data,document.reference);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LeaveFormDetails()));
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student ID: ${data['studentId']}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'From: ${data['fromDate']}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'To: ${data['toDate']}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Reason: ${data['reason']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Final Approval: ${data['finalApproval']['status'] ? 'Approved' : 'Not Approved'}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Lecturer Leave Home'),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _collectionNames
              .map((status) => _buildLeaveFormList(_getLeaveForms(status), status))
              .toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.hourglass_empty),
              label: 'Pending',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check),
              label: 'Accepted',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.close),
              label: 'Rejected',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      );
    }

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
