import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionAndAnswer extends StatefulWidget {
  @override
  _QuestionAndAnswerState createState() => _QuestionAndAnswerState();
}

class _QuestionAndAnswerState extends State<QuestionAndAnswer> {
  Utils utils = Utils();
  FireStoreService fireStoreService = FireStoreService();
  NotificationService notificationService = NotificationService();
  LoadingDialog loadingDialog = new LoadingDialog();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _addQuestion() async {
    if (_questionController.text.isEmpty) {
      utils.showToastMessage('Ask your question', context);
      return;
    }

    loadingDialog.showDefaultLoading('Submitting your question');
    DocumentReference questionRef = FirebaseFirestore.instance.doc('Q&A/Questions');
    DocumentReference questionAdminRef = FirebaseFirestore.instance.doc('AdminDetails/Questions');
    List<String> tokens = await utils.getSpecificTokens(questionAdminRef);
    notificationService.sendNotification(tokens, 'Question', _questionController.text, {});

    Map<String, dynamic> question = {'${await utils.getCurrentUserEmail()}/${DateTime.now().millisecondsSinceEpoch}': _questionController.text};

    fireStoreService.uploadMapDataToFirestore(question, questionRef);

    _questionController.clear();
    utils.showToastMessage('Question is submitted you will get update on your mail', context);
    loadingDialog.dismiss();
    Navigator.pop(context);
    Navigator.pop(context);
  }

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ask a Question'),
          content: TextField(
            controller: _questionController,
            decoration: InputDecoration(labelText: 'Question'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addQuestion,
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter search term',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        )
            : Text('Question and Answer'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Q&A').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final questions = snapshot.data?.docs ?? [];
          final filteredQuestions = questions.where((questionData) {
            final docId = questionData.id;
            if (docId == 'Questions') return false;

            final question = questionData['question'] as String;
            return question.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filteredQuestions.isEmpty) {
            return Center(child: Text('No results found'));
          }

          return ListView.builder(
            itemCount: filteredQuestions.length,
            itemBuilder: (context, index) {
              final questionData = filteredQuestions[index];
              final question = questionData['question'] as String;
              final type = questionData['type'] as String;

              Widget answerWidget;
              if (type == 'steps') {
                final steps = List<String>.from(questionData['answer']);
                answerWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.map((step) => ListTile(
                    leading: Icon(Icons.brightness_1, size: 8),
                    title: Text(step, style: TextStyle(fontSize: 16.0)),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                  )).toList(),
                );
              } else {
                final answer = questionData['answer'] as String;
                answerWidget = Align(
                  alignment: Alignment.centerLeft,
                  child: Text(answer, style: TextStyle(fontSize: 16.0)),
                );
              }

              return ExpansionTile(
                title: Text(
                  question,
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: answerWidget,
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        child: Icon(Icons.question_mark),
        tooltip: 'Ask a Question',
      ),
    );
  }
}
