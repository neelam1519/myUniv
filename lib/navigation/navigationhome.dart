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
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () => provider.onInternalViewButtonClicked(context),
          //   child: const Icon(Icons.info),
          // ),
        );
      },
    );
  }
}
