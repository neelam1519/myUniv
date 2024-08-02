import 'package:findany_flutter/leaveforms/leaveformprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LeaveFormDetailsShow extends StatefulWidget {
  final int index;

  LeaveFormDetailsShow({required this.index});

  @override
  _LeaveFormDetailsShowState createState() => _LeaveFormDetailsShowState();
}

class _LeaveFormDetailsShowState extends State<LeaveFormDetailsShow> {

  @override
  Widget build(BuildContext context) {
    final leaveFormProvider = Provider.of<LeaveFormProvider>(context);
    final List<Map<String, dynamic>> leaveData = leaveFormProvider.leaveData;

    if (widget.index >= leaveData.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Leave Form Details'),
        ),
        body: Center(
          child: Text('Leave form not found.'),
        ),
      );
    }

    final Map<String, dynamic> leaveDetails = leaveData[widget.index];
    print('Leave Details: $leaveDetails');

    final String docId = leaveDetails.keys.first;
    print('Document ID: $docId');

    final Map<String, dynamic> data = leaveDetails[docId];
    print('Data: $data');

    print('Final Approval $data');

    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Form Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Student ID:', data['studentId'] ?? 'N/A'),
                _buildInfoRow('Student Name:', data['studentName'] ?? 'N/A'),
                Row(
                  children: [
                    _buildDateInfo('From Date:', data['fromDate'] ?? 'N/A'),
                    SizedBox(width: 20),
                    _buildDateInfo('To Date:', data['toDate'] ?? 'N/A'),
                  ],
                ),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Father Mobile:', data['fatherMobile'] ?? 'N/A'),
                _buildInfoRow('Alternative Mobile:', data['alternativeMobile'] ?? 'N/A'),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Reason:', data['reason'] ?? 'N/A'),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Proof File URL:', data['proofFileUrl'] ?? 'N/A'),
                Divider(height: 20, thickness: 1),
                _buildApprovalRow('Faculty Advisor Approval:', data['facultyAdvisorApproval']?['status']),
                _buildApprovalRow('Year Coordinator Approval:', data['yearCoordinatorApproval']?['status']),
                _buildApprovalRow('HOD Approval:', data['hodApproval']?['status']),
                _buildApprovalRow('Hostel Warden Approval:', data['hostelWardenApproval']?['status']),
                Divider(height: 20, thickness: 1),
                _buildApprovalRow('Final Approval:', data['finalApproval']?['status'], isBold: true),
                SizedBox(height: 20),
                if (data['finalApproval']['status'] == 'APPROVED')
                  Center(
                    child: QrImageView(
                      data: docId,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Text(
      '$label $date',
      style: TextStyle(fontSize: 16),
    );
  }

  Widget _buildApprovalRow(String label, String status, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Expanded(
            child: Text(
              status,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
