import 'package:indoor_navigation/navigation/navigation.dart';
import 'package:rxdart/rxdart.dart';

class SelectedRoute {
  static final BehaviorSubject<List<IndoorNode>> routeStream = BehaviorSubject();

  static Stream<List<IndoorNode>> get observe => routeStream.stream;
}