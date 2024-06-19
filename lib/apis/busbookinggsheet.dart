import 'package:findany_flutter/utils/utils.dart';
import 'package:gsheets/gsheets.dart';

class BusBookingGSheet {
  Utils utils = new Utils();
  static const credentials = r'''{
    "type": "service_account",
    "project_id": "findany-419304",
    "private_key_id": "63d6d5d41d668d15d6b0297013a396ff0c5c31e6",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCP/9cdj5ocu36J\njkZ3V2ZW4YrKnTnV+E5IZUaahDnoNLjrVUzbl4hu1UFjIK7BBAv5PNDYQ5C6V4ia\nZev1fcI4G8xbkM5l9pNaBl39/iEuSsm1+Z2fCO6z9ZJn+EcIKgBcPYki7M3JdiBA\nMS2u7rERAj2+Y/Km8MHu7RdHQWBcB7CcYnPtBdRrvQRDg1Bifog+1PF8AR/HTJlP\nzkZ2mSKGdapwO+A3UDFsLyIqUyBe9jISxpKq14avyGpmuK7wCXCJhqvFi3TSkwXr\nOi8dcpf2jnXZ9NMll0Vr5MDsDc7xJ8fNNbLNX0/UN9bPqHluqhGmvDkucpngTfW0\nLIk3+5K3AgMBAAECggEADcReUvjauWqCONvTCC/hRzx9oiIRWHqf3rNdYlfH7YJf\njOhKgSgQptVZUK/cOp83bIG6+czOi8eN9iz5DS8TytIljI+LRsZMj4Enqqk0Oj0e\nNyQBRNDReX+97+trEcW/jmdiXWYZxUFiPfY1sZF9I5d87bSX4LazOTOOU9qqlWxm\nEXCqbCdte3HnDPSnekPOstblhvNjk23WRfDz+ytDC0y0+9xbcjWgyJMEhjg/QA4J\npORyd5xkHOhgL87SEQYYTlBEApCFf5RZy5Io1QCZ+pe+6GGNbyR3S+oCzjE9dRfF\nL8qXL52eqKvLeUFuZzf4CJKQ/f4y8THjF++400L00QKBgQDD8jMVhwPYKiaEhhKp\nzrztah87VQ89Jnlg8k4JXEahXPIUbyrIYvAHUaDz2TWE7lBNblFXzOj6Kqs1xsax\n7Hlms9f8Zj2EVUGwchmc6u9YANW1lMtZHMPQfX7+CfkmOcZWlHNGJUgQGoNF4bjG\nzJy/tLfQ/H4L22O9NVbPRK2BaQKBgQC8Ie+VAVPBmoFo64adR1BO55pA/hA/iD07\nBDRJoKNyxV5d4i2ZYSP+wlocV+vE23cYpLMIZE357KQPGK3bTJUJbE0JK6p+LfOC\ncmoxkAEehEx1QB4js4T6iJvTyjRTCboClWuB9lPQ3e1vGOiks4Ycr5Jnp54I4B9y\nQvxtoQ3PHwKBgDaajN/H4yte+6LcleDaKs3iT9fB6WA6E4MPou162HfpJdDJ9dsn\nrwnrFnY9pmtn2drqDiLwiFAGifWPchls85vKLDs65pO1Cnw4H6kZ0x7sBKH4V/56\nRJsaDcSPVO3xFbNU5Ra8Fuvd540WzN4hcOD/ZGYJprp5Jb85WPqjgdJZAoGAA0c8\nG4aYZQlCNAfWoqr5dUaH45YJxnGjT4H1P0szTe6uhEhKrx+INwo/87p8e0OvwZgt\nHnpQ+YfsG+88KFQfTLi8ZuqB4A0A70b7Hr35pwR7KJfjbo/UQ2FaBcjCPKgwu5bK\n9srKDxuu5X6znxsZvSo6DOBY2qK9KYqNR4PE79UCgYEAtNW4Zi6x4b9pGavSfRq1\nY8x6goVstXj9HlTX1zMgW8rfz35FT3V3ALdBMcssM3GaMTyUHYGyc18q/tfQ2BbN\nZJqDfCBnv0gUbsNy7n4PFkxxJOSw9IaHImhxscn31jwhk1TCJg5ZwA7yOJn082cq\nI3dibTG/+f58d6rzWtyxZ4Q=\n-----END PRIVATE KEY-----\n",
    "client_email": "gsheets@findany-419304.iam.gserviceaccount.com",
    "client_id": "106372033227423856037",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/gsheets%40findany-419304.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  }''';

  static final spreadsheetId = '16P-xDvhVkayNOvD9Az9Z_i8S_6KE_yWDTXyLWGQAzwU';
  static final gsheets = GSheets(credentials);
  static late Worksheet sheet;

  Future<void> main() async {
    String todayDate = utils.getTodayDate();
    final ss = await gsheets.spreadsheet(spreadsheetId);

    Worksheet? existingSheet = await ss.worksheetByTitle(todayDate);

    if (existingSheet == null) {
      existingSheet = await ss.addWorksheet(todayDate);
      await existingSheet.values.insertRow(1, ['REGISTRATION NUMBER','MOBILE NUMBER', 'EMAIL','FROM','TO','DATE','TIME','TOTAL COST','TRANSACTION ID','BOOKING ID','CONFIRM TICKETS - WAITING LIST TICKETS','PERSON DETAILS']);
    }
    sheet = existingSheet;
  }


  Future<void> updateCell(List<dynamic> value) async {
    await main();
    try {
      await sheet.values.appendRow(value);
    } catch (e) {
      print('Error updating cell: $e');
    }
  }


}
