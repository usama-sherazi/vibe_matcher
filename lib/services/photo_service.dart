import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoService {
  static const extraKey = 'photo';

  Future<Directory> _avatarDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'avatars'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> fileFor(String profileId) async {
    final dir = await _avatarDir();
    return File(p.join(dir.path, '$profileId.jpg'));
  }

  Future<void> saveLocal(String profileId, Uint8List bytes) async {
    final file = await fileFor(profileId);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List?> readLocal(String profileId) async {
    final file = await fileFor(profileId);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<void> deleteLocal(String profileId) async {
    final file = await fileFor(profileId);
    if (await file.exists()) await file.delete();
  }

  Uint8List compressToAvatar(Uint8List input, {int size = 512, int quality = 72}) {
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;
    final square = img.copyResizeCropSquare(decoded, size: size);
    return Uint8List.fromList(img.encodeJpg(square, quality: quality));
  }

  String toBase64(Uint8List bytes) => base64Encode(bytes);

  Map<String, dynamic> extrasWithPhoto(Map<String, dynamic> extras, Uint8List bytes) {
    return {...extras, extraKey: toBase64(bytes)};
  }

  Future<Uint8List?> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
    if (picked == null) return null;
    return picked.readAsBytes();
  }
}
