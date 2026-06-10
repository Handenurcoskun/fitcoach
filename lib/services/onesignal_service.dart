import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OneSignalService {
  static const _appId = '7ab59b71-dd05-48fc-b8e0-cd29c0516a76';
  // OneSignal dashboard → Settings → Keys & IDs → REST API Key
  static const _restApiKey = 'os_v2_app_pk2zw4o5avepzohazuu4aulkozazebpyydoumb44fiuri6zcxk7y4tnc6gfi76ucwybbj5khtf3apkyfum6i55t3zhb5ocr2wswrmcq';

  static Future<void> initialize() async {
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);

    // Subscription ID hazır olunca dinle
    OneSignal.User.pushSubscription.addObserver((state) {
      final id = state.current.id;
      if (id != null && id.isNotEmpty) {
        // Auth'tan userId alınamadığı için login sonrası manuel çağrılacak
      }
    });
  }

  // Login/register sonrası çağrıl — subscription ID'yi Firestore'a kaydet
  static Future<void> saveSubscriptionId(String userId) async {
    final id = OneSignal.User.pushSubscription.id;
    if (id == null || id.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'onesignalId': id});
    } catch (_) {}
  }

  // Üye tüm görevleri tamamlayınca antrenöre bildirim
  static Future<void> notifyTrainerAllTasksDone({
    required String trainerOneSignalId,
    required String memberName,
  }) async {
    await _send(
      targetId: trainerOneSignalId,
      title: '🎉 Harika haber!',
      body: '$memberName bugünkü tüm görevleri tamamladı!',
    );
  }

  // Üyeye tebrik bildirimi
  static Future<void> notifyMemberAllDone({
    required String memberOneSignalId,
  }) async {
    await _send(
      targetId: memberOneSignalId,
      title: '🔥 Muhteşemsin!',
      body: 'Bugünkü tüm görevleri tamamladın. Devam et!',
    );
  }

  static Future<void> _send({
    required String targetId,
    required String title,
    required String body,
  }) async {
    if (_restApiKey == 'REPLACE_WITH_REST_API_KEY') return;
    try {
      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_subscription_ids': [targetId],
          'headings': {'en': title, 'tr': title},
          'contents': {'en': body, 'tr': body},
        }),
      );
    } catch (_) {}
  }
}
