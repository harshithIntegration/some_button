
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planotech/Employee/addleads.dart';
import 'package:planotech/Employee/addreport.dart';
import 'package:planotech/admin/allattendance.dart';
import 'package:planotech/admin/analytics.dart';
import 'package:planotech/admin/viewattendance.dart';
import 'package:planotech/admin/viewleads.dart';
import 'package:planotech/dashboard.dart';
import 'package:planotech/logout.dart';
import 'package:planotech/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planotech/notificationservice.dart';

var attendanceStatus = '';

class EmployeeDashboard extends StatefulWidget {
  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  NotificationServices notificationServices = NotificationServices();
  void initializeNotifications() async {
    await notificationServices.requestNotificationPermission(context);
    notificationServices.isTokenRefreshed((newToken) {
      _sendTokenToBackend(newToken);
    });
    String? deviceToken = await notificationServices.getDeviceToken();
    if (deviceToken != null) {
      print("==========");
      print("Device token: $deviceToken");
      print("==========");
      _sendTokenToBackend(deviceToken); // Send the device token to backend
    } else {
      print("Failed to get device token.");
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    var empId = this.empId; // Ensure this is fetched correctly
    var url = Uri.parse(
        'http://13.201.213.5:4040/emp/employeenotificationtoken?empId=$empId&token=$token');

    var headers = {"Content-Type": "application/json"};

    var response = await http.post(url, headers: headers);
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      if (responseData['status'] == true) {
        print('Token added successfully: ${responseData['message']}');
      } else {
        print('Failed to add token: ${responseData['message']}');
      }
    } else {
      print('Failed to send token. Error: ${response.reasonPhrase}');
    }
  }

  



  @override
  void initState() {
    super.initState();
    fetchStoredResponse();
    _initPrefs();
    initializeNotifications();
  }

  int _selectedIndex = 0;
  SharedPreferences? _prefs;
  late String _punchinTime;
  Map<String, dynamic> response = {};
  bool _isButtonDisabled = false;
  Map<String, dynamic>? result;

  get empId => response['body']['userId']??'njnj';
  get name => response['body']['userName']??'hars';
  get department => response['body']['userDepartment']??'hhh';

  Future<void> fetchAttendanceAnalytics() async {
    final attendanceAnalytics = AttendanceAnalytics();
    String Id = empId.toString();
    final now = DateTime.now();
    print("-=-=-=-=-=-");
    print(Id);
    print("-=-=-=-=-=-");

    final analytics = await attendanceAnalytics.getAttendanceAnalytics(
      Id,
      now.month,
      now.year, // Get analytics for current month and year
    );

    // Update the state with fetched attendance analytics
    setState(() {
      result = analytics;
    });
  }

  Future<void> fetchStoredResponse() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedResponse = prefs.getString('response');
    if (storedResponse != null) {
      try {
        setState(() {
          response = json.decode(storedResponse);
        });
        fetchAttendanceAnalytics();
      } catch (e) {
        print("Error decoding stored response: $e");
      }
    } else {
      print("No stored response found.");
    }
    print(response);
  }

  void _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _punchinTime = _prefs!.getString('punchinTime') ?? '';

    // Check if punch-in is already done today
    if (_punchinTime.isNotEmpty) {
      DateFormat('hh:mm a').parse(_punchinTime);

      if (true) {
        setState(() {});
      }
    }
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _punchin() async {
    if (_prefs == null) {
      _initPrefs();
    }

    setState(() {
      _isButtonDisabled = true; // Disable buttons
    });

    DateTime now = DateTime.now();
    String loginTime = DateFormat('hh:mm a').format(now);
    String dayOfWeek = DateFormat('EEEE').format(now);

    _prefs!.setString('punchinTime', loginTime);
    _prefs!.setString('punchinDay', dayOfWeek);

    setState(() {
      _punchinTime = loginTime;
      // Disable punch-in button
    });

    // Get current location
    Position position = await _getGeoLocationPosition();
    String location = 'Lat: ${position.latitude}, Long: ${position.longitude}';

    // Get address from coordinates
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    String address =
        '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

    // Calculate attendance status
    String attendanceStatus = '';
    TimeOfDay currentTime = TimeOfDay.fromDateTime(now);
    print(currentTime);

    TimeOfDay specifiedTime = TimeOfDay(hour: 9, minute: 45);
    print(specifiedTime);
    if (currentTime.hour < specifiedTime.hour ||
        (currentTime.hour == specifiedTime.hour &&
            currentTime.minute <= specifiedTime.minute)) {
      attendanceStatus = 'Punch In On Time ';
    } else {
      attendanceStatus = 'Punch In Late';
    }

    await _sendDataToBackend(
        loginTime, location, address, attendanceStatus, dayOfWeek);

    setState(() {
      _isButtonDisabled = false;
    });
  }

  void _punchout() async {
    if (_prefs == null) {
      _initPrefs();
    }

    setState(() {
      _isButtonDisabled = true;
    });

    setState(() {});

    DateTime now = DateTime.now();
    String punchoutTime = DateFormat('hh:mm a').format(now);
    String dayOfWeek = DateFormat('EEEE').format(now);

    _prefs!.setString('punchoutTime', punchoutTime);
    _prefs!.setString('punchoutDay', dayOfWeek);

    setState(() {});

    Position position = await _getGeoLocationPosition();
    String location = 'Lat: ${position.latitude}, Long: ${position.longitude}';

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    String address =
        '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

    String attendanceStatus = '';
    TimeOfDay currentTime = TimeOfDay.fromDateTime(now);
    print(currentTime);

    TimeOfDay specifiedTime = TimeOfDay(hour: 18, minute: 30);
    print(specifiedTime);
    if (currentTime.hour < specifiedTime.hour ||
        (currentTime.hour == specifiedTime.hour &&
            currentTime.minute <= specifiedTime.minute)) {
      attendanceStatus = 'Punch Out Early';
    } else {
      attendanceStatus = 'Punch Out On Time';
    }

    await _sendDataToBackend(
        punchoutTime, location, address, attendanceStatus, dayOfWeek);

    setState(() {
      _isButtonDisabled = false;
    });
  }

  Future<void> _sendDataToBackend(String time, String location, String address,
      String attendanceStatus, String dayOfWeek) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
            backgroundColor: Colors.blueGrey,
          ),
        );
      },
    );

    var url = Uri.parse('http://13.201.213.5:4040/emp/addemployeeattendence');

    // Encode data in JSON format
    var body = jsonEncode({
      "employeeId": empId,
      "date": DateFormat('dd-MM-yyyy').format(DateTime.now()),
      "time": time,
      "latitude": location.split(',')[0].trim(),
      "longitude": location.split(',')[1].trim(),
      "address": address,
      "attendanceStatus": attendanceStatus,
      "department": department,
      "name": name,
      "attendance": 'Present',
      "day": dayOfWeek,
    });
    print(body);
    var headers = {"Content-Type": "application/json"};

    // Send POST request
    var response = await http.post(url, body: body, headers: headers);
    print(response.body);
    if (response.statusCode == 200) {
      print('Data sent successfully!');
      var responseData = json.decode(response.body);
      Navigator.of(context).pop();
      if (responseData['status'] == true) {
        // Show dialog with attendance status
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Attendance Status',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              content: Text(
                attendanceStatus,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      print('Failed to send data. Error: ${response.reasonPhrase}');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/blue.jpg',
            fit: BoxFit.cover,
          ),
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 5),
                  Image.asset(
                    'assets/pp.png',
                    height: 80,
                    width: 400,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Welcome ${name ?? ''}',
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35.0),
                  Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: result != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Present Circle
                              Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: 90,
                                        width: 90,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.greenAccent,
                                              Colors.lightGreen
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color.fromARGB(
                                                      255, 108, 201, 156)
                                                  .withOpacity(0.4),
                                              blurRadius: 15,
                                              spreadRadius: 5,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: CircularProgressIndicator(
                                            value: result!['Present'] / 27,
                                            strokeWidth: 10,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.greenAccent),
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: Duration(milliseconds: 500),
                                        child: Text(
                                          '${result!['Present']}',
                                          key: ValueKey(result!['Present']),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Present',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              // Absent Circle
                              Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: 90,
                                        width: 90,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.redAccent,
                                              Colors.deepOrangeAccent
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.redAccent
                                                  .withOpacity(0.4),
                                              blurRadius: 15,
                                              spreadRadius: 5,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: CircularProgressIndicator(
                                            value: result!['Absent'] / 6,
                                            strokeWidth: 10,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.redAccent),
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: Duration(milliseconds: 500),
                                        child: Text(
                                          '${result!['Absent']}',
                                          key: ValueKey(result!['Absent']),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Absent',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              // Late Circle
                              Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: 90,
                                        width: 90,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orangeAccent,
                                              Colors.amber
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orangeAccent
                                                  .withOpacity(0.4),
                                              blurRadius: 15,
                                              spreadRadius: 5,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: SizedBox(
                                          height: 100,
                                          width: 100,
                                          child: CircularProgressIndicator(
                                            value: result!['Late'] / 27,
                                            strokeWidth: 10,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.orangeAccent),
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: Duration(milliseconds: 500),
                                        child: Text(
                                          '${result!['Late']}',
                                          key: ValueKey(result!['Late']),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Late',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blueAccent),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20.0),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildCompactButton(
                        icon: Icons.add,
                        label: 'Add Leads',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EmployeeRegistrationForm(empId),
                            ),
                          );
                        },
                      ),
                      _buildCompactButton(
                        icon: Icons.leaderboard_sharp,
                        label: 'View Leads',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewLeadsPage(),
                            ),
                          );
                        },
                      ),
                      _buildCompactButton(
                        icon: Icons.feedback_outlined,
                        label: 'Add Report',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportSubmissionScreen(
                                  response['body']?['userId'],
                                  response['body']?['userName'],
                                  response['body']?['userDepartment']),
                            ),
                          );
                        },
                      ),
                      _buildCompactButton(
                        icon: Icons.table_view_rounded,
                        label: 'View Attendance',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewAttendanceById(empId),
                            ),
                          );
                        },
                      ),
                      if (department == "HR")
                        _buildCompactButton(
                          icon: Icons.view_comfortable,
                          label: 'View All Attendance',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendancePage1(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactButton(
                          icon: Icons.login,
                          label: 'Punch In',
                          onTap: _isButtonDisabled ? () {} : _punchin,
                        ),
                        const SizedBox(width: 20),
                        _buildCompactButton(
                          icon: Icons.logout,
                          label: 'Punch Out',
                          onTap: _isButtonDisabled ? () {} : _punchout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 30, 93, 209),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Dashboard(),
          ),
        );
      } else if (_selectedIndex == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
        );
      } else if (_selectedIndex == 2) {
        _showLogoutConfirmationDialog();
      }
    });
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Logout(),
                  ),
                );
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}


Widget _buildCompactButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50, // Reduced height for compact size
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Lighter button background
        borderRadius: BorderRadius.circular(15.0), // Soft, rounded corners
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.0, 
            ),
          ),
        ],
      ),
    ),
  );
}
