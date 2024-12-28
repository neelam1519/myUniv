import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home_provider.dart';

class GridItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final Widget destination;

  const GridItem({
    super.key,
    required this.imagePath,
    required this.title,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        return GestureDetector(
          onTap: () async {
            if (await homeProvider.utils.checkInternetConnection()) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            } else {
              if(title == 'Materials'){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => destination),
                );
              }else{
                homeProvider.utils.showToastMessage("Connect to the internet");
              }
            }
          },
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
