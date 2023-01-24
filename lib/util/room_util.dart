import 'package:flutter/material.dart';
import 'package:indoor_navigation/navigation/navigation.dart';

IconData getRoomIcon(IndoorNode room) {
  switch (room.runtimeType) {
    case Elevator:
      return Icons.elevator_outlined;
    case Stairway:
      return Icons.stairs_outlined;
    case Room:
      break;
    default:
      return Icons.meeting_room;
  }

  switch ((room as Room).type) {
    case RoomType.toilet:
    case RoomType.toiletFemale:
    case RoomType.toiletMale:
      return Icons.wc_outlined;
    default:
      return Icons.meeting_room;
  }
}