import 'package:flutter/cupertino.dart';

class Leaveformstats extends StatefulWidget {
  @override
  _LeaveformstatsState createState() => _LeaveformstatsState();
}

class _LeaveformstatsState extends State<Leaveformstats> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Leave Form Stats'),
      ),
      child: Center(
        child: Text('Leave Form Stats will be displayed here.'),
      ),
    );
  }
}
