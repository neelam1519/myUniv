import 'package:flutter/cupertino.dart';

class OnClickedBuildings extends StatefulWidget {
  final String block;
  OnClickedBuildings({required this.block});

  @override
  _OnClickedBuildingsState createState() => _OnClickedBuildingsState();
}

class _OnClickedBuildingsState extends State<OnClickedBuildings> {
  @override
  Widget build(BuildContext context) {
    return Center( // Center widget to center its child
      child: Text('${widget.block} internal view', // Displaying the block text
        style: TextStyle(
          fontSize: 20, // Adjust the font size as needed
          fontWeight: FontWeight.bold, // Adjust the font weight as needed
        ),
      ),
    );
  }
}
