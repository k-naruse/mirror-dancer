// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReferenceAdapter extends TypeAdapter<Reference> {
  @override
  final int typeId = 0;

  @override
  Reference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reference(
      id: fields[0] as String,
      title: fields[1] as String,
      memo: fields[2] as String,
      mirror: fields[3] as bool,
      hidden: fields[4] as bool,
      videoPath: fields[5] as String,
      createdAt: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Reference obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.memo)
      ..writeByte(3)
      ..write(obj.mirror)
      ..writeByte(4)
      ..write(obj.hidden)
      ..writeByte(5)
      ..write(obj.videoPath)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
