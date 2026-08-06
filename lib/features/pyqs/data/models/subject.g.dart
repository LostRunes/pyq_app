// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 2;

  @override
  Subject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subject(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      pyqDriveLink: fields[3] as String?,
      notesDriveLink: fields[4] as String?,
      courseOutcomeLink: fields[5] as String?,
      priority: fields[6] as int?,
      subjectCredit: fields[7] as int?,
      subjectType: fields[8] as String?,
      ytLinks: (fields[9] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.pyqDriveLink)
      ..writeByte(4)
      ..write(obj.notesDriveLink)
      ..writeByte(5)
      ..write(obj.courseOutcomeLink)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.subjectCredit)
      ..writeByte(8)
      ..write(obj.subjectType)
      ..writeByte(9)
      ..write(obj.ytLinks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
