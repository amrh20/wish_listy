import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Backend returns interests as raw English enum strings.
/// This extension localizes them using the app's ARB/JSON translations.
extension InterestTranslation on String {
  /// Returns the localized label for this interest string.
  /// If no match is found, returns the original string.
  String translateInterest(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final key = _interestKeyFor(this);
    if (key == null) return this;
    final translated = localization.translate('interests.$key');
    return translated == 'interests.$key' ? this : translated;
  }

  /// Maps backend enum value to translation key (without "interests." prefix).
  static String? _interestKeyFor(String raw) {
    switch (raw) {
      case 'Watches':
        return 'interestWatches';
      case 'Perfumes':
        return 'interestPerfumes';
      case 'Sneakers':
        return 'interestSneakers';
      case 'Jewelry':
        return 'interestJewelry';
      case 'Handbags':
        return 'interestHandbags';
      case 'Makeup & Skincare':
        return 'interestMakeupAndSkincare';
      case 'Gadgets':
        return 'interestGadgets';
      case 'Gaming':
        return 'interestGaming';
      case 'Photography':
        return 'interestPhotography';
      case 'Home Decor':
        return 'interestHomeDecor';
      case 'Plants':
        return 'interestPlants';
      case 'Coffee & Tea':
        return 'interestCoffeeAndTea';
      case 'Books':
        return 'interestBooks';
      case 'Fitness Gear':
        return 'interestFitnessGear';
      case 'Car Accessories':
        return 'interestCarAccessories';
      case 'Music Instruments':
        return 'interestMusicInstruments';
      case 'Art':
        return 'interestArt';
      case 'DIY & Crafts':
        return 'interestDiyAndCrafts';
      default:
        return null;
    }
  }
}
