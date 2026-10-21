import 'package:sekolahbinekas/data/log_database.dart';
import 'package:sekolahbinekas/data/tingkat_classes_database.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import 'dart:io';
import 'package:sekolahbinekas/models/log.dart';
import 'package:sekolahbinekas/data/image_database.dart';
import 'package:sekolahbinekas/models/tingkat_classes.dart';

class LogLogic {

  Future<Log> sendLog({
    required String text,
    required List<File>? images,
    required List<File>? files,
    required String? className,
  }) async {
    // Upload images to Zipline first
    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      imageUrls = await ImageDatabase().uploadImages(images);
    }

    // Upload files to Zipline
    List<String> fileUrls = [];
    if (files != null && files.isNotEmpty) {
      fileUrls = await ImageDatabase().uploadFiles(files);
    }

    Log log = await LogDatabase().addLog(
      text,
      imageUrls.isNotEmpty ? imageUrls : null,
      fileUrls.isNotEmpty ? fileUrls : null,
      className ?? '',
    );

    if (log.id.isEmpty) {
      throw Exception('Failed to send log');
    }
    return log;
    
  }

  Future<List<Log>> sendMultiClassLog({
    required String text,
    required List<File>? images,
    required List<File>? files,
    required List<TingkatClasses> tingkatClasses,
  }) async {
    List<String> classNames = tingkatClasses.map((e) => e.class_name).toList();
    List<Log> logs = [];
    for(String className in classNames){
      Log log = await sendLog(
        text: text,
        images: images,
        files: files,
        className: className,
      );
      logs.add(log);
    }
    return logs;
  }

  Future<List<TingkatClasses>> getTingkatClasses() async {
    String role = await UserDatabase().getUserRole();

    if(role == 'bidang_study_sd'){
      return await TingkatClassesDatabase().getByTingkat('SD');
    }
    else if(role == 'bidang_study_tk'){
      return await TingkatClassesDatabase().getByTingkat('TK');
    }
    else{
      return await TingkatClassesDatabase().getAllTingkatClasses();
    }
  }
}
