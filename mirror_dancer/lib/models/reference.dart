import 'package:hive/hive.dart';

part 'reference.g.dart';

@HiveType(typeId: 0)
class Reference extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String memo;

  @HiveField(3)
  bool mirror;

  @HiveField(4)
  bool hidden;

  @HiveField(5)
  String videoPath;

  @HiveField(6)
  String createdAt;

  Reference({
    required this.id,
    required this.title,
    this.memo = '',
    this.mirror = false,
    this.hidden = false,
    required this.videoPath,
    required this.createdAt,
  });

  Reference copyWith({
    String? id,
    String? title,
    String? memo,
    bool? mirror,
    bool? hidden,
    String? videoPath,
    String? createdAt,
  }) {
    return Reference(
      id: id ?? this.id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      mirror: mirror ?? this.mirror,
      hidden: hidden ?? this.hidden,
      videoPath: videoPath ?? this.videoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
