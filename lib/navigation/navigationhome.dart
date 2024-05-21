import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'clicked.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = LatLng(9.574610, 77.679771);
  List<Marker> _markers = [];
  BitmapDescriptor? _customMarkerIcon;
  MapType _currentMapType = MapType.satellite;
  String? _selectedMarkerName;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcon().then((_) {
      _loadMarkers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarkerIcon() async {
    final ByteData data = await rootBundle.load('assets/images/marker.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 80);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedMarker = byteData!.buffer.asUint8List();

    setState(() {
      _customMarkerIcon = BitmapDescriptor.fromBytes(resizedMarker);
    });
    print("Custom marker loaded successfully");
  }

  Future<void> _loadMarkers() async {
    try {
      final String data = await rootBundle.loadString('assets/locations.json');
      final List<dynamic> jsonResult = json.decode(data);
      _locations = jsonResult.cast<Map<String, dynamic>>();

      List<Marker> markers = _locations.map((location) {
        return Marker(
          markerId: MarkerId(location['name']),
          position: LatLng(location['lat'], location['lng']),
          infoWindow: InfoWindow(title: location['name']),
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
          onTap: () {
            setState(() {
              _selectedMarkerName = location['name'];
            });
            print("Marker selected: ${location['name']}");
          },
        );
      }).toList();

      setState(() {
        _markers = markers;
        _filteredLocations = _locations;
      });

      print("Markers loaded successfully");
    } catch (e) {
      print("Error loading markers: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.satellite ? MapType.normal : MapType.satellite;
    });
  }

  void onInternalViewButtonClicked() {
    if (_selectedMarkerName != null) {
      print("Selected marker: $_selectedMarkerName");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnClickedBuildings(block: _selectedMarkerName!),
        ),
      );
    } else {
      print("No marker selected");
    }
  }

  void _startSearch() {
    ModalRoute.of(context)!.addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearching));
    setState(() {
      _isSearching = true;
      _filteredLocations = _locations;
    });
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredLocations = _locations;
    });
  }

  void _searchOperation(String searchText) {
    if (_isSearching) {
      setState(() {
        _filteredLocations = _locations.where((location) {
          final nameMatches = location['name'].toString().toLowerCase().contains(searchText.toLowerCase());
          final alternativeNames = location['alternativeNames'];
          bool alternativeNameMatches = false;
          String? matchedAlternativeName;

          if (alternativeNames is List) {
            for (var altName in alternativeNames) {
              if (altName.toString().toLowerCase().contains(searchText.toLowerCase())) {
                alternativeNameMatches = true;
                matchedAlternativeName = altName;
                break;
              }
            }
          }

          if (nameMatches || alternativeNameMatches) {
            location['matchedAlternativeName'] = matchedAlternativeName;
            return true;
          } else {
            return false;
          }
        }).toList();
      });
    }
  }

  Future<void> showMarkerInfoWindow(String markerId) async {
    final GoogleMapController controller = await _controller.future;
    controller.showMarkerInfoWindow(MarkerId(markerId));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: _isSearching ? _buildSearchField() : Text('University Navigation'),
          backgroundColor: Colors.green[700],
          actions: _buildActions(),
        ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              mapType: _currentMapType,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 16.0,
              ),
              markers: Set<Marker>.of(_markers),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 16.0),
                    FloatingActionButton(
                      onPressed: onInternalViewButtonClicked,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.remove_red_eye, size: 35.0),
                    ),
                  ],
                ),
              ),
            ),
            _isSearching ? _buildSearchResults() : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search for locations...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white30),
      ),
      style: TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: _searchOperation,
    );
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return <Widget>[
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              Navigator.pop(context);
              return;
            }
            _searchController.clear();
            _searchOperation('');
          },
        ),
      ];
    }

    return <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: _startSearch,
      ),
    ];
  }

  Widget _buildSearchResults() {
    Navigator.pop(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: _filteredLocations.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_filteredLocations[index]['name']),
              onTap: () async {
                final location = _filteredLocations[index];
                final matchedAlternativeName = location['matchedAlternativeName'];
                final infoWindowTitle = matchedAlternativeName != null
                    ? '${location['name']} ($matchedAlternativeName)'
                    : location['name'];

                final GoogleMapController controller = await _controller.future;
                controller.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(location['lat'], location['lng']),
                  18.0,
                ));

                setState(() {
                  _markers = _markers.map((marker) {
                    if (marker.markerId.value == location['name']) {
                      return marker.copyWith(
                        infoWindowParam: InfoWindow(title: infoWindowTitle),
                      );
                    }
                    return marker;
                  }).toList();
                });

                await showMarkerInfoWindow(location['name']);

                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _selectedMarkerName = location['name'];
                });
              },
            );
          },
        ),
      ),
    );
  }
}
