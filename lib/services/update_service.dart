import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/language_provider.dart';
import 'dart:developer' as developer;
import '../config.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: Config.wooCommerceUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Map<String, dynamic>? _updateInfo;

  Future<void> initialize() async {
    try {
      final response = await _dio.get('/wp-json/ucp/v1/update-info');
      if (response.statusCode == 200) {
        _updateInfo = response.data;
        developer.log('UpdateService: Data loaded from WordPress: $_updateInfo');
      }
    } catch (e) {
      developer.log('UpdateService: Error fetching update info from WordPress: $e');
    }
  }

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      if (_updateInfo == null) {
        await initialize();
      }

      if (_updateInfo == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final requiredVersion = _updateInfo!['required_version'] ?? '1.0.0';
      final forceUpdate = _updateInfo!['is_force_update'] ?? false;

      developer.log('UpdateService: Current: $currentVersion, Required: $requiredVersion');

      if (_isVersionLower(currentVersion, requiredVersion)) {
        _showUpdateDialog(context, forceUpdate);
      }
    } catch (e) {
      developer.log('UpdateService: Error checking for update: $e');
    }
  }

  bool _isVersionLower(String current, String required) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> requiredParts = required.split('.').map(int.parse).toList();

      for (var i = 0; i < requiredParts.length; i++) {
          int curr = i < currentParts.length ? currentParts[i] : 0;
          int req = requiredParts[i];
          if (curr < req) return true;
          if (curr > req) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, bool isForceUpdate) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    bool isArabic = languageProvider.appLocale.languageCode == 'ar';
    
    final title = isArabic ? "تحديث جديد" : "New Update";
    final message = isArabic 
        ? (_updateInfo!['update_message_ar'] ?? "يوجد تحديث جديد متاح للتطبيق.")
        : (_updateInfo!['update_message_en'] ?? "A new version of the app is available.");
    final btnText = isArabic ? "تحديث الآن" : "Update Now";
    final laterText = isArabic ? "لاحقاً" : "Later";

    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => PopScope(
        canPop: !isForceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update_alt, size: 60, color: Colors.orange),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (!isForceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(laterText, style: const TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _launchStore,
              child: Text(btnText),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchStore() async {
    if (_updateInfo == null) return;

    final url = Platform.isAndroid 
        ? _updateInfo!['update_url_android']
        : _updateInfo!['update_url_ios'];
    
    if (url != null && url.isNotEmpty) {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }
}
