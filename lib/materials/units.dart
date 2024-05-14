import 'package:findany_flutter/materials/displaymaterials.dart';
import 'package:flutter/material.dart';

class Units extends StatefulWidget {
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
              title: Text('Unit ${index + 1}'),
              onTap: () {
                // Navigate to unit details page or perform any action here
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DisplayMaterials()));
              },
            ),
          );
        },
      ),
    );
  }
}
