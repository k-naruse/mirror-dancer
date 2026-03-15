// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_video.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MyVideoAdapter extends TypeAdapter<MyVideo> {
  @override
  final int typeId = 1;

  @override
  MyVideo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MyVideo(
      id: fields[0] as String,
      label: fields[1] as String,
      refId: fields[2] as String,
      date: fields[3] as String,
      hidden: fields[4] as bool,
      videoPath: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MyVideo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.refId)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.hidden)
      ..writeByte(5)
      ..write(obj.videoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyVideoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
