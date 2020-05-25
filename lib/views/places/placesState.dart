import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pandemia/components/places/search/placeCard.dart';
import 'package:pandemia/components/places/search/searchBar.dart';
import 'package:pandemia/components/places/type/placeType.dart';
import 'package:pandemia/data/database/models/Favorite.dart';
import 'package:pandemia/utils/CustomPalette.dart';
import 'package:pandemia/views/places/places.dart';

class PlacesState extends State<PlacesView> {
  GoogleMapController mapController;
  String _mapStyle;
  final LatLng _center = const LatLng(50.6311652, 3.0477402);
  final searchBar = new SearchBar();
  List<Polyline> searchZones = [];
  Favorite fPlace;
  String selectedType = "";

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.setMapStyle(_mapStyle);
    searchBar.mapController = controller;
    searchBar.callback = (dynamic place) {
      print(place);
      setState(() {
        fPlace =
            Favorite(address: place['formatted_address'], name: place['name'],
            id: place['place_id']);
        print(fPlace);
      });
    };
    searchBar.closeCallback = () {
      setState(() {
        fPlace = null;
      });
    };
  }

  void setPlaceType (String placeKey) {
    setState(() {
      selectedType = placeKey;
    });
    print('place type is set to $placeKey');

    // refreshing view with new place type
    getAllPlacesInViewport();
  }

  void getAllPlacesInViewport () async {
    print('getting all places in viewport');
    var bounds = await mapController.getVisibleRegion();
    // print(bounds);

    setState(() {
      searchZones.add(Polyline(
        polylineId: PolylineId(DateTime.now().toIso8601String()),
        color: Colors.blue,
        patterns: [
          PatternItem.dash(20.0),
          PatternItem.gap(10)
        ],
        width: 5,
        points: [
          bounds.northeast,
          new LatLng(bounds.southwest.latitude, bounds.northeast.longitude),
          bounds.southwest,
          new LatLng(bounds.northeast.latitude, bounds.southwest.longitude),
          bounds.northeast,
        ],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    searchBar.fatherContext = context;
    rootBundle.loadString('assets/mapstyle.txt').then((string) {
      _mapStyle = string;
    });
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        resizeToAvoidBottomPadding: false,
        body: Stack (
          fit: StackFit.passthrough,
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              onCameraIdle: () => getAllPlacesInViewport(),
              polylines: searchZones.toSet(),
              zoomControlsEnabled: false,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 13.75,
              ),
            ),

            Align(
              alignment: Alignment.topCenter,
              child: searchBar,
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: PlaceCard(place: fPlace, mainContext: context)
            ),

            DraggableScrollableSheet(
              initialChildSize: 0.09,
              minChildSize: 0.09,
              builder: (BuildContext localContext, ScrollController scrollController) {
                List<Widget> typesItems = [ListTile(
                  title: Center(
                    child: Column (
                      children: <Widget>[
                        Icon(Icons.maximize, color: CustomPalette.text[700]),
                        Container (
                          child: Text(FlutterI18n.translate(context, "places_typepicker_title"), style: TextStyle(
                              color: CustomPalette.text[300])),
                          margin: EdgeInsets.all(0),
                          padding: EdgeInsets.only(bottom: 10),
                        ),
                        Divider (color: CustomPalette.text[300], thickness: 0.5,)
                      ],
                    ),
                  ),
                )];
                for (PlaceType t in PlaceType.getSortedTypes(context)) {
                  typesItems.add(
                      ListTile(
                        onTap: () => setPlaceType(t.key),
                        dense: true,
                        enabled: true,
                        title: Text(t.translation, style: TextStyle(color: CustomPalette.text[300])),
                        leading: Radio(
                          groupValue: selectedType,
                          value: t.key,
                          onChanged: (key) => setPlaceType(key)
                        ),
                      )
                  );
                }

                return Container(
                  color: CustomPalette.background[400],
                  child: ListView(
                    controller: scrollController,
                    children: typesItems,
                  )
                );
              },
            )
          ],
        )
      ),
    );
  }
}