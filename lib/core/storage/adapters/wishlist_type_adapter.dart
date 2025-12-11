import 'package:hive/hive.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class WishlistTypeAdapter extends TypeAdapter<WishlistType> {
  @override
  final int typeId = 0;

  @override
  WishlistType read(BinaryReader reader) {
    final index = reader.readByte();
    return WishlistType.values[index];
  }

  @override
  void write(BinaryWriter writer, WishlistType obj) {
    writer.writeByte(obj.index);
  }
}

class WishlistVisibilityAdapter extends TypeAdapter<WishlistVisibility> {
  @override
  final int typeId = 1;

  @override
  WishlistVisibility read(BinaryReader reader) {
    final index = reader.readByte();
    return WishlistVisibility.values[index];
  }

  @override
  void write(BinaryWriter writer, WishlistVisibility obj) {
    writer.writeByte(obj.index);
  }
}

class ItemPriorityAdapter extends TypeAdapter<ItemPriority> {
  @override
  final int typeId = 2;

  @override
  ItemPriority read(BinaryReader reader) {
    final index = reader.readByte();
    return ItemPriority.values[index];
  }

  @override
  void write(BinaryWriter writer, ItemPriority obj) {
    writer.writeByte(obj.index);
  }
}

class ItemStatusAdapter extends TypeAdapter<ItemStatus> {
  @override
  final int typeId = 3;

  @override
  ItemStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return ItemStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, ItemStatus obj) {
    writer.writeByte(obj.index);
  }
}

