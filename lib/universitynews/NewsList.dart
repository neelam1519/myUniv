import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/newslist_provider.dart';
import 'news_detail_screen.dart';
import 'addnews.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  @override
  void initState() {
    super.initState();
    final newsProvider = Provider.of<NewsListProvider>(context, listen: false);
    newsProvider.checkAdminStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsListProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('University News'),
            backgroundColor: Colors.yellow[700],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search news',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: provider.updateSearchQuery,
                ),
              ),
            ),
          ),
          body: StreamBuilder<List<DocumentSnapshot>>(
            stream: provider.newsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredDocs = provider.filterNews(snapshot.data!);

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  var doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>?;
                  final pdfUrl = data?.containsKey('pdfUrl') ?? false ? data!['pdfUrl'] as String? : null;
                  final timestamp = (doc['timestamp'] as Timestamp).toDate();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    elevation: 3.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        doc['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc['summary'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Published on: ${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.green[700],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailScreen(
                              title: doc['title'],
                              details: doc['details'],
                              pdfUrl: pdfUrl,
                              isAdmin: provider.isAdmin,
                              summary: doc['summary'],
                              documentID: doc.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: provider.isAdmin
              ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddNews(
                    title: '',
                    summary: '',
                    details: '',
                    pdfUrl: '',
                    documentID: '',
                  ),
                ),
              );
            },
            backgroundColor: Colors.yellow[700],
            child: const Icon(Icons.add),
          )
              : null,
        );
      },
    );
  }
}
