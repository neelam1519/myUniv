import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../apis/googleDrive.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'displaymaterials_drive.dart';

class Folder {
  final String id;
  final String name;

  Folder(this.id, this.name);
}

class Units extends StatefulWidget {
  final String subjectID;
  final String subjectname;

  const Units({super.key, required this.subjectID, required this.subjectname});

  @override
  State<Units> createState() => _UnitsState();
}

class _UnitsState extends State<Units> {
  GoogleDriveService driveService = GoogleDriveService();

  Future<List<Folder>> fetchUnits() async {
    try {
      await driveService.authenticate();
      List<drive.File> folders = await driveService.listFoldersInFolder(widget.subjectID);

      List<Folder> folderList = folders.map((folder) => Folder(folder.id!, folder.name!)).toList();

      // Custom sorting: Units first, QUESTION PAPERS next, others last
      folderList.sort((a, b) {
        if (a.name.startsWith('UNIT') && b.name.startsWith('UNIT')) {
          return a.name.compareTo(b.name);
        }
        if (a.name.startsWith('UNIT')) {
          return -1;
        }
        if (b.name.startsWith('UNIT')) {
          return 1;
        }
        if (a.name == 'QUESTION PAPERS') {
          return -1;
        }
        if (b.name == 'QUESTION PAPERS') {
          return 1;
        }
        return a.name.compareTo(b.name);
      });

      return folderList;
    } catch (e) {
      print('Error fetching units: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subjectname,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 4.0,
      ),
      body: FutureBuilder<List<Folder>>(
        future: fetchUnits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading dialog while the data is being fetched
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            // Show an error message if an error occurred
            return Center(
              child: Text(
                'Error fetching units: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Show a message if no units are available
            return const Center(
              child: Text("No units available"),
            );
          } else {
            // Display the sorted list of units
            final units = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: units.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    child: ListTile(
                      title: Text(
                        units[index].name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      onTap: () {
                        // Get the selected folder's ID and name
                        final selectedFolderId = units[index].id;
                        final selectedFolderName = units[index].name;

                        // Perform an action with the selected ID and name
                        print('Selected Folder - ID: $selectedFolderId, Name: $selectedFolderName');

                        // Example: Navigate to another screen with the selected folder info
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriveMaterials(
                              unitID: selectedFolderId,
                              unitName: selectedFolderName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
