import 'package:findany_flutter/materials/displaymaterials.dart';
import 'package:findany_flutter/materials/display_materials_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Units extends StatefulWidget {
  final String path;
  final String subject;

  const Units({super.key, required this.path, required this.subject});

  @override
  State<Units> createState() => _UnitsState();
}

class _UnitsState extends State<Units> {
  late DisplayMaterialsProvider displayMaterialsProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    displayMaterialsProvider = Provider.of<DisplayMaterialsProvider>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subject,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 4.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: ListTile(
                title: Text(
                  'UNIT ${index + 1}',
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
                  String storagePath = "${widget.path}/UNIT ${index + 1}";
                  displayMaterialsProvider.setStoragePath(storagePath);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplayMaterials(
                        path: widget.path,
                        unit: 'UNIT ${index + 1}',
                        subject: widget.subject,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
