import 'dart:math' as math;

import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2 contrast ratio between two colors, from 1 (none) to 21.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [foreground] as it appears painted over [background].
Color over(Color foreground, Color background) =>
    Color.alphaBlend(foreground, background);

/// The pairings the app actually paints, held to WCAG AA: 4.5:1 for text,
/// 3:1 for icons and the edges of controls. Brand colors drift below these
/// easily — bittersweet on white is 2.7:1 — so the pairs are pinned here.
void main() {
  const text = 4.5;
  const nonText = 3.0;

  final themes = {'light': AppTheme.lightTheme, 'dark': AppTheme.darkTheme};

  for (final MapEntry(key: mode, value: theme) in themes.entries) {
    group('$mode mode', () {
      final scheme = theme.colorScheme;
      final page = theme.scaffoldBackgroundColor;
      final card = theme.cardTheme.color!;
      final navBar = theme.navigationBarTheme.backgroundColor!;
      final facilityCard = scheme.facilityCard;
      final surfaces = {
        'page': page,
        'card': card,
        'nav bar': navBar,
        'facility card': facilityCard,
      };

      test('link text reads on every surface', () {
        for (final MapEntry(key: name, value: surface) in surfaces.entries) {
          expect(
            contrast(scheme.tertiaryText, surface),
            greaterThanOrEqualTo(text),
            reason: 'tertiaryText on $name',
          );
        }
      });

      test('green text reads on every surface and on the gradient', () {
        final gradientEnd = mode == 'light'
            ? AppColors.lightGradientEnd
            : AppColors.darkGradientEnd;
        for (final MapEntry(key: name, value: surface) in {
          ...surfaces,
          'onboarding gradient': gradientEnd,
        }.entries) {
          expect(
            contrast(scheme.primaryText, surface),
            greaterThanOrEqualTo(text),
            reason: 'primaryText on $name',
          );
        }
      });

      test('destructive text reads on a card and in a dialog', () {
        expect(contrast(scheme.error, card), greaterThanOrEqualTo(text));
        expect(
            contrast(scheme.onError, scheme.error), greaterThanOrEqualTo(text));
      });

      test('the active tab reads: label on the bar, icon on its pill', () {
        final labelStyle = theme.navigationBarTheme.labelTextStyle!
            .resolve({WidgetState.selected})!;
        final iconColor = theme.navigationBarTheme.iconTheme!
            .resolve({WidgetState.selected})!.color!;
        final pill = over(scheme.navIndicator, navBar);

        expect(contrast(labelStyle.color!, navBar), greaterThanOrEqualTo(text));
        expect(contrast(iconColor, pill), greaterThanOrEqualTo(nonText));
        // Told apart by more than color.
        expect(labelStyle.fontWeight, AppTypography.navLabelActiveWeight);
      });

      test('inactive tabs and muted text still read', () {
        final labelStyle =
            theme.navigationBarTheme.labelTextStyle!.resolve({})!;
        expect(contrast(labelStyle.color!, navBar), greaterThanOrEqualTo(text));
        for (final MapEntry(key: name, value: surface) in surfaces.entries) {
          expect(
            contrast(scheme.onSurfaceVariant, surface),
            greaterThanOrEqualTo(text),
            reason: 'onSurfaceVariant on $name',
          );
        }
      });

      test('an input outline stands out from the page', () {
        final border =
            theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
        final gradientStart = mode == 'light'
            ? AppColors.lightGradientStart
            : AppColors.darkGradientStart;
        expect(
          contrast(border.borderSide.color, gradientStart),
          greaterThanOrEqualTo(nonText),
        );
        expect(
          contrast(border.borderSide.color, card),
          greaterThanOrEqualTo(nonText),
        );
      });

      test('the focus ring stands out from the page', () {
        expect(contrast(scheme.focusRing, page), greaterThanOrEqualTo(nonText));
      });

      test('tag chips read: text on its own tint', () {
        for (final color in [scheme.tertiaryText, scheme.primaryText]) {
          expect(
            contrast(color, over(color.tint, facilityCard)),
            greaterThanOrEqualTo(text),
          );
        }
      });
    });
  }

  test('dark mode lifts the category tones that sink into navy', () {
    // Icons on their tinted tile, on a dark card.
    final card = AppTheme.darkTheme.cardTheme.color!;
    for (final group in [
      ...FacilityCategories.quickActionGroups,
      FacilityCategories.groupOther,
    ]) {
      final tone = MarkerUtils.getColorForCategory(
        group,
        brightness: Brightness.dark,
      );
      expect(
        contrast(tone, over(tone.tintStrong, card)),
        greaterThanOrEqualTo(3.0),
        reason: group,
      );
    }
  });

  test('map pins keep one color in both modes', () {
    for (final group in FacilityCategories.quickActionGroups) {
      expect(
        MarkerUtils.getColorForCategory(group),
        MarkerUtils.getColorForCategory(group, brightness: Brightness.light),
      );
    }
    expect(
      MarkerUtils.getColorForCategory(FacilityCategories.groupHealthCare),
      AppColors.healthCare,
    );
  });

  test('dark surfaces step up in lightness as they rise', () {
    double lightness(Color c) => HSLColor.fromColor(c).lightness;
    expect(
      lightness(AppColors.darkSurface),
      greaterThan(lightness(AppColors.darkBackground)),
    );
    expect(
      lightness(AppColors.darkNavBar),
      greaterThan(lightness(AppColors.darkSurface)),
    );
    // And cards get an outline there, where a shadow can't be seen.
    expect(AppTheme.darkTheme.colorScheme.cardOutline, isNotNull);
    expect(AppTheme.lightTheme.colorScheme.cardOutline, isNull);
  });

  test('the scrim is heavier on navy', () {
    expect(
      AppTheme.darkTheme.colorScheme.modalScrim.a,
      greaterThan(AppTheme.lightTheme.colorScheme.modalScrim.a),
    );
    expect(
      AppTheme.lightTheme.dialogTheme.barrierColor,
      AppTheme.lightTheme.colorScheme.modalScrim,
    );
    expect(
      AppTheme.darkTheme.bottomSheetTheme.modalBarrierColor,
      AppTheme.darkTheme.colorScheme.modalScrim,
    );
  });
}
