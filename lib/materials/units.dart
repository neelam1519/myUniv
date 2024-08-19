import 'package:findany_flutter/materials/displaymaterials.dart';
import 'package:findany_flutter/provider/display_materials_provider.dart';
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(widget.subject),
        ),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text('UNIT ${index + 1}'),
              onTap: () {
                String storagePath = "${widget.path}/UNIT ${index+1}";
                displayMaterialsProvider.setStoragePath(storagePath);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DisplayMaterials(path: widget.path, unit: 'UNIT ${index + 1}', subject: widget.subject)));
              },
            ),
          );
        },
      ),
    );
  }
}
