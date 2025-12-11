import 'package:hive/hive.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class WishlistAdapter extends TypeAdapter<Wishlist> {
  @override
  final int typeId = 6;

  @override
  Wishlist read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    
    return Wishlist(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as WishlistType,
      eventId: fields[3] as String?,
      name: fields[4] as String,
      description: fields[5] as String?,
      visibility: fields[6] as WishlistVisibility,
      items: (fields[7] as List?)?.cast<WishlistItem>() ?? [],
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Wishlist obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.eventId)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.visibility)
      ..writeByte(7)
      ..write(obj.items)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

