import 'dart:convert';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mood_fresher/firebase/firebase_options.dart';
import 'package:mood_fresher/screens/chat.dart';

class NotificationServices {
  final _notification = FirebaseMessaging.instance;
  final _localNotification = FlutterLocalNotificationsPlugin();

  Future<String?> getToken() async {
    return await _notification.getToken();
  }

  void initialize(BuildContext context) async {
    await _notification.requestPermission(
      announcement: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );
    FirebaseMessaging.onMessage.listen((message) async {
      var androidSettings =
          const AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosSettings = const DarwinInitializationSettings();
      var initializeSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotification
          .initialize(initializeSettings,
              onDidReceiveNotificationResponse: (details) =>
                  handleTap(context, message))
          .then((value) => showNotification(message));
    });
    await _notification.getInitialMessage().then((value) {
      if (value != null) {
        handleTap(context, value);
      }
    });
    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => handleTap(context, message));
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  static Future<void> sendNotification(
      {required String chatId,
      required String recipientId,
      required String recipientName,
      required String recipientImage,
      required String recipientToken,
      required String senderId,
      required String sender,
      required String? senderToken,
      required String senderImage,
      required String message}) async {
    var data = {
      'to': recipientToken,
      'priority': 'high',
      'notification': {
        'title': sender,
        'body': message,
      },
      'data': {
        'chatId': chatId,
        'recipientId': recipientId,
        'recipientName': recipientName,
        'recipientImage': recipientImage,
        'senderId': senderId,
        'sender': sender,
        'senderToken': senderToken,
        'senderImage': senderImage
      }
    };
    await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
        body: jsonEncode(data),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'key='
        });
  }

  void showNotification(RemoteMessage message) {
    var androidChannel = AndroidNotificationChannel(
        Random.secure().nextInt(100000).toString(),
        'High Importance Notifications',
        importance: Importance.max);
    var androidDetails = AndroidNotificationDetails(
        androidChannel.id, androidChannel.name,
        importance: Importance.high, priority: Priority.high);
    var iosDetails = const DarwinNotificationDetails();
    var notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    _localNotification.show(message.hashCode, message.notification?.title,
        message.notification?.body, notificationDetails);
  }

  void handleTap(BuildContext context, RemoteMessage message) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: ((context) => ChatScreen(
            chatId: message.data['chatId'],
            uid: message.data['recipientId'],
            username: message.data['recipientName'],
            userImage: message.data['recipientImage'],
            recipientId: message.data['senderId'],
            recipient: message.data['sender'],
            recipientToken: message.data['senderToken'],
            recipientImage: message.data['senderImage']))));
  }
}

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
