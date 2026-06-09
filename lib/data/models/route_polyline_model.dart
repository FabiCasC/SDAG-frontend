class RoutePolyline {
  final List<PolylinePoint> points;

  RoutePolyline({required this.points});

  factory RoutePolyline.fromJson(Map<String, dynamic> json) {
    var list = json['points'] as List;
    List<PolylinePoint> pointsList = list.map((i) => PolylinePoint.fromJson(i)).toList();
    return RoutePolyline(points: pointsList);
  }
}

class PolylinePoint {
  final double lat;
  final double lng;

  PolylinePoint({required this.lat, required this.lng});

  factory PolylinePoint.fromJson(Map<String, dynamic> json) {
    return PolylinePoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}