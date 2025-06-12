import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/therapy_room_model.dart';
import 'therapy_room_state.dart';

class TherapyRoomCubit extends Cubit<TherapyRoomState> {
  final String? pairingId;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  List<TherapyMessage> messages = [];
  String? partnerId;
  bool isPartnerOnline = false;
  bool sessionAvailable = true;
  bool isTyping = false;
  int tokensUsed = 0;
  int tokenLimit = 2000;

  StreamSubscription? _presenceSubscription;
  StreamSubscription? _messagesSubscription;

  TherapyRoomCubit({required this.pairingId}) : super(TherapyRoomInitial()) {
    _init();
  }

  Future<void> _init() async {
    emit(TherapyRoomLoading());
    try {
      final pairDoc = await FirebaseFirestore.instance.collection('pairs').doc(pairingId).get();
      final data = pairDoc.data()!;
      final userA = data['userA'];
      final userB = data['userB'];
      partnerId = userId == userA ? userB : userA;
      tokenLimit = data['tokenLimit'] ?? 2000;
      tokensUsed = data['tokenUsedThisWeek'] ?? 0;

      final lastSession = data['lastSessionTimestamp']?.toDate();
      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final sessionStartedThisWeek = lastSession != null && lastSession.isAfter(startOfWeek);
      sessionAvailable = sessionStartedThisWeek ? (tokensUsed < tokenLimit) : true;

      _presenceSubscription = FirebaseFirestore.instance
          .collection('pairs')
          .doc(pairingId)
          .collection('presence')
          .doc(partnerId)
          .snapshots()
          .listen((snapshot) {
        isPartnerOnline = snapshot.data()?['online'] == true;
        _emitCurrentState();
      });

      _messagesSubscription = FirebaseFirestore.instance
          .collection('pairs')
          .doc(pairingId)
          .collection('therapyRoom')
          .orderBy('timestamp')
          .snapshots()
          .listen((snapshot) {
        messages = snapshot.docs.map((doc) => TherapyMessage.fromMap(doc.data())).toList();
        _emitCurrentState();
      });
    } catch (e) {
      emit(TherapyRoomError(e.toString()));
    }
  }

  void _emitCurrentState() {
    if (isClosed) return;
    emit(TherapyRoomLoaded(
      messages: messages,
      isPartnerOnline: isPartnerOnline,
      sessionAvailable: sessionAvailable,
      isTyping: isTyping,
    ));
  }

  Future<void> sendMessage(String messageText) async {
    if (!sessionAvailable || !isPartnerOnline || messageText.trim().isEmpty) return;
    final chatRef = FirebaseFirestore.instance
        .collection('pairs')
        .doc(pairingId)
        .collection('therapyRoom');

    await chatRef.add({
      'userId': userId,
      'message': messageText,
      'type': 'user',
      'timestamp': FieldValue.serverTimestamp(),
    });

    isTyping = true;
    _emitCurrentState();

    final snapshot = await chatRef.orderBy('timestamp').get();
    final history = snapshot.docs.map((doc) {
      final d = doc.data();
      return {
        'role': d['userId'] == 'gpt' ? 'assistant' : 'user',
        'content': d['message'],
      };
    }).toList();

    if (tokensUsed >= tokenLimit) return;

    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('gptTherapyReply-gptTherapyReply');
    final result = await callable.call(<String, dynamic>{
      'pairingId': pairingId,
      'history': history,
    });

    final gptReply = result.data['reply'] as String? ?? 'لا يوجد رد.';
    final tokensConsumedRaw = result.data['tokenUsed'];
    final tokensConsumed = tokensConsumedRaw is int ? tokensConsumedRaw : 0;


    await chatRef.add({
      'userId': 'gpt',
      'message': gptReply,
      'type': 'gpt',
      'timestamp': FieldValue.serverTimestamp(),
    });

    tokensUsed += tokensConsumed;
    await FirebaseFirestore.instance.collection('pairs').doc(pairingId).update({
      'tokenUsedThisWeek': tokensUsed,
    });

    if (tokensUsed >= tokenLimit) {
      sessionAvailable = false;
    }


    isTyping=false;
    _emitCurrentState();
  }


  Future<void> markPresence(bool online) async {
    await FirebaseFirestore.instance
        .collection('pairs')
        .doc(pairingId)
        .collection('presence')
        .doc(userId)
        .set({'online': online});
  }

  @override
  Future<void> close() async {
    await _presenceSubscription?.cancel();
    await _messagesSubscription?.cancel();
    return super.close();
  }
}
