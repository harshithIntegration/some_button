// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';

// class Reportpage extends StatefulWidget {
//   final int empId;
//   Reportpage(this.empId);

//   @override
//   _ReportpageState createState() => _ReportpageState();
// }

// class _ReportpageState extends State<Reportpage> {
//   List<dynamic> _userList = [];
//   List<dynamic> _filteredUserList = [];
//   bool _isLoading = false;
//   DateTime? _selectedDate;

//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }

//   Future<void> fetchData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     final response = await http.post(
//       Uri.parse('http://13.201.213.5:4040/admin/fetchdailyemployeereportbyid?empId=${widget.empId}'),
//       headers: {
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode(<String, dynamic>{'empId': widget.empId}),
//     );

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);
//       setState(() {
//         _userList = data['userList'] ?? [];
//         _filteredUserList = _userList;
//         _isLoading = false;
//       });
//     } else {
//       setState(() {
//         _isLoading = false;
//       });
//       throw Exception('Failed to load data');
//     }
//   }

//   void filterByDate(DateTime? selectedDate) {
//     setState(() {
//       _selectedDate = selectedDate;
//       if (_selectedDate == null) {
//         _filteredUserList = List.from(_userList);
//       } else {
//         _filteredUserList = _userList.where((user) {
//           try {
//             final dateParts = (user['date'] ?? '').split('-');
//             if (dateParts.length == 3) {
//               final day = int.tryParse(dateParts[0]);
//               final month = int.tryParse(dateParts[1]);
//               final year = int.tryParse(dateParts[2]);
//               if (day != null && month != null && year != null) {
//                 final userDate = DateTime(year, month, day);
//                 return userDate.toLocal().isAtSameMomentAs(_selectedDate!.toLocal());
//               }
//             }
//             return false;
//           } catch (e) {
//             print('Error parsing date: $e');
//             return false;
//           }
//         }).toList();
//       }
//     });
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime.now(),
//       firstDate: DateTime(2015, 8),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//       filterByDate(picked);
//     }
//   }

//   void _openImageDialog(String imageUrl) {
//     showDialog(
//       context: context,
//       builder: (_) => Dialog(
//         child: InteractiveViewer(
//           boundaryMargin: EdgeInsets.all(20.0),
//           minScale: 0.1,
//           maxScale: 5.0,
//           child: Image.network(imageUrl),
//         ),
//       ),
//     );
//   }

//   // Future<void> _openFile(String fileUrl) async {
//   //   try {
//   //     final response = await http.get(Uri.parse(fileUrl));
//   //     if (response.statusCode == 200) {
//   //       final fileName = fileUrl.substring(fileUrl.lastIndexOf('/') + 1);
//   //       final directory = await getApplicationDocumentsDirectory();
//   //       final filePath = '${directory.path}/$fileName';

//   //       final file = File(filePath);
//   //       await file.writeAsBytes(response.bodyBytes);

//   //       // Open the file
//   //       final result = await OpenFile.open(filePath);
//   //       if (result.type != ResultType.done) {
//   //         ScaffoldMessenger.of(context).showSnackBar(
//   //           SnackBar(content: Text('Could not open the file')),
//   //         );
//   //       }
//   //     } else {
//   //       throw Exception('Failed to download file');
//   //     }
//   //   } catch (e) {
//   //     print('Error opening file: $e');
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('An error occurred while opening the file')),
//   //     );
//   //   }
//   // }

//   Icon _getFileIcon(String extension) {
//     switch (extension) {
//       case 'pdf':
//         return Icon(Icons.picture_as_pdf, color: Colors.red);
//       case 'doc':
//       case 'docx':
//         return Icon(Icons.description, color: Colors.blue);
//       case 'xls':
//       case 'xlsx':
//         return Icon(Icons.table_chart, color: Colors.green);
//       case 'jpg':
//       case 'jpeg':
//       case 'png':
//         return Icon(Icons.image, color: Colors.orange);
//       default:
//         return Icon(Icons.insert_drive_file, color: Colors.grey);
//     }
//   }

//   Widget _buildReportItem(dynamic user) {
//     final date = user['date'] ?? 'No date';
//     final report = user['report'] ?? '';
//     final imageUrl = user['imageLink'];
//     // final fileUrl = user['documentLink'];
//     // final fileExtension = fileUrl != null ? fileUrl.split('.').last : '';

//     return Card(
//       color: Colors.grey.shade200,
//       margin: EdgeInsets.all(8.0),
//       elevation: 3.0,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ListTile(
//             title: Text('Date: $date'),
//             subtitle: Text('Report: $report'),
//           ),
//           SizedBox(height: 8.0),
//           if (imageUrl != null && imageUrl.isNotEmpty)
//             Row(
//               children: [
//                 Expanded(
//                   child: InkWell(
//                     onTap: () => _openImageDialog(imageUrl),
//                     child: Row(
//                       children: [
//                         Icon(Icons.image),
//                         SizedBox(width: 8.0),
//                         Expanded(
//                           child: Text(
//                             'Image: $imageUrl',
//                             style: TextStyle(
//                               fontSize: 14.0,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.brown,
//                             ),
//                             overflow: TextOverflow.visible,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           // SizedBox(height: 8.0),
//           // if (fileUrl != null && fileUrl.isNotEmpty)
//           //   Row(
//           //     children: [
//           //       Expanded(
//           //         child: InkWell(
//           //           onTap: () => _openFile(fileUrl), 
//           //           child: Row(
//           //             children: [
//           //               _getFileIcon(fileExtension),
//           //               SizedBox(width: 8.0),
//           //               Expanded(
//           //                 child: Text(
//           //                   'File: $fileUrl',
//           //                   style: TextStyle(
//           //                     fontSize: 14.0,
//           //                     fontWeight: FontWeight.bold,
//           //                     color: Colors.blueGrey,
//           //                   ),
//           //                   overflow: TextOverflow.visible,
//           //                 ),
//           //               ),
//           //             ],
//           //           ),
//           //         ),
//           //       ),
//           //     ],
//           //   ),
//           SizedBox(height: 16.0),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _isLoading
//           ? Center(
//               child: CircularProgressIndicator(),
//             )
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: TextFormField(
//                     readOnly: true,
//                     onTap: () async {
//                       final selectedDate = await showDatePicker(
//                         context: context,
//                         initialDate: _selectedDate ?? DateTime.now(),
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime.now(),
//                       );
//                       if (selectedDate != null) {
//                         _selectDate(context);
//                       }
//                     },
//                     controller: TextEditingController(
//                       text: _selectedDate != null
//                           ? '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
//                           : '',
//                     ),
//                     decoration: const InputDecoration(
//                       labelText: 'Filter by Date',
//                       border: OutlineInputBorder(),
//                       suffixIcon: Icon(Icons.calendar_today),
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: _filteredUserList.isEmpty
//                       ? Center(
//                           child: Text(
//                             'No data found for selected date.',
//                             style: TextStyle(fontSize: 18.0),
//                           ),
//                         )
//                       : ListView.builder(
//                           itemCount: _filteredUserList.length,
//                           itemBuilder: (context, index) {
//                             return _buildReportItem(_filteredUserList[index]);
//                           },
//                         ),
//                 ),
//               ],
//             ),
//     );
//   }
// }



import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class Reportpage extends StatefulWidget {
  final int empId;
  Reportpage(this.empId);

  @override
  _ReportpageState createState() => _ReportpageState();
}

class _ReportpageState extends State<Reportpage> {
  List<dynamic> _userList = [];
  List<dynamic> _filteredUserList = [];
  bool _isLoading = false;
  DateTime? _selectedDate;
  final DateTime today = DateTime.now();


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.post(                                                                                              
      
      Uri.parse('http://13.201.213.5:4040/admin/fetchdailyemployeereportbyid?empId=${widget.empId}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'empId': widget.empId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        _userList = data['userList'] ?? [];
        _filteredUserList = _userList;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load data');
    }
  }

  Future<void> _downloadFile(String url, BuildContext context) async {
    if (Platform.isAndroid &&
        (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted)) {
      final ValueNotifier<String> _progressNotifier =
          ValueNotifier<String>('Starting download...');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Text('Downloading'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    ValueListenableBuilder<String>(
                      valueListenable: _progressNotifier,
                      builder: (context, progressText, child) {
                        return Text(progressText);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      try {
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final fileName = url.split('/').last;
        final filePath = '${directory.path}/$fileName';

        Dio dio = Dio();
        await dio.download(
          url,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100).toStringAsFixed(0) + "%";
              _progressNotifier.value = 'Downloading: $progress';
            }
          },
        );

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download completed: $fileName')),
        );

        // Open the file
        OpenFile.open(filePath);
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Storage permission is required to download files.')),
      );
      await openAppSettings();
    }
  }

  void filterByDate(DateTime? selectedDate) {
    setState(() {
      _selectedDate = selectedDate;
      if (_selectedDate == null) {
        _filteredUserList = List.from(_userList);
      } else {
        _filteredUserList = _userList.where((user) {
          try {
            final dateParts = (user['date'] ?? '').split('-');
            if (dateParts.length == 3) {
              final day = int.tryParse(dateParts[0]);
              final month = int.tryParse(dateParts[1]);
              final year = int.tryParse(dateParts[2]);
              if (day != null && month != null && year != null) {
                final userDate = DateTime(year, month, day);
                return userDate.toLocal().isAtSameMomentAs(_selectedDate!.toLocal());
              }
            }
            return false;
          } catch (e) {
            print('Error parsing date: $e');
            return false;
          }
        }).toList();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      filterByDate(picked);
    }
  }

  void _openImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(imageUrl: imageUrl),
      ),
    );
  }


    void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  Future<void> _launchURL(String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      String fileName = url.split('/').last;
      String filePath = '${tempDir.path}/$fileName';

      // Download the file
      await Dio().download(url, filePath);

      // Open the file
      await OpenFile.open(filePath);
    } catch (e) {
      _showSnackbar('Error opening file: $e');
    }
  }

Widget _buildReportItem(dynamic user) {
  // Parse the date string to DateTime object
  final dateStr = user['date'] ?? 'No date';
  final timeStr = user['time'] ?? ''; // Fetch time string
  final report = user['report'] ?? '';
  final imageUrl = user['imageLink'];
  final documentLink = user['documentLink'];

  // Try parsing the date manually if it's in 'DD-MM-YYYY' format
  DateTime? parsedDate;
  try {
    final dateParts = dateStr.split('-');
    if (dateParts.length == 3) {
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      parsedDate = DateTime(year, month, day);
    }
  } catch (e) {
    print('Error parsing date: $e');
  }

  // Format the date and time
  final formattedDate = parsedDate != null
      ? '${parsedDate.day}-${parsedDate.month}-${parsedDate.year}'
      : 'Invalid date';
  final formattedTime = timeStr.isNotEmpty ? timeStr : 'Invalid time'; // Use the time string directly

  return Card(
    color: Colors.grey.shade200,
    margin: EdgeInsets.all(8.0),
    elevation: 3.0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('Date: $formattedDate'),
          subtitle: Text('Time: $formattedTime\nReport: $report'), // Display time correctly
        ),
        
        if (imageUrl != null && imageUrl.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '➮ Click  :  Image: ${imageUrl.split('/').last}',
                        style: TextStyle(
                          color: Color.fromARGB(255, 63, 148, 218),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _openImageViewer(imageUrl);
                          },
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () {
                  _downloadFile(imageUrl, context);
                },
              ),
            ],
          ),
        if (documentLink != null && documentLink.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '➮ Click  :  Document: ${documentLink.split('/').last}',
                        style: TextStyle(
                          color: Color.fromARGB(255, 63, 148, 218),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launchURL(documentLink);
                          },
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () {
                  _downloadFile(documentLink, context);
                },
              ),
            ],
          ),
        SizedBox(height: 16.0),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: true,
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        _selectDate(context);
                      }
                    },
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
                          : '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Filter by Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredUserList.isEmpty
                      ? Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUserList.length,
                          itemBuilder: (context, index) {
                            return _buildReportItem(_filteredUserList[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  ImageViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Viewer'),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}