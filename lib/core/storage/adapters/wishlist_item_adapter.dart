import 'package:hive/hive.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/friends/data/models/user_model.dart' as friends;

class WishlistItemAdapter extends TypeAdapter<WishlistItem> {
  @override
  final int typeId = 5;

  @override
  WishlistItem read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    
    return WishlistItem(
      id: fields[0] as String,
      wishlistId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String?,
      link: fields[4] as String?,
      priceRange: fields[5] as PriceRange?,
      imageUrl: fields[6] as String?,
      priority: fields[7] as ItemPriority? ?? ItemPriority.medium,
      status: fields[8] as ItemStatus? ?? ItemStatus.desired,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      isReceived: fields[11] as bool? ?? false,
      reservedBy: fields[12] as friends.User?,
    );
  }

  @override
  void write(BinaryWriter writer, WishlistItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.wishlistId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.link)
      ..writeByte(5)
      ..write(obj.priceRange)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.isReceived)
      ..writeByte(12)
      ..write(obj.reservedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

