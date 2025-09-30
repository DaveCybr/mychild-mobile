import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    final loc = Provider.of<LocationService>(context, listen: false);
    if (auth.token != null) loc.startTracking(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final loc = Provider.of<LocationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Child Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.logout();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Device tracking is active'),
            if (loc.current != null) ...[
              Text('Lat: \${loc.current!.latitude}'),
              Text('Lng: \${loc.current!.longitude}'),
            ],
          ],
        ),
      ),
    );
  }
}
