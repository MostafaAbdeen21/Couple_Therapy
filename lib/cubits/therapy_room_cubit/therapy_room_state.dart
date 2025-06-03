import '../../models/therapy_room_model.dart';

abstract class TherapyRoomState {}

class TherapyRoomInitial extends TherapyRoomState {}
class TherapyRoomLoading extends TherapyRoomState {}
class TherapyRoomLoaded extends TherapyRoomState {
  final List<TherapyMessage> messages;
  final bool isPartnerOnline;
  final bool sessionAvailable;

  TherapyRoomLoaded({
    required this.messages,
    required this.isPartnerOnline,
    required this.sessionAvailable,
  });
}

class TherapyRoomError extends TherapyRoomState {
  final String error;
  TherapyRoomError(this.error);
}