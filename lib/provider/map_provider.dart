import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../navigation/clicked.dart';
import '../utils/utils.dart';

class MapProvider with ChangeNotifier {
  final Completer<GoogleMapController> controller = Completer();
  Utils utils = Utils();
  BitmapDescriptor? _customMarkerIcon;
  List<Marker> _markers = [];
  final List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _filteredLocations = [];
  String?selectedMarkerName;
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  final MapType _currentMapType = MapType.satellite;

  MapProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCustomMarkerIcon();
    await _loadMarkers();
    searchController.addListener(_filterLocations);
  }

  Future<void> _loadCustomMarkerIcon() async {
    final ByteData data = await rootBundle.load('assets/images/marker.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 80);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedMarker = byteData!.buffer.asUint8List();

    _customMarkerIcon = BitmapDescriptor.fromBytes(resizedMarker);
    notifyListeners();
  }

  Future<void> _loadMarkers() async {
    try {
      CollectionReference markersCollection = FirebaseFirestore.instance.collection('navigation');
      QuerySnapshot querySnapshot = await markersCollection.get();

      List<Marker> markers = querySnapshot.docs.map((doc) {
        GeoPoint geoPoint = doc['geopoint'];
        List<dynamic> alternativeNames = doc['alternative names'];
        String name = doc.id;

        final location = {
          'name': name,
          'lat': geoPoint.latitude,
          'lng': geoPoint.longitude,
          'alternativeNames': alternativeNames,
        };
        _locations.add(location);
        return Marker(
          markerId: MarkerId(name),
          position: LatLng(geoPoint.latitude, geoPoint.longitude),
          infoWindow: InfoWindow(title: name),
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
          onTap: () {selectedMarkerName = name;
            notifyListeners();
          },
        );
      }).toList();

      _markers = markers;
      _filteredLocations = _locations;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error loading markers: $e");
      }
    }
  }

  void _filterLocations() {
    final query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      _filteredLocations = _locations.where((location) {
        final name = location['name'].toLowerCase();
        final alternativeNames = (location['alternativeNames'] as List<dynamic>)
            .map((e) => e.toLowerCase())
            .where((altName) => altName.contains(query))
            .toList();

        return name.contains(query) || alternativeNames.isNotEmpty;
      }).toList();
    } else {
      _filteredLocations = _locations;
    }
    notifyListeners();
  }

  Future<void> onMapCreated(GoogleMapController myController) async {
    controller.complete(myController);
  }

  Future<void> showMarkerInfoWindow(String markerId) async {
    final GoogleMapController myController = await controller.future;
    myController.showMarkerInfoWindow(MarkerId(markerId));
  }

  void toggleSearch() {
    isSearching = !isSearching;
    if (!isSearching) {
      searchController.clear();
    }
    notifyListeners();
  }

  Future<void> onInternalViewButtonClicked(BuildContext context) async {
    if (selectedMarkerName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnClickedBuildings(block: selectedMarkerName!),
        ),
      );
    }
    else {
      utils.showToastMessage('Select any KLU buildings');
    }
  }

  List<Marker> get markers => _markers;
  List<Map<String, dynamic>> get filteredLocations => _filteredLocations;
  bool get isSearchingState => isSearching;
  TextEditingController get searchTextController => searchController;
  MapType get currentMapType => _currentMapType;
}
