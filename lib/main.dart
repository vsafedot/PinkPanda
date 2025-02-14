import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Railway Tracking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const MapScreen(),
    const StationsScreen(),
    const AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.train),
            label: 'Stations',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = MapController();
  bool isTrainMoving = true;
  int currentStationIndex = 0;
  Timer? _timer;
  Station? selectedStation;
  Position? userLocation;

  final List<Station> stations = [
    Station(
      id: 'BDHL',
      name: 'Badhal',
      code: 'BDHL',
      zone: 'NWR',
      state: 'Rajasthan',
      address: 'Kishangarh Renwal, Rajasthan',
      position: LatLng(27.2520587, 75.4516454),
      status: StationStatus.normal,
    ),
    Station(
      id: 'JP',
      name: 'Jaipur Junction',
      code: 'JP',
      zone: 'NWR',
      state: 'Rajasthan',
      address: 'Jaipur, Rajasthan',
      position: LatLng(26.9196, 75.7880),
      status: StationStatus.warning,
    ),
    Station(
      id: 'AII',
      name: 'Ajmer Junction',
      code: 'AII',
      zone: 'NWR',
      state: 'Rajasthan',
      address: 'Ajmer, Rajasthan',
      position: LatLng(26.4499, 74.6399),
      status: StationStatus.normal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTrainMovement();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = position;
    });
  }

  void _startTrainMovement() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isTrainMoving) return;
      setState(() {
        currentStationIndex = (currentStationIndex + 1) % stations.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: stations[0].position,
              initialZoom: 10,
              onTap: (_, __) {
                setState(() {
                  selectedStation = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: stations.map((s) => s.position).toList(),
                    color: Colors.blue,
                    strokeWidth: 3,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ...stations.map((station) => Marker(
                    point: station.position,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showStationDetails(station),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStatusColor(station.status).withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.train,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  )),
                  // Train marker
                  Marker(
                    point: stations[currentStationIndex].position,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_train,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  if (userLocation != null)
                    Marker(
                      point: LatLng(
                        userLocation!.latitude,
                        userLocation!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'play_pause',
                  onPressed: () {
                    setState(() {
                      isTrainMoving = !isTrainMoving;
                      if (isTrainMoving) _startTrainMovement();
                    });
                  },
                  child: Icon(isTrainMoving ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          if (selectedStation != null)
            _buildStationDetailsSheet(),
        ],
      ),
    );
  }

  Color _getStatusColor(StationStatus status) {
    switch (status) {
      case StationStatus.normal:
        return Colors.green;
      case StationStatus.warning:
        return Colors.orange;
      case StationStatus.danger:
        return Colors.red;
    }
  }

  void _showStationDetails(Station station) {
    setState(() {
      selectedStation = station;
    });
  }

  Widget _buildStationDetailsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedStation!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        selectedStation = null;
                      });
                    },
                  ),
                ],
              ),
              const Divider(),
              _detailRow('Code', selectedStation!.code),
              _detailRow('Zone', selectedStation!.zone),
              _detailRow('State', selectedStation!.state),
              _detailRow('Address', selectedStation!.address),
              _detailRow(
                'Status',
                selectedStation!.status.toString().split('.').last.toUpperCase(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StationsScreen extends StatelessWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Station ${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NORMAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text('Next Train: 10:30 AM'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.apps, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text('Platform 2'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

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
        itemCount: 2,
        itemBuilder: (context, index) {
          final isWarning = index == 0;
          return Card(
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
          );
        },
      ),
    );
  }
}

enum StationStatus {
  normal,
  warning,
  danger,
}

class Station {
  final String id;
  final String name;
  final String code;
  final String zone;
  final String state;
  final String address;
  final LatLng position;
  final StationStatus status;

  const Station({
    required this.id,
    required this.name,
    required this.code,
    required this.zone,
    required this.state,
    required this.address,
    required this.position,
    required this.status,
  });
}