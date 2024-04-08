import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findany_flutter/Firebase/firestore.dart';
import 'package:findany_flutter/Firebase/realtimedatabase.dart';
import 'package:findany_flutter/Firebase/storage.dart';
import 'package:findany_flutter/apis/gsheets.dart';
import 'package:findany_flutter/utils/LoadingDialog.dart';
import 'package:findany_flutter/utils/sharedpreferences.dart';
import 'package:findany_flutter/utils/utils.dart';
import 'package:findany_flutter/xerox/showfiles.dart';
import 'package:findany_flutter/xerox/xeroxhistory.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class XeroxHome extends StatefulWidget {

  @override
  _XeroxHomeState createState() => _XeroxHomeState();
}

class _XeroxHomeState extends State<XeroxHome> {

  Utils utils = new Utils();
  RealTimeDatabase realTimeDatabase = new RealTimeDatabase();
  FirebaseStorageHelper firebaseStorageHelper = new FirebaseStorageHelper();
  FireStoreService fireStoreService = new FireStoreService();
  UserSheetsApi userSheetsApi = new UserSheetsApi();
  SharedPreferences sharedPreferences = new SharedPreferences();
  LoadingDialog loadingDialog = new LoadingDialog();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _mobilenumberController = TextEditingController();
  TextEditingController _transactionidController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _bindingFileController = TextEditingController();
  TextEditingController _singleSideFileController = TextEditingController();

  Map<String, String> _uploadedFiles = {};

  String email='';
  double _calculatedPrice=0;
  int pages=0,bindings =0;
  double progress=0,xeroxPrice=1.5, bindingPrice = 1, pagesCost =0, bindingsCost =0;
  String xeroxVenue='We will let you know where to collect else contact 8501070702';
  String paymentNumber = '';
  int totalFileCount=0;

  @override
  void initState() {
    super.initState();
    initializeData();
    totalFileCount = _uploadedFiles.length;
  }

  Future<void> initializeData() async {
    loadingDialog.showDefaultLoading('Getting Details...');
    // Initialize email here
    email = (await sharedPreferences.getSecurePrefsValue('Email'))!;

    int? xeroxInt = await realTimeDatabase.getCurrentValue('Xerox/XeroxPrice');
    print('1 $xeroxInt');
    int? bindingInt = await realTimeDatabase.getCurrentValue('Xerox/BindingPrice');
    print('2 $bindingInt');
    xeroxPrice = xeroxInt!.toDouble();
    bindingPrice = bindingInt!.toDouble();
    print('Xerox Price: $xeroxPrice');
    print('Binding Price$bindingPrice');


    xeroxVenue = await realTimeDatabase.getCurrentValue('Xerox/XeroxVenue');
    print("Venue: $xeroxVenue");

    paymentNumber = await realTimeDatabase.getCurrentValue('Xerox/paymentNumber');
    setState(() {

    });
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xerox Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => XeroxHistory()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black, // Default text color
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Note: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: xeroxVenue, // Rest of the text
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name*',
                    border: InputBorder.none,
                    labelStyle: TextStyle(fontSize: 15),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: TextFormField(
                  controller: _mobilenumberController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number*',
                    border: InputBorder.none,
                    labelStyle: TextStyle(fontSize: 15),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Text(
                  email,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _uploadFile,
                    child: Text('Upload File'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Define action for the second button
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowFiles(),
                        ),
                      ).then((value) {
                        // Handle the returned map data here
                        if (value != null) {
                          // Do something with the returned map data
                          setState(() {
                            _uploadedFiles.addAll(value);
                            totalFileCount = _uploadedFiles.length;
                          });
                        }
                      });
                    },
                    child: Text('Select Files'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int index = 0; index < _uploadedFiles.length; index++)
                    ListTile(
                      title: Text('${index + 1}. ${_uploadedFiles.keys.toList()[index]}'),
                      onTap: () => _openFile(_uploadedFiles.values.toList()[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            utils.deleteFileInCache(_uploadedFiles.values.toList()[index]);
                            _uploadedFiles.remove(_uploadedFiles.keys.toList()[index]);
                            totalFileCount = _uploadedFiles.length;
                          });
                        },
                      ),
                    ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter the numbers of files for binding (default is no binding)',
                    border: InputBorder.none,
                    labelStyle: TextStyle(fontSize: 15),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter the numbers of 2-side print files (default is 1-side print)',
                    border: InputBorder.none,
                    labelStyle: TextStyle(fontSize: 15),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Specify any additional specifications (Extra cost applies)',
                    border: InputBorder.none,
                    labelStyle: TextStyle(fontSize: 15),
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null, // Allows multiple lines of text input
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'no of pages',
                        labelStyle: TextStyle(fontSize: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          pages = int.tryParse(value) ?? 0;
                          pagesCost = pages * xeroxPrice;
                          _calculatedPrice = pagesCost + bindingsCost;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '* $xeroxPrice',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '+',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'no of bindings',
                        labelStyle: TextStyle(fontSize: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          bindings = int.tryParse(value) ?? 0;
                          bindingsCost = bindings * bindingPrice;
                          _calculatedPrice = pagesCost + bindingsCost;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '* $bindingPrice',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '= $_calculatedPrice',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),

              SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Text(
                  'paytm/gpay/phonepe: $paymentNumber',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _transactionidController,
                        decoration: InputDecoration(
                          labelText: 'Transaction Id*',
                          border: InputBorder.none,
                          labelStyle: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Add your onTap action here
                        print('Icon tapped');
                        utils.showToastMessage("Youtube link for getting transaction ID", context);
                      },
                      child: Icon(Icons.help_outline), // Add icon here
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Add submit action here
                  onSubmitClicked();
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> onSubmitClicked() async {
    // Check if any required field is empty
    if (_nameController.text.isEmpty || _mobilenumberController.text.isEmpty || _transactionidController.text.isEmpty || _uploadedFiles.isEmpty) {
      utils.showToastMessage('Missing required Fields', context);
      return;
    } else if (!utils.isValidMobileNumber(_mobilenumberController.text)) {
      utils.showToastMessage('Enter a Valid Mobile Number', context);
      return;
    } else if (_nameController.text.length <= 5) {
      utils.showToastMessage('Enter at least 5 letters in name', context);
      return;
    } else if (!(_transactionidController.text.length >= 10 && _transactionidController.text.length <= 30)) {
      utils.showToastMessage('Enter a valid Transaction ID', context);
      return;
    }

    // Show progress loading bar
    loadingDialog.showProgressLoading(progress, 'Uploading files...');

    // List to store uploaded file URLs
    List<String> uploadedUrls = [];
    int fileLength = _uploadedFiles.length;
    double totalprogress=0.9/fileLength;

    // Iterate through the uploaded files
    for (String value in _uploadedFiles.values) {
      File file = File(value);
      print('Value: ${file.path}');
      String? uploadedUrl = '';
      // Upload the file to Firebase Storage
      if(utils.isURL(value)){
        uploadedUrl = value;
      }else{
        uploadedUrl = await firebaseStorageHelper.uploadFile(file, 'XeroList/${utils.getTodayDate().replaceAll('/', ',')}', '${getFileName(file)}',);
      }
      print("Url: $uploadedUrl");
      // Add the uploaded URL to the list
      if (uploadedUrl != null) {
        uploadedUrls.add(uploadedUrl);
        progress+=totalprogress;
        loadingDialog.showProgressLoading(progress, 'Uploading Files...');
      }
    }
    // Hide progress loading bar after uploading files
    print('Uploaded Urls: ${uploadedUrls}');

    int? count = await realTimeDatabase.incrementValue('Xerox/XeroxHistory');
    print("Count: $count");

    DocumentReference userRef = FirebaseFirestore.instance.doc('/UserDetails/${utils.getCurrentUserUID()}/XeroxHistory/$count');

    Map<String, dynamic> uploadData = {'ID': count,'Date': utils.getTodayDate(),'Name': _nameController.text, 'Mobile Number': _mobilenumberController.text, 'Email': email,
      'No of Pages': pages, 'Calculated Price': _calculatedPrice, 'Transaction ID': _transactionidController.text,'Uploaded Files': uploadedUrls,
      'Description':_descriptionController.text};

    List<String> sheetData = [_nameController.text, _mobilenumberController.text, email, pages.toString(), _calculatedPrice.toString(), _transactionidController.text,_descriptionController.text];
    sheetData.addAll(uploadedUrls);

    await fireStoreService.uploadMapDataToFirestore(uploadData, userRef);

    // Once all files are uploaded, update the Google Sheets
    userSheetsApi.updateCell(sheetData);
    loadingDialog.showProgressLoading(progress+0.05, 'Uploading Files...');
    utils.deleteFolder('/data/user/0/com.neelam.FindAny/cache/uploadedFiles/');
    EasyLoading.dismiss();

    // Hide progress loading bar after updating Google Sheets
    utils.showToastMessage('Request submitted', context);
    Navigator.pop(context);
    // Optionally, you can use the uploadedUrls list for further processing or display
  }

  String getFileName(File file) {
    return path.basename(file.path);
  }

  Future<void> _uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
      );
      print('Result: $result');
      if (result != null) {
        Directory cacheDir = await getTemporaryDirectory();
        Directory uploadDir = Directory('${cacheDir.path}/uploadedFiles');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }
        print('uploadDir: ${uploadDir.path}');
        for (var file in result.files) {
          String fileName = file.name;
          File pickedFile = File(file.path!);
          File newFile = File('${uploadDir.path}/$fileName');
          await pickedFile.copy(newFile.path);
          String filePath = newFile.path;
          print('File uploaded: $fileName at $filePath');
          setState(() {
            _uploadedFiles[fileName] = filePath;
          });
        }
        utils.deleteFolder('/data/user/0/com.neelam.FindAny/cache/file_picker/');
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (error) {
      print('Error opening file: $error');
    }
  }
  @override
  void dispose() {
    // Dispose the controllers when the widget is disposed
    _bindingFileController.dispose();
    _singleSideFileController.dispose();
    super.dispose();
  }


}
