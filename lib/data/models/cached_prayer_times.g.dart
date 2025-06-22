// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_prayer_times.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedPrayerTimesAdapter extends TypeAdapter<CachedPrayerTimes> {
  @override
  final int typeId = 2;

  @override
  CachedPrayerTimes read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedPrayerTimes(
      fajr: fields[0] as String,
      dhuhr: fields[1] as String,
      asr: fields[2] as String,
      maghrib: fields[3] as String,
      isha: fields[4] as String,
      date: fields[5] as DateTime,
      latitude: fields[6] as double,
      longitude: fields[7] as double,
      cachedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedPrayerTimes obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.fajr)
      ..writeByte(1)
      ..write(obj.dhuhr)
      ..writeByte(2)
      ..write(obj.asr)
      ..writeByte(3)
      ..write(obj.maghrib)
      ..writeByte(4)
      ..write(obj.isha)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedPrayerTimesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
