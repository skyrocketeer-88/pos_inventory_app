// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceiptItemAdapter extends TypeAdapter<ReceiptItem> {
  @override
  final int typeId = 3;

  @override
  ReceiptItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptItem(
      name: fields[0] as String,
      quantity: fields[1] as int,
      price: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReceiptAdapter extends TypeAdapter<Receipt> {
  @override
  final int typeId = 4;

  @override
  Receipt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Receipt(
      id: fields[0] as String,
      vendorOrCustomer: fields[1] as String,
      date: fields[2] as DateTime,
      items: (fields[3] as List).cast<ReceiptItem>(),
      taxRate: fields[4] as double,
      rawOcrText: fields[5] as String,
      notes: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Receipt obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorOrCustomer)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.taxRate)
      ..writeByte(5)
      ..write(obj.rawOcrText)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
