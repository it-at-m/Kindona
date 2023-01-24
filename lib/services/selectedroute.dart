import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:rxdart/rxdart.dart';

class SelectedRoute {
  static final BehaviorSubject<List<Room>> routeStream = BehaviorSubject();

  static Stream<List<Room>> get observe => routeStream.stream;
}