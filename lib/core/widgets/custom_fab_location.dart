import 'package:flutter/material.dart';

/// Custom FloatingActionButton location that positions the FAB
/// exactly 15px above the bottom navigation bar
class CustomFabLocation extends FloatingActionButtonLocation {
  const CustomFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Calculate bottom navigation bar height
    // Structure: SafeArea padding + margin(20) + container padding(8) + GNav padding(10) + content(~36)
    // Total nav height: ~74px + SafeArea padding
    final bottomNavHeight = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.contentBottom -
        15.0; // 15px spacing above nav bar

    // Standard FAB size is 56x56
    const fabSize = 56.0;
    const padding = 16.0; // Standard padding from edge

    return Offset(
      scaffoldGeometry.scaffoldSize.width - fabSize - padding,
      bottomNavHeight - fabSize,
    );
  }

  @override
  String toString() => 'CustomFabLocation';
}

