import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SelfieResult {
  final String? photoUrl;
  final String? localFilePath;
  final bool isOnline;

  SelfieResult({
    this.photoUrl,
    this.localFilePath,
    required this.isOnline,
  });
}

class SelfieService {
  static final SelfieService _instance = SelfieService._internal();
  factory SelfieService() => _instance;
  SelfieService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<CameraDescription?> getFrontCamera() async {
    final cameras = await availableCameras();
    try {
      return cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      return cameras.isNotEmpty ? cameras.first : null;
    }
  }

  Future<String> compressImage(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = '${dir.path}/selfie_$timestamp.jpg';

    int quality = 20;
    String? resultPath;

    do {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        minWidth: 480,
        minHeight: 360,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) throw Exception('Compression failed');
      resultPath = result.path;

      final file = File(resultPath);
      final size = await file.length();
      if (size <= 25600 || quality <= 10) break;

      quality = (quality - 5).clamp(10, 20);
    } while (true);

    return resultPath;
  }

  Future<String> uploadPhoto(String filePath, String userId) async {
    final bytes = await File(filePath).readAsBytes();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${userId}_$timestamp.jpg';
    final storagePath = 'selfies/$userId/$fileName';

    await _supabase.storage
        .from('selfie_absensi')
        .uploadBinary(storagePath, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));

    return _supabase.storage
        .from('selfie_absensi')
        .getPublicUrl(storagePath);
  }

  Future<SelfieResult> captureAndUpload({
    required CameraController controller,
    required String userId,
  }) async {
    final xFile = await controller.takePicture();
    final compressedPath = await compressImage(xFile.path);

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = !connectivity.contains(ConnectivityResult.none);

    if (isOnline) {
      final photoUrl = await uploadPhoto(compressedPath, userId);
      File(compressedPath).delete();
      return SelfieResult(
        photoUrl: photoUrl,
        localFilePath: null,
        isOnline: true,
      );
    } else {
      return SelfieResult(
        photoUrl: null,
        localFilePath: compressedPath,
        isOnline: false,
      );
    }
  }

  Future<String> uploadLocalPhoto({
    required String userId,
    required String localPath,
  }) async {
    final photoUrl = await uploadPhoto(localPath, userId);
    await File(localPath).delete();
    return photoUrl;
  }
}
