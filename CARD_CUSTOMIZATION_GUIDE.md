# WishlistCardWidget - Customization Guide

## 🎨 How to Customize the New Card Design

### Quick Reference: Where to Find What

```dart
ModernWishlistCard (lib/core/widgets/modern_wishlist_card.dart)
├── _buildCard()               → Main container
├── _buildHeader()             → Avatar + Title + Status Pill
├── _buildCleanStats()         → 3 stats in a row
├── _buildStatItem()           → Individual stat (Icon + Value + Label)
├── _buildActionRow()          → Menu icon + Add Wish button
└── _buildBottomProgressBar()  → Progress indicator
```

---

## 🎯 Common Customizations

### 1. **Change Card Corner Radius**

**Current:** 24px
**Location:** Line ~129, `_buildCard()`

```dart
// Find this:
borderRadius: BorderRadius.circular(24),

// Change to:
borderRadius: BorderRadius.circular(20),  // Less rounded
borderRadius: BorderRadius.circular(28),  // More rounded
```

### 2. **Adjust Avatar Size**

**Current:** 56x56px
**Location:** Line ~183, `_buildHeader()`

```dart
// Find this:
Container(
  width: 56,
  height: 56,
  // ...
)

// Change to:
Container(
  width: 60,  // Larger
  height: 60,
  // ...
)
```

### 3. **Change Title Font Size**

**Current:** 18px Poppins Bold
**Location:** Line ~226, `_buildHeader()`

```dart
// Find this:
style: GoogleFonts.poppins(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  // ...
),

// Change to:
style: GoogleFonts.poppins(
  fontSize: 20,  // Larger
  fontWeight: FontWeight.w800,  // Bolder
  // ...
),
```

### 4. **Modify Stat Icon Size**

**Current:** 28px
**Location:** Line ~313, `_buildStatItem()`

```dart
// Find this:
Icon(
  icon,
  color: color,
  size: 28,
),

// Change to:
Icon(
  icon,
  color: color,
  size: 32,  // Larger
),
```

### 5. **Adjust Progress Bar Height**

**Current:** 6px
**Location:** Line ~444, `_buildBottomProgressBar()`

```dart
// Find this:
LinearProgressIndicator(
  value: _progressAnimation.value,
  backgroundColor: AppColors.borderLight,
  minHeight: 6,
  // ...
)

// Change to:
LinearProgressIndicator(
  value: _progressAnimation.value,
  backgroundColor: AppColors.borderLight,
  minHeight: 4,  // Slimmer
  // Or
  minHeight: 8,  // Thicker
  // ...
)
```

### 6. **Change Status Pill Colors**

**Current:** Green (Public) / Blue (Private)
**Location:** Line ~265, `_buildStatusPill()`

```dart
// Find this:
final backgroundColor = isPublic
    ? AppColors.success.withOpacity(0.15)
    : AppColors.info.withOpacity(0.15);
final textColor = isPublic ? AppColors.success : AppColors.info;

// Change to:
final backgroundColor = isPublic
    ? AppColors.primary.withOpacity(0.15)  // Purple
    : AppColors.error.withOpacity(0.15);   // Red
final textColor = isPublic ? AppColors.primary : AppColors.error;
```

### 7. **Modify Card Shadow**

**Current:** 8dp normal, 12dp hover
**Location:** Line ~136, `_buildCard()`

```dart
// Find this:
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.08),
    offset: Offset(0, _isHovered ? 8 : 4),
    blurRadius: _isHovered ? 24 : 16,
    spreadRadius: 0,
  ),
],

// Change to softer shadow:
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),  // Lighter
    offset: Offset(0, _isHovered ? 6 : 2),                       // Closer
    blurRadius: _isHovered ? 20 : 12),                           // Less blur
    spreadRadius: 0,
  ),
],
```

### 8. **Change "Add Wish" Button Text**

**Current:** "Add Wish"
**Location:** Line ~414, `_buildActionRow()`

```dart
// Find this:
Text(
  'Add Wish',
  style: GoogleFonts.poppins(...),
),

// Change to:
Text(
  'Add Gift',     // Different text
  // Or
  'New Item',     // Alternative
  style: GoogleFonts.poppins(...),
),
```

### 9. **Adjust Card Padding**

**Current:** 20px all around
**Location:** Line ~149, `_buildCard()`

```dart
// Find this:
Padding(
  padding: const EdgeInsets.all(20),
  child: Column(...),
),

// Change to:
Padding(
  padding: const EdgeInsets.all(24),  // More spacious
  // Or
  padding: const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,  // Less vertical space
  ),
  child: Column(...),
),
```

### 10. **Modify Hover Lift Effect**

**Current:** 4px lift on hover
**Location:** Line ~117, `build()`

```dart
// Find this:
transform: Matrix4.identity()
  ..translate(0.0, _isHovered ? -4.0 : 0.0),

// Change to:
transform: Matrix4.identity()
  ..translate(0.0, _isHovered ? -8.0 : 0.0),  // More dramatic
// Or
transform: Matrix4.identity()
  ..translate(0.0, _isHovered ? -2.0 : 0.0),  // Subtle
```

---

## 🎨 Color Themes

### Option A: Monochrome (Elegant)
```dart
// All stats same color (grey scale)
_buildStatItem(
  icon: Icons.card_giftcard_rounded,
  value: widget.totalItems.toString(),
  label: 'Gifts',
  color: AppColors.textPrimary,  // All grey
),
```

### Option B: Gradient Colors
```dart
// Use gradient for accent color
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [_accentColor, _accentColor.withOpacity(0.6)],
  ),
  borderRadius: BorderRadius.circular(24),
),
```

### Option C: Brand Colors
```dart
// Replace with your brand colors
final brandPrimary = Color(0xFF6366F1);
final brandSecondary = Color(0xFFEC4899);
final brandSuccess = Color(0xFF10B981);
```

---

## 🔧 Advanced Customizations

### Add a Floating Action Button Instead of Pill Button

```dart
// Replace _buildActionRow() with:
Stack(
  children: [
    // ... card content
    Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.small(
        onPressed: widget.onAddItem,
        backgroundColor: _accentColor,
        child: Icon(Icons.add),
      ),
    ),
  ],
)
```

### Add Shine Effect on Hover

```dart
// In _buildCard(), add:
Stack(
  children: [
    // ... existing card
    if (_isHovered)
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
  ],
)
```

### Add Star Rating

```dart
// In _buildHeader(), after subtitle:
Row(
  children: List.generate(5, (index) {
    return Icon(
      index < 4 ? Icons.star : Icons.star_border,
      size: 12,
      color: Colors.amber,
    );
  }),
),
```

### Add "New" Badge

```dart
// In _buildHeader(), add:
if (widget.isNew)  // Add isNew parameter
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      'NEW',
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  ),
```

---

## 📱 Responsive Design Tips

### For Tablets (larger screens):
```dart
final isTablet = MediaQuery.of(context).size.width > 600;

// Adjust sizes:
Container(
  width: isTablet ? 72 : 56,   // Larger avatar
  height: isTablet ? 72 : 56,
  // ...
)
```

### For Small Phones:
```dart
final isSmallPhone = MediaQuery.of(context).size.width < 360;

// Reduce sizes:
style: GoogleFonts.poppins(
  fontSize: isSmallPhone ? 16 : 18,  // Smaller title
  // ...
),
```

---

## 🎯 Best Practices

1. **Keep it Simple:** Don't add too many elements
2. **Maintain Hierarchy:** Title > Stats > Actions
3. **Use Consistent Spacing:** Multiples of 4 (4, 8, 12, 16, 20, 24)
4. **Test on Real Devices:** Check on iPhone and Android
5. **Respect Touch Targets:** Minimum 40x40px for buttons
6. **Use Theme Colors:** Stick to AppColors constants
7. **Animate Thoughtfully:** Smooth 60fps animations only
8. **Accessibility First:** Test with screen readers

---

## 🚫 What NOT to Do

❌ Don't add borders back to stat items
❌ Don't make the progress bar thicker than 8px
❌ Don't use more than 3 colors on the card
❌ Don't add too many buttons (keep it minimal)
❌ Don't reduce corner radius below 20px
❌ Don't use fonts other than Poppins (consistency)
❌ Don't animate every interaction (subtle is better)
❌ Don't forget to test on dark mode (if applicable)

---

## 📚 Further Reading

- [Material Design 3](https://m3.material.io/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Flutter Card Design Best Practices](https://flutter.dev/docs/development/ui/widgets/material)
- [Google Fonts in Flutter](https://pub.dev/packages/google_fonts)

---

## 🎉 Quick Copy-Paste Snippets

### Change to Dark Theme:
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surfaceDark,  // Dark background
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withOpacity(0.05),  // Light shadow
        offset: Offset(0, 4),
        blurRadius: 16,
      ),
    ],
  ),
  // ...
)
```

### Add Glassmorphism:
```dart
import 'dart:ui';

// Wrap card content:
ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),  // Semi-transparent
        // ...
      ),
    ),
  ),
)
```

---

**Happy Customizing! 🎨**

