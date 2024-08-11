// import 'dart:async';
// import 'dart:ui' as ui;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../utils/utils.dart';
// import 'clicked.dart';
//
// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});
//
//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   Utils utils = Utils();
//   final Completer<GoogleMapController> _controller = Completer();
//   static const LatLng _center = LatLng(9.574610, 77.679771);
//   List<Marker> _markers = [];
//   BitmapDescriptor? _customMarkerIcon;
//   final MapType _currentMapType = MapType.satellite;
//   String? _selectedMarkerName;
//   final TextEditingController _searchController = TextEditingController();
//   bool _isSearching = false;
//   final List<Map<String, dynamic>> _locations = [];
//   List<Map<String, dynamic>> _filteredLocations = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCustomMarkerIcon().then((_) {
//       _loadMarkers();
//     });
//     _searchController.addListener(_filterLocations);
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadCustomMarkerIcon() async {
//     final ByteData data = await rootBundle.load('assets/images/marker.png');
//     final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 80);
//     final ui.FrameInfo fi = await codec.getNextFrame();
//     final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List resizedMarker = byteData!.buffer.asUint8List();
//
//     setState(() {
//       _customMarkerIcon = BitmapDescriptor.fromBytes(resizedMarker);
//     });
//     if (kDebugMode) {
//       print("Custom marker loaded successfully");
//     }
//   }
//
//   Future<void> _loadMarkers() async {
//     try {
//       CollectionReference markersCollection = FirebaseFirestore.instance.collection('navigation');
//       QuerySnapshot querySnapshot = await markersCollection.get();
//
//       List<Marker> markers = querySnapshot.docs.map((doc) {
//         GeoPoint geoPoint = doc['geopoint'];
//         List<dynamic> alternativeNames = doc['alternative names'];
//         String name = doc.id;
//
//         final location = {
//           'name': name,
//           'lat': geoPoint.latitude,
//           'lng': geoPoint.longitude,
//           'alternativeNames': alternativeNames,
//         };
//         _locations.add(location);
//         return Marker(
//           markerId: MarkerId(name),
//           position: LatLng(geoPoint.latitude, geoPoint.longitude),
//           infoWindow: InfoWindow(title: name),
//           icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
//           onTap: () {
//             setState(() {
//               _selectedMarkerName = name;
//             });
//             print("Marker selected: $name");
//           },
//         );
//       }).toList();
//
//       setState(() {
//         _markers = markers;
//         _filteredLocations = _locations;
//       });
//       print("Markers loaded successfully: $markers");
//     } catch (e) {
//       if (kDebugMode) {
//         print("Error loading markers: $e");
//       }
//     }
//   }
//
//   void _onMapCreated(GoogleMapController controller) {
//     _controller.complete(controller);
//   }
//
//   void onInternalViewButtonClicked() {
//     if (_selectedMarkerName != null) {
//       if (kDebugMode) {
//         print("Selected marker: $_selectedMarkerName");
//       }
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => OnClickedBuildings(block: _selectedMarkerName!),
//         ),
//       );
//     } else {
//       if (kDebugMode) {
//         print("No marker selected");
//       }
//       utils.showToastMessage('Select any KLU buildings');
//     }
//   }
//
//   Future<void> showMarkerInfoWindow(String markerId) async {
//     final GoogleMapController controller = await _controller.future;
//     controller.showMarkerInfoWindow(MarkerId(markerId));
//   }
//
//   void _filterLocations() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       if (query.isNotEmpty) {
//         _filteredLocations = _locations.map((location) {
//           final name = location['name'].toLowerCase();
//           final alternativeNames = (location['alternativeNames'] as List<dynamic>)
//               .map((e) => e.toLowerCase())
//               .where((altName) => altName.contains(query))
//               .toList();
//
//           if (name.contains(query) || alternativeNames.isNotEmpty) {
//             return {
//               'name': location['name'],
//               'lat': location['lat'],
//               'lng': location['lng'],
//               'alternativeNames': alternativeNames,
//             };
//           }
//           return null;
//         }).where((location) => location != null).cast<Map<String, dynamic>>().toList();
//       } else {
//         _filteredLocations = _locations;
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (kDebugMode) {
//       print('Build is running');
//     }
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(
//           title: _isSearching
//               ? TextField(
//             controller: _searchController,
//             autofocus: true,
//             decoration: const InputDecoration(
//               hintText: 'Search locations...',
//               border: InputBorder.none,
//               hintStyle: TextStyle(color: Colors.white70),
//             ),
//             style: const TextStyle(color: Colors.white, fontSize: 16.0),
//           )
//               : const Text('University Navigation'),
//           backgroundColor: Colors.green[700],
//           actions: [
//             IconButton(
//               icon: Icon(_isSearching ? Icons.close : Icons.search),
//               onPressed: () {
//                 setState(() {
//                   _isSearching = !_isSearching;
//                   if (!_isSearching) {
//                     _searchController.clear();
//                   }
//                 });
//               },
//             ),
//           ],
//         ),
//         body: Stack(
//           children: <Widget>[
//             GoogleMap(
//               onMapCreated: _onMapCreated,
//               mapType: _currentMapType,
//               initialCameraPosition: const CameraPosition(
//                 target: _center,
//                 zoom: 16.0,
//               ),
//               markers: Set<Marker>.of(_markers),
//             ),
//             if (_isSearching)
//               Positioned(
//                 child: Container(
//                   constraints: BoxConstraints(
//                     maxHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).viewInsets.bottom,
//                   ),
//                   color: Colors.white,
//                   child: SingleChildScrollView(
//                     child: Column(
//                       children: _filteredLocations.map((location) {
//                         final name = location['name'];
//                         final alternativeNames = (location['alternativeNames'] as List<dynamic>).join(', ');
//
//                         return ListTile(
//                           title: Text(name),
//                           subtitle: alternativeNames.isNotEmpty
//                               ? Text(
//                             alternativeNames,
//                             style: const TextStyle(fontSize: 12.0),
//                             overflow: TextOverflow.ellipsis,
//                             maxLines: 1,
//                           )
//                               : null,
//                           onTap: () async {
//                             _searchController.clear();
//                             final controller = await _controller.future;
//                             controller.animateCamera(
//                               CameraUpdate.newLatLng(
//                                 LatLng(location['lat'], location['lng']),
//                               ),
//                             );
//                             setState(() {
//                               _isSearching = false;
//                               _selectedMarkerName = location['name'];
//                               showMarkerInfoWindow(location['name']);
//                             });
//                           },
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
// }

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../provider/map_provider.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: provider.isSearchingState
                ? TextField(
              controller: provider.searchTextController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search locations...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            )
                : const Text('University Navigation'),
            backgroundColor: Colors.green[700],
            actions: [
              IconButton(
                icon: Icon(provider.isSearchingState ? Icons.close : Icons.search),
                onPressed: () => provider.toggleSearch(),
              ),
            ],
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                onMapCreated: provider.onMapCreated,
                mapType: provider.currentMapType,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(9.574610, 77.679771),
                  zoom: 16.0,
                ),
                markers: Set<Marker>.of(provider.markers),
              ),
              if (provider.isSearchingState)
                Positioned(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).viewInsets.bottom,
                    ),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                        children: provider.filteredLocations.map((location) {
                          final name = location['name'];
                          final alternativeNames = (location['alternativeNames'] as List<dynamic>).join(', ');

                          return ListTile(
                            title: Text(name),
                            subtitle: alternativeNames.isNotEmpty
                                ? Text(
                              alternativeNames,
                              style: const TextStyle(fontSize: 12.0),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            )
                                : null,
                            onTap: () async {
                              provider.searchTextController.clear();
                              final controller = await provider.controller.future;
                              controller.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(location['lat'], location['lng']),
                                ),
                              );
                              provider.toggleSearch();
                              provider.selectedMarkerName = location['name'];
                              provider.showMarkerInfoWindow(location['name']);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => provider.onInternalViewButtonClicked(context),
            child: const Icon(Icons.info),
          ),
        );
      },
    );
  }
}
