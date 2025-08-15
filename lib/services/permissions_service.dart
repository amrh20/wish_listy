import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionsService {
  
  // طلب صلاحية الكاميرا
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }
  
  // طلب صلاحية معرض الصور
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status == PermissionStatus.granted;
  }
  
  // طلب صلاحية الموقع
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status == PermissionStatus.granted;
  }
  
  // طلب صلاحية التقويم
  static Future<bool> requestCalendarPermission() async {
    final status = await Permission.calendar.request();
    return status == PermissionStatus.granted;
  }
  
  // طلب صلاحية الإشعارات
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }
  
  // فحص جميع الصلاحيات المطلوبة
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return await [
      Permission.camera,
      Permission.photos,
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();
  }
  
  // عرض حوار لطلب الصلاحية مع توضيح السبب
  static Future<bool> requestPermissionWithDialog(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String message,
  }) async {
    // فحص الصلاحية أولاً
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      // عرض حوار توضيحي
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Not Now'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Allow'),
            ),
          ],
        ),
      );
      
      if (shouldRequest == true) {
        final result = await permission.request();
        return result.isGranted;
      }
    }
    
    if (status.isPermanentlyDenied) {
      // إرشاد المستخدم لفتح الإعدادات
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permission Required'),
          content: Text(
            'This permission has been permanently denied. Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Open Settings'),
            ),
          ],
        ),
      );
      
      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    }
    
    return false;
  }
  
  // طلب صلاحية الكاميرا مع حوار توضيحي
  static Future<bool> requestCameraWithDialog(BuildContext context) async {
    return await requestPermissionWithDialog(
      context,
      permission: Permission.camera,
      title: 'Camera Access',
      message: 'WishLink needs camera access to let you add photos to your wishlist items and scan QR codes.',
    );
  }
  
  // طلب صلاحية الصور مع حوار توضيحي
  static Future<bool> requestPhotosWithDialog(BuildContext context) async {
    return await requestPermissionWithDialog(
      context,
      permission: Permission.photos,
      title: 'Photo Library Access',
      message: 'WishLink needs access to your photos to let you select images for your wishlist items.',
    );
  }
  
  // طلب صلاحية الموقع مع حوار توضيحي
  static Future<bool> requestLocationWithDialog(BuildContext context) async {
    return await requestPermissionWithDialog(
      context,
      permission: Permission.locationWhenInUse,
      title: 'Location Access',
      message: 'WishLink needs location access to help you find and add event locations.',
    );
  }
}