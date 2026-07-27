// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfTemplateConfigAdapter extends TypeAdapter<PdfTemplateConfig> {
  @override
  final int typeId = 5;

  @override
  PdfTemplateConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfTemplateConfig(
      businessName: fields[0] as String,
      address: fields[1] as String,
      phone: fields[2] as String,
      footerText: fields[3] as String,
      primaryColorValue: fields[4] as int,
      showTaxLine: fields[5] as bool,
      showLogoPlaceholder: fields[6] as bool,
      documentTitle: fields[7] as String,
      currencySymbol: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PdfTemplateConfig obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.businessName)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.footerText)
      ..writeByte(4)
      ..write(obj.primaryColorValue)
      ..writeByte(5)
      ..write(obj.showTaxLine)
      ..writeByte(6)
      ..write(obj.showLogoPlaceholder)
      ..writeByte(7)
      ..write(obj.documentTitle)
      ..writeByte(8)
      ..write(obj.currencySymbol);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfTemplateConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
