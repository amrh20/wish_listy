import 'package:hive/hive.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class PriceRangeAdapter extends TypeAdapter<PriceRange> {
  @override
  final int typeId = 4;

  @override
  PriceRange read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    
    return PriceRange(
      minPrice: fields[0] as double?,
      maxPrice: fields[1] as double?,
      currency: fields[2] as String? ?? 'USD',
    );
  }

  @override
  void write(BinaryWriter writer, PriceRange obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.minPrice)
      ..writeByte(1)
      ..write(obj.maxPrice)
      ..writeByte(2)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

