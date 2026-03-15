import 'package:hive/hive.dart';

part 'my_video.g.dart';

@HiveType(typeId: 1)
class MyVideo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String label;

  @HiveField(2)
  String refId;

  @HiveField(3)
  String date;

  @HiveField(4)
  bool hidden;

  @HiveField(5)
  String videoPath;

  MyVideo({
    required this.id,
    required this.label,
    required this.refId,
    required this.date,
    this.hidden = false,
    required this.videoPath,
  });

  MyVideo copyWith({
    String? id,
    String? label,
    String? refId,
    String? date,
    bool? hidden,
    String? videoPath,
  }) {
    return MyVideo(
      id: id ?? this.id,
      label: label ?? this.label,
      refId: refId ?? this.refId,
      date: date ?? this.date,
      hidden: hidden ?? this.hidden,
      videoPath: videoPath ?? this.videoPath,
    );
  }
}
