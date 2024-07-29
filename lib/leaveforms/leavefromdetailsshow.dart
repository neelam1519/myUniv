import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/leaveforms/leaveformprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeaveFormDetailsShow extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final leaveData = Provider.of<LeaveFormProvider>(context).leaveData;

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
                _buildInfoRow('Student ID:', leaveData['studentId']),
                _buildInfoRow('Student Name:', leaveData['studentName']),
                Row(
                  children: [
                    Text(
                      'From Date: ${leaveData['fromDate']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 20),
                    Text(
                      'To Date: ${leaveData['toDate']}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Father Mobile:', leaveData['fatherMobile']),
                _buildInfoRow('Alternative Mobile:', leaveData['alternativeMobile']),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Reason:', leaveData['reason']),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Proof File URL:', leaveData['proofFileUrl']),
                Divider(height: 20, thickness: 1),
                _buildApprovalRow(
                  'Faculty Advisor Approval:',
                  leaveData['facultyAdvisorApproval']['status'] ? 'Approved' : 'Not Approved',
                ),
                _buildApprovalRow(
                  'Year Coordinator Approval:',
                  leaveData['yearCoordinatorApproval']['status'] ? 'Approved' : 'Not Approved',
                ),
                _buildApprovalRow(
                  'HOD Approval:',
                  leaveData['hodApproval']['status'] ? 'Approved' : 'Not Approved',
                ),
                _buildApprovalRow(
                  'Hostel Warden Approval:',
                  leaveData['hostelWardenApproval']['status'] ? 'Approved' : 'Not Approved',
                ),
                Divider(height: 20, thickness: 1),
                _buildApprovalRow(
                  'Final Approval:',
                  leaveData['finalApproval']['status'] ? 'Approved' : 'Not Approved',
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ),
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
}
