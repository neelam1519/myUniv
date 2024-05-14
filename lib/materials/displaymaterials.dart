import 'package:flutter/material.dart';

class DisplayMaterials extends StatefulWidget {
  @override
  _DisplayMaterialsState createState() => _DisplayMaterialsState();
}

class _DisplayMaterialsState extends State<DisplayMaterials> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Display Materials'),
      ),
      body: Container(
        child: Center(
          child: Text('Display Materials Screen'),
        ),
      ),
    );
  }
}
