import 'package:findany_flutter/materials/displaymaterials.dart';
import 'package:flutter/material.dart';

class Units extends StatefulWidget {
  final String path;

  Units({required this.path});

  @override
  _UnitsState createState() => _UnitsState();
}

class _UnitsState extends State<Units> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Units'),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text('UNIT ${index + 1}'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DisplayMaterials(path: '${widget.path}', unit: 'UNIT ${index+1}',)));
              },
            ),
          );
        },
      ),
    );
  }
}
