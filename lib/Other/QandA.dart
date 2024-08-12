// import 'package:findany_flutter/Firebase/firestore.dart';
// import 'package:findany_flutter/services/sendnotification.dart';
// import 'package:findany_flutter/utils/LoadingDialog.dart';
// import 'package:findany_flutter/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class QuestionAndAnswer extends StatefulWidget {
//   const QuestionAndAnswer({super.key});
//
//   @override
//   _QuestionAndAnswerState createState() => _QuestionAndAnswerState();
// }
//
// class _QuestionAndAnswerState extends State<QuestionAndAnswer> {
//
//   Utils utils = Utils();
//   FireStoreService fireStoreService = FireStoreService();
//   NotificationService notificationService = NotificationService();
//   LoadingDialog loadingDialog = LoadingDialog();
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String _searchQuery = '';
//   bool _isSearching = false;
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _questionController = TextEditingController();
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _questionController.dispose();
//     loadingDialog.dismiss();
//     super.dispose();
//   }
//
//   Future<void> _addQuestion() async {
//     if (_questionController.text.isEmpty) {
//       utils.showToastMessage('Ask your question');
//       return;
//     }
//
//     loadingDialog.showDefaultLoading('Submitting your question');
//     DocumentReference questionRef = FirebaseFirestore.instance.doc('Q&A/Questions');
//     DocumentReference questionAdminRef = FirebaseFirestore.instance.doc('AdminDetails/Questions');
//     List<String> tokens = await utils.getSpecificTokens(questionAdminRef);
//     notificationService.sendNotification(tokens, 'Question', _questionController.text, {});
//
//     Map<String, dynamic> question = {'${await utils.getCurrentUserEmail()}/${DateTime.now().millisecondsSinceEpoch}': _questionController.text};
//
//     fireStoreService.uploadMapDataToFirestore(question, questionRef);
//
//     _questionController.clear();
//     utils.showToastMessage('Question is submitted you will get update on your mail');
//     loadingDialog.dismiss();
//     Navigator.pop(context);
//     Navigator.pop(context);
//   }
//
//   void _showAddQuestionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Ask a Question'),
//           content: TextField(
//             controller: _questionController,
//             decoration: const InputDecoration(labelText: 'Question'),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: _addQuestion,
//               child: const Text('Submit'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: _isSearching
//             ? TextField(
//           controller: _searchController,
//           autofocus: true,
//           decoration: const InputDecoration(
//             hintText: 'Enter search term',
//             border: InputBorder.none,
//           ),
//           onChanged: (value) {
//             setState(() {
//               _searchQuery = value.toLowerCase();
//             });
//           },
//         )
//             : const Text('Question and Answer'),
//         actions: [
//           IconButton(
//             icon: Icon(_isSearching ? Icons.clear : Icons.search),
//             onPressed: () {
//               setState(() {
//                 if (_isSearching) {
//                   _searchQuery = '';
//                   _searchController.clear();
//                 }
//                 _isSearching = !_isSearching;
//               });
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore.collection('Q&A').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           final questions = snapshot.data?.docs ?? [];
//           final filteredQuestions = questions.where((questionData) {
//             final docId = questionData.id;
//             if (docId == 'Questions') return false;
//
//             final question = questionData['question'] as String;
//             return question.toLowerCase().contains(_searchQuery);
//           }).toList();
//
//           if (filteredQuestions.isEmpty) {
//             return const Center(child: Text('No Answers found ask a question?'));
//           }
//
//           return ListView.builder(
//             itemCount: filteredQuestions.length,
//             itemBuilder: (context, index) {
//               final questionData = filteredQuestions[index];
//               final question = questionData['question'] as String;
//               final type = questionData['type'] as String;
//
//               Widget answerWidget;
//               if (type == 'steps') {
//                 final steps = List<String>.from(questionData['answer']);
//                 answerWidget = Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: steps.map((step) => ListTile(
//                     leading: const Icon(Icons.brightness_1, size: 8),
//                     title: Text(step, style: const TextStyle(fontSize: 16.0)),
//                     contentPadding: EdgeInsets.zero,
//                     visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
//                   )).toList(),
//                 );
//               } else {
//                 final answer = questionData['answer'] as String;
//                 answerWidget = Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(answer, style: const TextStyle(fontSize: 16.0)),
//                 );
//               }
//
//               return ExpansionTile(
//                 title: Text(
//                   question,
//                   style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
//                 ),
//                 children: <Widget>[
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: answerWidget,
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddQuestionDialog,
//         tooltip: 'Ask a Question',
//         child: const Icon(Icons.question_mark),
//       ),
//     );
//   }
//
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../provider/qanda_provider.dart';

class QuestionAndAnswer extends StatefulWidget {
  const QuestionAndAnswer({super.key});

  @override
  State<QuestionAndAnswer> createState() => _QuestionAndAnswerState();
}

class _QuestionAndAnswerState extends State<QuestionAndAnswer> {
  @override
  void initState() {
    super.initState();
    // Any initialization logic if needed
  }

  void _showAddQuestionDialog() {
    final provider = Provider.of<QAndAProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ask a Question'),
          content: TextField(
            controller: provider.questionController,
            decoration: const InputDecoration(labelText: 'Question'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.addQuestion(context);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QAndAProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: provider.isSearching
                ? TextField(
              controller: provider.searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter search term',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                provider.searchQuery = value.toLowerCase();
              },
            )
                : const Text('Question and Answer'),
            actions: [
              IconButton(
                icon: Icon(provider.isSearching ? Icons.clear : Icons.search),
                onPressed: () {
                  provider.isSearching = !provider.isSearching;
                  if (!provider.isSearching) {
                    provider.searchQuery = '';
                    provider.searchController.clear();
                  }
                },
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Q&A').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final questions = snapshot.data?.docs ?? [];
              final filteredQuestions = questions.where((questionData) {
                final docId = questionData.id;
                if (docId == 'Questions') return false;

                final question = questionData['question'] as String;
                return question.toLowerCase().contains(provider.searchQuery);
              }).toList();

              if (filteredQuestions.isEmpty) {
                return const Center(child: Text('No Answers found. Ask a question?'));
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
                        leading: const Icon(Icons.brightness_1, size: 8),
                        title: Text(step, style: const TextStyle(fontSize: 16.0)),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                      )).toList(),
                    );
                  } else {
                    final answer = questionData['answer'] as String;
                    answerWidget = Align(
                      alignment: Alignment.centerLeft,
                      child: Text(answer, style: const TextStyle(fontSize: 16.0)),
                    );
                  }

                  return ExpansionTile(
                    title: Text(
                      question,
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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
            tooltip: 'Ask a Question',
            child: const Icon(Icons.question_mark),
          ),
        );
      },
    );
  }
}
