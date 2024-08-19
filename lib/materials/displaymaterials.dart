import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:findany_flutter/services/sendnotification.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:universal_io/io.dart';
import '../provider/display_materials_provider.dart';
import '../services/pdfscreen.dart';
import 'package:provider/provider.dart';

class DisplayMaterials extends StatelessWidget {
  final String path;
  final String unit;
  final String subject;

  const DisplayMaterials({super.key, required this.path, required this.subject, required this.unit});

  Widget buildSkeletonView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 4, // Display 4 shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            elevation: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(color: Colors.grey[300]),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 20,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void viewPdfFullScreen(String? filePath, String title, BuildContext context) {
    if (filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFScreen(filePath: filePath, title: title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DisplayMaterialsProvider(
        firebaseStorageHelper: FirebaseStorageHelper(),
        loadingDialog: LoadingDialog(),
        notificationService: NotificationService(),
        utils: Utils(),
      )..initialize(path,unit),
      child: Consumer<DisplayMaterialsProvider>(
        builder: (context, provider, child) {
          print("StoragePath: ${provider.storagePath}");
          return Scaffold(
            appBar: AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("$subject>$unit"),
              ),
            ),
            body: StreamBuilder<List<File>>(
              stream: provider.streamController.stream,
              builder: (context, snapshot) {
                print("Snapshot Data: ${snapshot.data}");
                if (!provider.isInitialized) {
                  return buildSkeletonView();
                } else if (provider.isDownloading && !provider.firstDownloadCompleted) {
                  return buildSkeletonView();
                } else if (snapshot.hasError) {
                  provider.loadingDialog.dismiss();
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!provider.isDownloading && (snapshot.data == null || snapshot.data!.isEmpty)) {
                  provider.loadingDialog.dismiss();
                  return const Center(
                    child: Text('No files available.'),
                  );
                } else {
                  List<File> filesToShow = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filesToShow.length,
                    itemBuilder: (context, index) {
                      File pdfFile = filesToShow[index];
                      return GestureDetector(
                        onTap: () {
                          viewPdfFullScreen(pdfFile.path, pdfFile.path.split('/').last, context);
                        },
                        child: Card(
                          elevation: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: PDFView(
                                  filePath: pdfFile.path,
                                  enableSwipe: true,
                                  swipeHorizontal: false,
                                  autoSpacing: false,
                                  pageFling: false,
                                  onRender: (pages) {},
                                  onError: (error) {
                                    print(error.toString());
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  pdfFile.path.split('/').last,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: provider.currentIndex,
              onTap: (int index) async {
                provider.updateIndex(index,path,unit);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.picture_as_pdf),
                  label: 'PDFs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pages),
                  label: 'QUESTION PAPERS',
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                provider.uploadFiles();
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.upload),
            ),
          );
        },
      ),
    );
  }
}
