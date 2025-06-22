// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_audio.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedAudioFileAdapter extends TypeAdapter<CachedAudioFile> {
  @override
  final int typeId = 3;

  @override
  CachedAudioFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedAudioFile(
      surahNumber: fields[0] as int,
      ayahNumber: fields[1] as int,
      localPath: fields[2] as String,
      originalUrl: fields[3] as String,
      fileSize: fields[4] as int,
      downloadedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedAudioFile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.surahNumber)
      ..writeByte(1)
      ..write(obj.ayahNumber)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.originalUrl)
      ..writeByte(4)
      ..write(obj.fileSize)
      ..writeByte(5)
      ..write(obj.downloadedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedAudioFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
