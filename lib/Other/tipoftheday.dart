import 'package:flutter/material.dart';

class TipOfTheDay {
  final String title;
  final String imageUrl;
  final String description;
  final DateTime date;

  TipOfTheDay({
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.date,
  });
}

class TipOfTheDayScreen extends StatelessWidget {
  final List<TipOfTheDay> tips = [
    TipOfTheDay(
      title: "Stay Hydrated",
      imageUrl: "https://firebasestorage.googleapis.com/v0/b/findany-84c36.appspot.com/o/ProfileImages%2F3YR0ACkiYzOTjZB3ccGo7nY4q2z2.jpg?alt=media&token=5bcb7e8b-9364-42da-a9d8-23588cbc0fdd",
      description: "Drink at least 8 glasses of water daily to stay healthy.",
      date: DateTime.now().subtract(Duration(days: 1)),
    ),
    TipOfTheDay(
      title: "Stay Hydrated",
      imageUrl: "https://firebasestorage.googleapis.com/v0/b/findany-84c36.appspot.com/o/ProfileImages%2F3YR0ACkiYzOTjZB3ccGo7nY4q2z2.jpg?alt=media&token=5bcb7e8b-9364-42da-a9d8-23588cbc0fdd",
      description: "Drink at least 8 glasses of water daily to stay healthy.",
      date: DateTime.now().subtract(Duration(days: 1)),
    ),
    TipOfTheDay(
      title: "Daily Exercise",
      imageUrl: "https://firebasestorage.googleapis.com/v0/b/findany-84c36.appspot.com/o/ProfileImages%2F3YR0ACkiYzOTjZB3ccGo7nY4q2z2.jpg?alt=media&token=5bcb7e8b-9364-42da-a9d8-23588cbc0fdd",
      description: "Exercise for at least 30 minutes every day.",
      date: DateTime.now().subtract(Duration(days: 8)), // Past week
    ),
    // Add more tips here
  ];

  List<TipOfTheDay> filterTipsByWeek(DateTime startDate, DateTime endDate) {
    return tips
        .where((tip) =>
    tip.date.isAfter(startDate) && tip.date.isBefore(endDate))
        .toList();
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(Duration(days: 7));

    if (date.isAfter(thisWeekStart)) {
      // If the tip is from this week
      return '${_getDayOfWeek(date)}'; // Format as day of the week (e.g., Monday)
    } else if (date.isAfter(lastWeekStart)) {
      // If the tip is from last week
      return 'Last Week - ${_getDayOfWeek(date)}'; // Last week + day (e.g., Last Week - Monday)
    } else {
      return '';
    }
  }

  String _getDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime startOfPastWeek = startOfCurrentWeek.subtract(Duration(days: 7));
    final DateTime endOfPastWeek = startOfCurrentWeek.subtract(Duration(days: 1));

    final List<TipOfTheDay> currentWeekTips =
    filterTipsByWeek(startOfCurrentWeek, now);
    final List<TipOfTheDay> pastWeekTips =
    filterTipsByWeek(startOfPastWeek, endOfPastWeek);

    return Scaffold(
      appBar: AppBar(title: Text("Tip of the Day")),
      body: ListView(
        children: [
          if (currentWeekTips.isNotEmpty) ...[
            Text("This Week", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...currentWeekTips.map((tip) => TipCard(tip, formatDate(tip.date))),
          ],
          if (pastWeekTips.isNotEmpty) ...[
            Text("Last Week", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...pastWeekTips.map((tip) => TipCard(tip, formatDate(tip.date))),
          ],
        ],
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  final TipOfTheDay tip;
  final String formattedDate;

  TipCard(this.tip, this.formattedDate);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showInAppMessage(context, tip);
      },
      child: Card(
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image on one side
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  tip.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
              SizedBox(width: 12), // Space between image and text
              // Title and Description on the other side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate, // Show the formatted date (e.g., Monday or Last Week - Monday)
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 6), // Space between date and title
                    Text(
                      tip.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6), // Space between title and description
                    Text(
                      tip.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3, // Limit description to 3 lines
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInAppMessage(BuildContext context, TipOfTheDay tip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tip Title
                    Text(
                      tip.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    // Tip Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        tip.imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    // Tip Description
                    Text(
                      tip.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Cross Icon for dismissing the dialog
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
