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
    
    // Handle backward compatibility: old wishlists may not have category field (index 10)
    // If fieldsCount is 10, it's an old format without category
    // If fieldsCount is 11, it has category
    String? category;
    if (fieldsCount >= 11 && fields.containsKey(10)) {
      category = fields[10] as String?;
    }
    
    return Wishlist(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as WishlistType,
      eventId: fields[3] as String?,
      name: fields[4] as String,
      description: fields[5] as String?,
      visibility: fields[6] as WishlistVisibility,
      category: category, // Category field (null for old wishlists)
      items: (fields[7] as List?)?.cast<WishlistItem>() ?? [],
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Wishlist obj) {
    writer
      ..writeByte(11) // Updated field count to 11 (was 10)
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
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.category); // Added category field
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

