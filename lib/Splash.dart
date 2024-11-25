import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String deviceId = "Unknown"; // To store deviceId
  String recDeviceId="Unknown";
  @override
  void initState() {
    super.initState();
    sendPostRequest(); // Send the request when the splash screen loads
  }

  // Method to send the POST request
  Future<void> sendPostRequest() async {
    // Fetch dynamic device information
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    setState(() {
      deviceId = androidInfo.id ?? "Unknown"; // Save deviceId
    });

    const url = 'http://devapiv4.dealsdray.com/api/v2/user/device/add';

    Map<String, dynamic> requestBody = {
      "deviceType": "android",
      "deviceId": deviceId,
      "deviceName": androidInfo.model ?? "Unknown",
      "deviceOSVersion": androidInfo.version.release ?? "Unknown",
      "deviceIPAddress": "11.433.445.66", // Replace with actual IP fetching logic if needed
      "lat": 9.9312,
      "long": 76.2673,
      "buyer_gcmid": "",
      "buyer_pemid": "",
      "app": {
        "version": "1.20.5",
        "installTimeStamp": "2022-02-10T12:33:30.696Z",
        "uninstallTimeStamp": "2022-02-10T12:33:30.696Z",
        "downloadTimeStamp": "2022-02-10T12:33:30.696Z"
      }
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Log the response if needed (optional)
      print("Response: ${response.statusCode} - ${response.body}");
      var parsedResponse = jsonDecode(response.body);

      // Access the deviceId from the response data
      recDeviceId = parsedResponse['data']['deviceId'];
    } catch (e) {
      print("Error: $e"); // Log error (optional)
    } finally {
      // Navigate to the next screen with the deviceId
      navigateToNextScreen(recDeviceId);
    }
  }

  // Method to navigate to the next screen
  void navigateToNextScreen(String recDeviceId) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userId:"" ,deviceId: recDeviceId)), // Pass deviceId to HomeScreen
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image for the splash screen
          Image.asset(
            'assets/splash_image.png', // Replace with your image path in the assets folder
            fit: BoxFit.cover,
          ),
          // Loading spinner at the center
          const Center(
            child: CircularProgressIndicator(), // Dotted circle loading spinner
          ),
        ],
      ),
    );
  }
}

// A simple HomeScreen as the next screen

class HomeScreen extends StatefulWidget {
  final String deviceId;

  const HomeScreen({super.key, required this.deviceId, required String userId,});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
 // Tracks whether Phone is selected
  bool isPhoneSelected = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();


  // Method to send OTP request
  Future<void> sendOtpRequest() async {
    const url = 'http://devapiv4.dealsdray.com/api/v2/user/otp';

    // JSON payload

    Map<String, dynamic> requestBody = {
      "mobileNumber": _mobileController.text,
      "deviceId": widget.deviceId,
    };

    try {
      print(widget.deviceId);
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData["status"] == 1) {
          // Save the userId and deviceId
          String userId = responseData["data"]["userId"];
          String newDeviceId = responseData["data"]["deviceId"];

          // Navigate to the OTP Verification Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                mobileNumber: _mobileController.text,
                userId: userId,
                deviceId: newDeviceId,
              ),
            ),
          );
        } else {
          // Show an error message if OTP not sent successfully
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData["data"]["message"] ?? "Error")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send OTP")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/ic_launcher.png', // Replace with your logo asset
                    height: 100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Heading Text
            const Text(
              "Glad to see you!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle Text
            const Text(
              "Please provide your credentials to proceed",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // Single Toggle Button for Phone and Email
            ToggleButtons(
              isSelected: [isPhoneSelected, !isPhoneSelected],
              onPressed: (int index) {
                setState(() {
                  isPhoneSelected = index == 0;
                });
              },
              borderRadius: BorderRadius.circular(20),
              selectedColor: Colors.white,
              fillColor: Colors.red,
              color: Colors.grey,
              constraints: const BoxConstraints(
                minHeight: 40.0,
                minWidth: 70.0,
              ),
              children: const [
                Text("Phone"),
                Text("Email"),
              ],
            ),
            const SizedBox(height: 30),

            // Conditional Rendering of Fields
            if (isPhoneSelected)
              Column(
                children: [
                  // Phone Input Field
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone",
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Send Code Button
                  ElevatedButton(
                    onPressed: sendOtpRequest, // Triggering the OTP request logic
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "SEND CODE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  // Email Input Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button for Email
                  ElevatedButton(
                    onPressed: submitEmailLogin, // Add email login logic
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "LOGIN",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }



  void submitEmailLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty) {
      // Show error if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email")),
      );
      return;
    }

    try {
      // Make the API call
      final response = await http.post(
        Uri.parse('http://devapiv4.dealsdray.com/api/v2/user/email/referral'),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 202 || response.statusCode == 409) {
        // If the server returns a 202 OK accepted
        var responseData = json.decode(response.body);
        print(responseData['data']['message']);
        // Check the response message
        if (responseData['data']['message'] == 'Email exists') {
          // If email exists, navigate to the Main Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()), // Replace with your main screen
          );
        } else if (responseData['data']['message'] == 'User Not Found') {
          // If user is not found, navigate to the Register Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen(userId:"")), // Replace with your Register screen
          );
        }
      } else {
        // If the server returns a non-200 response
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to log in. Please try again.")),
        );
      }
    } catch (error) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred. Please try again.")),
      );
    }
  }
}


class OTPVerificationScreen extends StatefulWidget {
  final String mobileNumber;
  final String userId;
  final String deviceId;

  const OTPVerificationScreen({
    super.key,
    required this.mobileNumber,
    required this.userId,
    required this.deviceId,
  });

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());
  late int timerSeconds;

  @override
  void initState() {
    super.initState();
    timerSeconds = 120; // Set timer to 2 minutes
    startTimer();
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (timerSeconds > 0) {
        setState(() {
          timerSeconds--;
        });
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submitOTP() async {
    // Capture OTP from the TextControllers
    String otp = _otpControllers.map((controller) => controller.text).join();

    // Prepare the API URL
    String apiUrl = "http://devapiv4.dealsdray.com/api/v2/user/otp/verification";

    // Prepare the request body
    Map<String, String> requestBody = {
      "otp": otp,
      "userId": widget.userId,
      "deviceId": widget.deviceId,
    };

    // Send a POST request to the API
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: json.encode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Decode the response body
        var responseData = json.decode(response.body);

        // Handle different status codes from the API response
        if (responseData['status'] == 1) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Incomplete Registration'),
              content: const Text('Please complete your registration first.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    // Navigate to the Register Screen and pass userId
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: const Text('Register'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        }
        else if (responseData['status'] == 2) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('OTP Expired'),
              content: const Text('The OTP has expired. Please request a new one.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (responseData['status'] == 3) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Invalid OTP'),
              content: const Text('The OTP you entered is invalid. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Handle other cases or unexpected responses
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unknown Error'),
              content: const Text('Something went wrong, please try again later.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // If the server responds with an error (not 200)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content:const Text('Failed to send OTP. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Handle any errors during the API request (e.g., no internet)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:const Text('Error'),
          content: const Text('Something went wrong. Please check your internet connection or try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime =
        "${(timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(timerSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("OTP Verification"),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
            margin: const EdgeInsets.only(bottom: 50),
              child: const Image(
                image: AssetImage('assets/otp_image.png'),
                height: 150,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "OTP Verification",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "We have sent a unique OTP number to your mobile ${widget.mobileNumber}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: _otpControllers[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedTime, style: const TextStyle(fontSize: 16)),
                TextButton(
                  onPressed: submitOTP, // Trigger OTP submission
                  child: const Text("Submit"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class RegisterScreen extends StatefulWidget {
  final String userId;

  const RegisterScreen({super.key, required this.userId});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false; // Track password visibility
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController referralCodeController = TextEditingController();

  // Function to handle the registration logic
  Future<void> submitRegistration() async {
    const String apiUrl = 'http://devapiv4.dealsdray.com/api/v2/user/email/referral';

    int? referralCode = null;  // This is a nullable int, and it can hold null
    if(referralCodeController.text.isEmpty){
      referralCode=null;
    }else{referralCode=int.parse(referralCodeController.text);
    }
    // Prepare data to send in the API request
    final Map<String, dynamic> data = {
      "email": emailController.text,
      "password": passwordController.text,
      "referralCode": referralCode,
      "userId": widget.userId,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode==409) {
        if (responseBody["status"] == 1 && responseBody["data"]["message"] == "Successfully Added") {
          // If registration is successful, navigate to HomeScreen
          showErrorDialog("Succesfully added go to mail to login");

          Future.delayed(const Duration(seconds: 1), (){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(deviceId: "", userId: widget.userId),
            ),
          );
        });

        } else if (responseBody["status"] == 0 && responseBody["data"]["message"] == "Email exists") {

          // If registration is successful, navigate to HomeScreen
          showErrorDialog("Already Registered - SignIn using email: ${responseBody["data"]["message"]}");  Future.delayed(const Duration(seconds: 1), (){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HomeScreen(deviceId: "", userId: widget.userId),
              ),
            );
          });

        }
          else {
          // Handle unsuccessful registration or invalid response
          showErrorDialog("Registration failed: ${responseBody["data"]["message"]}");
        }
      } else {
        // Handle API error response
        showErrorDialog("Something went wrong. Please try again later.");
      }
    } catch (error) {
      // Handle network error or other issues
      showErrorDialog("Failed to connect. Please check your internet connection.");
    }
  }

  // Function to show error dialog
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/ic_launcher.png', // Add your logo asset path
                    height: 100,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // Title
            const Text(
              "Let's Begin!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            const Text(
              'Please enter your credentials to proceed',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Email Field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Your Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            // Password Field with Visibility Toggle
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Create Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible, // Update obscureText based on visibility state
            ),

            const SizedBox(height: 20),

            // Referral Code Field (Optional)
            TextField(
              controller: referralCodeController,
              decoration: const InputDecoration(
                labelText: 'Referral Code (Optional)',
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            ElevatedButton(
              onPressed: submitRegistration, // Call the submitRegistration function
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  List categoryItems = [];
  List productItems = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://devapiv4.dealsdray.com/api/v2/user/home/withoutPrice'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        categoryItems = data['data']['category'];
        productItems = data['data']['products'];
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search here',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
          ),
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      // Adding Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.red,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_circle, size: 80, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'User Name',  // Customize with user's name or info
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                // Handle navigation to Home screen
              },
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text('Categories'),
              onTap: () {
                // Handle navigation to Categories screen
              },
            ),
            ListTile(
              leading: Icon(Icons.local_offer),
              title: Text('Deals'),
              onTap: () {
                // Handle navigation to Deals screen
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text('Cart'),
              onTap: () {
                // Handle navigation to Cart screen
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                // Handle navigation to Profile screen
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Handle navigation to Settings screen
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 10), () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen(userId:"" ,deviceId:"")), // Pass deviceId to HomeScreen
                  );
                });
                // Handle logout
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // KYC Notificationn
            // Categories Section
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryItems.length,
                itemBuilder: (context, index) {
                  return CategoryItem(
                    iconUrl: categoryItems[index]['icon'],
                    label: categoryItems[index]['label'],
                  );
                },
              ),
            ),
            SizedBox(height: 10),

            // Exclusive for You Section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXCLUSIVE FOR YOU',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: productItems.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        productImage: productItems[index]['icon'],
                        productLabel: productItems[index]['label'],
                        productOffer: productItems[index]['offer'],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Deals'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String iconUrl;
  final String label;

  const CategoryItem({super.key, required this.iconUrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          child: Image.network(iconUrl, width: 30, height: 30, fit: BoxFit.contain),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productImage;
  final String productLabel;
  final String productOffer;

  const ProductCard({super.key, required this.productImage, required this.productLabel, required this.productOffer});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              image: DecorationImage(
                image: NetworkImage(productImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productLabel, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 5),
                const Text('₹999', style: TextStyle(fontSize: 14, color: Colors.red)),
                Text('$productOffer% Off', style:const TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
