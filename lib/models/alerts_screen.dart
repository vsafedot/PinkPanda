import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert'; // For JSON decoding
import 'dart:async'; // For train movement simulation

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final DatabaseReference _alertsRef = FirebaseDatabase.instance.reference().child('alerts');
  late List<Station> _stations;
  List<LatLng> _trainPath = [];
  LatLng _trainPosition = const LatLng(20.5937, 78.9629);
  bool _isTrainStopped = false;
  String _trainStatus = 'Train is moving';
  String? _selectedStation;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _startTrainMovement();
  }

  // Load and parse real-world station data (same as before)
  Future<void> _loadStations() async {
    final String data = ''' 
    {
      "type": "FeatureCollection",
      "features": [
        {
          "geometry": {
            "type": "Point",
            "coordinates": [75.4516454, 27.2520587]
          },
          "type": "Feature",
          "properties": {
            "state": "Rajasthan",
            "code": "BDHL",
            "name": "Badhal",
            "zone": "NWR",
            "address": "Kishangarh Renwal, Rajasthan"
          }
        }
      ]
    }
    ''';
    final Map<String, dynamic> jsonData = json.decode(data);
    setState(() {
      _stations = (jsonData['features'] as List).map((e) => Station.fromJson(e)).toList();
      _trainPath = _stations.map((e) => LatLng(e.latitude, e.longitude)).toList();
    });
  }

  // Simulate train movement along the path
  Future<void> _startTrainMovement() async {
    int index = 0;
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isTrainStopped) {
        setState(() {
          _trainStatus = 'Train is stopped';
        });
        timer.cancel();
        return;
      }
      if (index < _trainPath.length) {
        setState(() {
          _trainPosition = _trainPath[index];
          _trainStatus = 'Train is moving';
        });
        index++;
        _sendTrainLocationToFirebase();
      } else {
        timer.cancel();
      }
    });
  }

  // Send train location to Firebase
  void _sendTrainLocationToFirebase() {
    final alertData = {
      'location': {
        'latitude': _trainPosition.latitude,
        'longitude': _trainPosition.longitude,
      },
      'status': _trainStatus,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _alertsRef.push().set(alertData);
  }

  // Stop train movement
  void _stopTrain() {
    setState(() {
      _isTrainStopped = true;
      _trainStatus = 'Train is stopped';
    });
  }

  // Resume train movement
  void _resumeTrain() {
    setState(() {
      _isTrainStopped = false;
      _trainStatus = 'Train is moving';
    });
    _startTrainMovement();
  }

  // Show alert details
  void _showAlertDetails(String alertId) {
    // Fetch alert details using alertId from Firebase and display them
    _alertsRef.child(alertId).once().then((DataSnapshot snapshot) {
      final alert = snapshot.value;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Alert Details'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location: ${alert['location']['latitude']}, ${alert['location']['longitude']}'),
                Text('Status: ${alert['status']}'),
                Text('Time: ${alert['timestamp']}'),
              ],
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2, // Just for demo; replace with real Firebase data later
        itemBuilder: (context, index) {
          final isWarning = index == 0;
          return GestureDetector(
            onTap: () => _showAlertDetails('alert_id_$index'), // Show alert details when tapped
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isWarning ? Colors.orange : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWarning ? Icons.warning : Icons.error,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isWarning
                                    ? 'Track maintenance scheduled'
                                    : 'Signal malfunction detected',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isWarning ? '2 hours ago' : '30 minutes ago',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      isWarning
                          ? 'Regular maintenance work on Platform 1. Expect minor delays.'
                          : 'Technical team has been dispatched. Issue expected to be resolved within 1 hour.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as Read'),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Station {
  final String id;
  final String name;
  final String code;
  final String zone;
  final String state;
  final String address;
  final double latitude;
  final double longitude;

  Station({
    required this.id,
    required this.name,
    required this.code,
    required this.zone,
    required this.state,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'];
    final coordinates = json['geometry']['coordinates'];
    return Station(
      id: properties['code'],
      name: properties['name'],
      code: properties['code'],
      zone: properties['zone'],
      state: properties['state'],
      address: properties['address'],
      latitude: coordinates[1],
      longitude: coordinates[0],
    );
  }
}
