import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // generado automáticamente
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'map_widget.dart';
import 'sign_in_screen.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // generado por el CLI
  );

  // Initialize Firebase Messaging
  //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);



  // Request permissions
  await FirebaseMessaging.instance.requestPermission();

  //FirebaseMessaging.instance.subscribeToTopic('database-updates');
  // Get FCM token
  //final fcmToken = await FirebaseMessaging.instance.getToken();
  //print('FCM Token: $fcmToken');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Festidriver 2',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const MyHomePage(title: 'Festidriver 2');
          } else {
            return const SignInScreen();
          }
        },
      ),
    );
  }
}

class DriversTab extends StatefulWidget {
  @override
  _DriversTabState createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool isDriverMode = false;
  final DatabaseReference _driversRef = FirebaseDatabase.instance.ref().child("drivers");

  String selectedVehicle = 'Moto';
  String selectedUniversity = 'Unillanos Barcelona';
  final TextEditingController whatsappController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if user is in driver mode
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _driversRef.child(user.uid).get().then((snapshot) {
        if (snapshot.exists) {
          setState(() => isDriverMode = true);
        }
      });
    }
  }

  void _activateDriverMode(String vehicle, String university, String whatsapp) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final driverData = {
      'id': user.uid,
      'userId': user.uid,
      'userName': user.displayName ?? 'Unknown',
      'userEmail': user.email ?? '',
      'userPhoto': user.photoURL ?? '',
      'university': university,
      'vehicle': vehicle,
      'whatsapp': whatsapp,
      'isActive': true,
      'createdAt': ServerValue.timestamp,
      'lastUpdated': ServerValue.timestamp,
    };
    await _driversRef.child(user.uid).set(driverData);
    setState(() => isDriverMode = true);
  }

  void _deactivateDriverMode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _driversRef.child(user.uid).remove();
    setState(() => isDriverMode = false);
  }

  void _showActivationModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activar modo conductor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedVehicle,
              items: ['Moto', 'Carro'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => selectedVehicle = v!),
              decoration: InputDecoration(labelText: 'Tipo de vehículo'),
            ),
            DropdownButtonFormField<String>(
              value: selectedUniversity,
              items: ['Unillanos Barcelona', 'Unillanos San Antonio'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (u) => setState(() => selectedUniversity = u!),
              decoration: InputDecoration(labelText: 'Universidad de origen'),
            ),
            TextFormField(
              controller: whatsappController,
              decoration: InputDecoration(labelText: 'Whatsapp'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _activateDriverMode(selectedVehicle, selectedUniversity, whatsappController.text);
              Navigator.pop(context);
            },
            child: Text('Activar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(
            onPressed: isDriverMode ? _deactivateDriverMode : _showActivationModal,
            child: Text(isDriverMode ? 'Desactivar modo conductor' : 'Activar modo conductor'),
            style: TextButton.styleFrom(
              backgroundColor: isDriverMode ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),

          //MapWidget(),

          StreamBuilder(
            stream: _driversRef.onValue.asBroadcastStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                final data = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );

                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final driversList = data.values.toList();
                driversList.sort((a, b) {
                  final aIsCurrent = a["userId"] == currentUserId;
                  final bIsCurrent = b["userId"] == currentUserId;
                  if (aIsCurrent && !bIsCurrent) return -1;
                  if (!aIsCurrent && bIsCurrent) return 1;
                  return 0;
                });

                return Expanded(
                  child: ListView(
                    children: driversList.map((driver) {
                      final driverMap = Map<String, dynamic>.from(driver);
                      final vehicle = driverMap["vehicle"] ?? "Carro";
                      final seats = vehicle == "Moto" ? 1 : 3;
                      return InkWell(
                        onTap: () async {
                          final whatsapp = driverMap["whatsapp"];
                          if (whatsapp != null) {
                            final url = 'whatsapp://send?phone=57$whatsapp';
                            launch(url);
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(driverMap["userPhoto"] ?? ''),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        driverMap["userName"],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text("Desde: ${driverMap["university"]}"),
                                Text("Vehículo: $vehicle"),
                                const Text("Disponible"),
                                Text("$seats asientos disponibles"),
                                Text(driverMap["whatsapp"] ?? ''),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
              return const Center(child: Text("No hay conductores aún"));
            },
          )
        ],
      ),
    );
  }
}

class PassengersTab extends StatefulWidget {
  @override
  _PassengersTabState createState() => _PassengersTabState();
}

class _PassengersTabState extends State<PassengersTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Center(
      child: Text('Vista de Pasajeros'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    // Handle foreground messages
   /*  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    }); */

  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter--;
    });
  }



  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: const Color(0x1A3461FC),
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email ?? widget.title),
          actions: [
            IconButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Conductores'),
              Tab(text: 'Pasajeros'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DriversTab(),
            PassengersTab(),
          ],
        ),
      ),
    );
  }
}
