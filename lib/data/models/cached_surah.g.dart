// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_surah.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedSurahAdapter extends TypeAdapter<CachedSurah> {
  @override
  final int typeId = 0;

  @override
  CachedSurah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedSurah(
      number: fields[0] as int,
      name: fields[1] as String,
      englishName: fields[2] as String,
      revelationType: fields[3] as String,
      numberOfAyahs: fields[4] as int,
      ayahs: (fields[5] as List).cast<CachedAyah>(),
      cachedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedSurah obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.englishName)
      ..writeByte(3)
      ..write(obj.revelationType)
      ..writeByte(4)
      ..write(obj.numberOfAyahs)
      ..writeByte(5)
      ..write(obj.ayahs)
      ..writeByte(6)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedSurahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedAyahAdapter extends TypeAdapter<CachedAyah> {
  @override
  final int typeId = 1;

  @override
  CachedAyah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedAyah(
      number: fields[0] as int,
      text: fields[1] as String,
      numberInSurah: fields[2] as int,
      translation: fields[3] as String?,
      tafsir: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedAyah obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.numberInSurah)
      ..writeByte(3)
      ..write(obj.translation)
      ..writeByte(4)
      ..write(obj.tafsir);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedAyahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
