import 'package:flutter/cupertino.dart';

class OnClickedBuildings extends StatefulWidget {
  final String block;

  const OnClickedBuildings({super.key, required this.block});

  @override
  State<OnClickedBuildings> createState() => _OnClickedBuildingsState();
}

class _OnClickedBuildingsState extends State<OnClickedBuildings> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '${widget.block} internal view',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
