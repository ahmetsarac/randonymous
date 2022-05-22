import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingNotifier extends ChangeNotifier {
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();
  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCPeerConnection? peerConnection;
  String? roomId;
  bool permissionStatus = false;
  bool isCalling = false;

  final configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  Future<void> getMicrophoneAccess() async {
    final mediaConstraints = {'audio': true, 'video': false};
    try {
      final stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = stream;
      localStream = stream;
      remoteRenderer.srcObject = await createLocalMediaStream('key');
      debugPrint(localRenderer.srcObject.toString());
      permissionStatus = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Microphone access error: ${e.toString()}');
      permissionStatus = false;
      notifyListeners();
    }
  }

  Future<void> makeCall() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    final snapshot = await db.collection('rooms').get();
    final openRooms = snapshot.docs
        .where(
          (element) => element.data()['answer'] == null,
        )
        .map((e) => e.id)
        .toList();
    debugPrint(openRooms.toString());
    if (openRooms.isEmpty) {
      createRoom();
    } else {
      var randomItem = (openRooms..shuffle()).first;
      roomId = randomItem;
      joinRoom();
    }
    isCalling = true;
    notifyListeners();
  }

  Future<void> createRoom() async {
    // Access Firestore and create a document ref
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    // Create peer connection and add local streams to the connection
    debugPrint('Create peer connection with $configuration');
    peerConnection = await createPeerConnection(configuration);
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Create a collection for callee candidates
    var callerCandidatesCollection = roomRef.collection('callerCandidates');
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      debugPrint('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };

    peerConnection?.onIceConnectionState = (e) {
      debugPrint('onIceConnectionState message: $e');
    };

    // Create the offer
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    log('Created offer: $offer');
    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
    await roomRef.set(roomWithOffer);
    roomId = roomRef.id;
    debugPrint('New room created with SDK offer. Room ID: $roomId');

    // Remote track capturing
    peerConnection?.onTrack = (RTCTrackEvent event) {
      debugPrint('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        debugPrint('Add a track to the remoteStream $track');
        remoteStream?.addTrack(track);
      });
    };

    peerConnection!.onAddStream = (stream) {
      debugPrint('addStream: ${stream.id}');
      remoteRenderer.srcObject = stream;
    };

    // Listening for remote session descripton (answer)
    roomRef.snapshots().listen((snapshot) async {
      debugPrint('Got updated room: ${snapshot.data()}');

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null &&
          data['answer'] != null) {
        var answer = RTCSessionDescription(
            data['answer']['sdp'], data['answer']['type']);

        debugPrint('Someone tried to connect');
        await peerConnection?.setRemoteDescription(answer);
      }
    });

    // Listen for remote ICE candidates
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          debugPrint('Got new remote ICE candidate ${jsonEncode(data)}');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  Future<void> joinRoom() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();
    debugPrint('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      debugPrint('Create peer connection with $configuration in joinRoom');
      peerConnection = await createPeerConnection(configuration);

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Collecting ICE candidates
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        debugPrint('onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };

      //
      peerConnection?.onTrack = (RTCTrackEvent event) {
        debugPrint('Got remote track: ${event.streams[0]}');
        event.streams[0].getTracks().forEach((track) {
          debugPrint('Add a track to the remoteStream: $track');
          remoteStream?.addTrack(track);
          remoteRenderer.srcObject = remoteStream;
        });
      };

      peerConnection!.onAddStream = (stream) {
        debugPrint('addStream: ${stream.id}');
        remoteRenderer.srcObject = stream;
      };

      // Creating the answer SDP
      var data = roomSnapshot.data() as Map<String, dynamic>;
      debugPrint('Got offer $data');
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();
      debugPrint('Created answer: $answer');
      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);

      // Listening for remote ICE candidates below
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          debugPrint('Got new remote ICE candidate: $data');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      });
    }
  }

  Future<void> hangUp() async {
    //final tracks = localRenderer.srcObject!.getTracks();
    //for (var track in tracks) {
    //  track.stop();
    //}
    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      for (var document in calleeCandidates.docs) {
        document.reference.delete();
      }

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      for (var document in callerCandidates.docs) {
        document.reference.delete();
      }

      await roomRef.delete();
    }

    //localStream!.dispose();
    remoteStream?.dispose();
    isCalling = false;
    notifyListeners();
  }
}

final signalingProvider = ChangeNotifierProvider((ref) {
  return SignalingNotifier();
});
