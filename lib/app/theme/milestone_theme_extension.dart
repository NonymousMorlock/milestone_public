import 'package:flutter/material.dart';
import 'package:milestone/core/res/styles/colours.dart';

@immutable
class MilestoneThemeExtension extends ThemeExtension<MilestoneThemeExtension> {
  const MilestoneThemeExtension({
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.fieldFillSubtle,
    required this.glassSurface,
    required this.navTileSurface,
    required this.clientAvatarStart,
    required this.clientAvatarMiddle,
    required this.clientAvatarEnd,
    required this.timelineAccent,
    required this.projectCardGradientStart,
    required this.projectCardGradientEnd,
    required this.imageScrim,
    required this.statusOverdue,
    required this.statusDueSoon,
    required this.statusOnTrack,
    required this.linkTileSurface,
    required this.placeholderBase,
    required this.placeholderHighlight,
    required this.placeholderSolid,
    required this.feedbackInfo,
    required this.feedbackWarning,
    required this.feedbackError,
    required this.feedbackSuccess,
    required this.loadingAccentStart,
    required this.loadingAccentEnd,
  });

  factory MilestoneThemeExtension.light(ColorScheme colorScheme) {
    return MilestoneThemeExtension(
      heroGradientStart: Colours.lightThemePrimaryColour,
      heroGradientEnd: Colours.lightThemePrimaryTint,
      fieldFillSubtle: colorScheme.primary.withValues(alpha: .12),
      glassSurface: Colors.white,
      navTileSurface: colorScheme.surfaceContainerHighest.withValues(
        alpha: .72,
      ),
      clientAvatarStart: Colours.lightThemeSecondaryColour,
      clientAvatarMiddle: Colours.lightThemeYellowColour,
      clientAvatarEnd: Colours.lightThemePrimaryColour,
      timelineAccent: Colors.green.shade600,
      projectCardGradientStart: Color.alphaBlend(
        Colours.lightThemePrimaryTint.withValues(alpha: .28),
        colorScheme.surfaceContainerHighest,
      ),
      projectCardGradientEnd: Color.alphaBlend(
        Colours.lightThemePrimaryColour.withValues(alpha: .12),
        colorScheme.surfaceContainer,
      ),
      imageScrim: Colors.black.withValues(alpha: .45),
      statusOverdue: colorScheme.error,
      statusDueSoon: Colours.lightThemeYellowColour,
      statusOnTrack: Colors.green.shade600,
      linkTileSurface: colorScheme.surfaceContainerHigh,
      placeholderBase: Colors.grey.shade300,
      placeholderHighlight: Colors.grey.shade100,
      placeholderSolid: Colors.white,
      feedbackInfo: Colors.blue.shade500,
      feedbackWarning: Colors.orange.shade500,
      feedbackError: colorScheme.error,
      feedbackSuccess: Colors.green.shade600,
      loadingAccentStart: Colours.lightThemePrimaryColour,
      loadingAccentEnd: Colours.lightThemePrimaryTint,
    );
  }

  factory MilestoneThemeExtension.dark(ColorScheme colorScheme) {
    return MilestoneThemeExtension(
      heroGradientStart: Colours.darkThemeDarkNavBarColour,
      heroGradientEnd: Colours.lightThemePrimaryColour.withValues(alpha: .92),
      fieldFillSubtle: colorScheme.surfaceContainerHighest,
      glassSurface: Colours.darkThemeDarkNavBarColour,
      navTileSurface: colorScheme.surfaceContainerHighest.withValues(
        alpha: .88,
      ),
      clientAvatarStart: Colours.lightThemePrimaryColour,
      clientAvatarMiddle: Colours.lightThemeSecondaryColour,
      clientAvatarEnd: Colours.lightThemeYellowColour,
      timelineAccent: Colors.green.shade400,
      projectCardGradientStart: Colors.blueGrey.shade900,
      projectCardGradientEnd: Colours.darkThemeDarkNavBarColour,
      imageScrim: Colors.black.withValues(alpha: .55),
      statusOverdue: colorScheme.error,
      statusDueSoon: Colours.lightThemeYellowColour,
      statusOnTrack: Colors.green.shade400,
      linkTileSurface: colorScheme.surfaceContainerHigh,
      placeholderBase: colorScheme.surfaceContainerHighest,
      placeholderHighlight: colorScheme.surfaceContainer,
      placeholderSolid: colorScheme.surface,
      feedbackInfo: Colors.blue.shade300,
      feedbackWarning: Colors.orange.shade300,
      feedbackError: colorScheme.error,
      feedbackSuccess: Colors.green.shade400,
      loadingAccentStart: Color.lerp(
        Colours.lightThemePrimaryColour,
        Colors.white,
        .24,
      )!,
      loadingAccentEnd: Color.lerp(
        Colours.lightThemePrimaryTint,
        Colors.white,
        .12,
      )!,
    );
  }

  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color fieldFillSubtle;
  final Color glassSurface;
  final Color navTileSurface;
  final Color clientAvatarStart;
  final Color clientAvatarMiddle;
  final Color clientAvatarEnd;
  final Color timelineAccent;
  final Color projectCardGradientStart;
  final Color projectCardGradientEnd;
  final Color imageScrim;
  final Color statusOverdue;
  final Color statusDueSoon;
  final Color statusOnTrack;
  final Color linkTileSurface;
  final Color placeholderBase;
  final Color placeholderHighlight;
  final Color placeholderSolid;
  final Color feedbackInfo;
  final Color feedbackWarning;
  final Color feedbackError;
  final Color feedbackSuccess;
  final Color loadingAccentStart;
  final Color loadingAccentEnd;

  @override
  MilestoneThemeExtension copyWith({
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? fieldFillSubtle,
    Color? glassSurface,
    Color? navTileSurface,
    Color? clientAvatarStart,
    Color? clientAvatarMiddle,
    Color? clientAvatarEnd,
    Color? timelineAccent,
    Color? projectCardGradientStart,
    Color? projectCardGradientEnd,
    Color? imageScrim,
    Color? statusOverdue,
    Color? statusDueSoon,
    Color? statusOnTrack,
    Color? linkTileSurface,
    Color? placeholderBase,
    Color? placeholderHighlight,
    Color? placeholderSolid,
    Color? feedbackInfo,
    Color? feedbackWarning,
    Color? feedbackError,
    Color? feedbackSuccess,
    Color? loadingAccentStart,
    Color? loadingAccentEnd,
  }) {
    return MilestoneThemeExtension(
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      fieldFillSubtle: fieldFillSubtle ?? this.fieldFillSubtle,
      glassSurface: glassSurface ?? this.glassSurface,
      navTileSurface: navTileSurface ?? this.navTileSurface,
      clientAvatarStart: clientAvatarStart ?? this.clientAvatarStart,
      clientAvatarMiddle: clientAvatarMiddle ?? this.clientAvatarMiddle,
      clientAvatarEnd: clientAvatarEnd ?? this.clientAvatarEnd,
      timelineAccent: timelineAccent ?? this.timelineAccent,
      projectCardGradientStart:
          projectCardGradientStart ?? this.projectCardGradientStart,
      projectCardGradientEnd:
          projectCardGradientEnd ?? this.projectCardGradientEnd,
      imageScrim: imageScrim ?? this.imageScrim,
      statusOverdue: statusOverdue ?? this.statusOverdue,
      statusDueSoon: statusDueSoon ?? this.statusDueSoon,
      statusOnTrack: statusOnTrack ?? this.statusOnTrack,
      linkTileSurface: linkTileSurface ?? this.linkTileSurface,
      placeholderBase: placeholderBase ?? this.placeholderBase,
      placeholderHighlight: placeholderHighlight ?? this.placeholderHighlight,
      placeholderSolid: placeholderSolid ?? this.placeholderSolid,
      feedbackInfo: feedbackInfo ?? this.feedbackInfo,
      feedbackWarning: feedbackWarning ?? this.feedbackWarning,
      feedbackError: feedbackError ?? this.feedbackError,
      feedbackSuccess: feedbackSuccess ?? this.feedbackSuccess,
      loadingAccentStart: loadingAccentStart ?? this.loadingAccentStart,
      loadingAccentEnd: loadingAccentEnd ?? this.loadingAccentEnd,
    );
  }

  @override
  MilestoneThemeExtension lerp(
    covariant ThemeExtension<MilestoneThemeExtension>? other,
    double t,
  ) {
    if (other is! MilestoneThemeExtension) return this;

    return MilestoneThemeExtension(
      heroGradientStart: Color.lerp(
        heroGradientStart,
        other.heroGradientStart,
        t,
      )!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      fieldFillSubtle: Color.lerp(fieldFillSubtle, other.fieldFillSubtle, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      navTileSurface: Color.lerp(navTileSurface, other.navTileSurface, t)!,
      clientAvatarStart: Color.lerp(
        clientAvatarStart,
        other.clientAvatarStart,
        t,
      )!,
      clientAvatarMiddle: Color.lerp(
        clientAvatarMiddle,
        other.clientAvatarMiddle,
        t,
      )!,
      clientAvatarEnd: Color.lerp(clientAvatarEnd, other.clientAvatarEnd, t)!,
      timelineAccent: Color.lerp(timelineAccent, other.timelineAccent, t)!,
      projectCardGradientStart: Color.lerp(
        projectCardGradientStart,
        other.projectCardGradientStart,
        t,
      )!,
      projectCardGradientEnd: Color.lerp(
        projectCardGradientEnd,
        other.projectCardGradientEnd,
        t,
      )!,
      imageScrim: Color.lerp(imageScrim, other.imageScrim, t)!,
      statusOverdue: Color.lerp(statusOverdue, other.statusOverdue, t)!,
      statusDueSoon: Color.lerp(statusDueSoon, other.statusDueSoon, t)!,
      statusOnTrack: Color.lerp(statusOnTrack, other.statusOnTrack, t)!,
      linkTileSurface: Color.lerp(linkTileSurface, other.linkTileSurface, t)!,
      placeholderBase: Color.lerp(placeholderBase, other.placeholderBase, t)!,
      placeholderHighlight: Color.lerp(
        placeholderHighlight,
        other.placeholderHighlight,
        t,
      )!,
      placeholderSolid: Color.lerp(
        placeholderSolid,
        other.placeholderSolid,
        t,
      )!,
      feedbackInfo: Color.lerp(feedbackInfo, other.feedbackInfo, t)!,
      feedbackWarning: Color.lerp(feedbackWarning, other.feedbackWarning, t)!,
      feedbackError: Color.lerp(feedbackError, other.feedbackError, t)!,
      feedbackSuccess: Color.lerp(feedbackSuccess, other.feedbackSuccess, t)!,
      loadingAccentStart: Color.lerp(
        loadingAccentStart,
        other.loadingAccentStart,
        t,
      )!,
      loadingAccentEnd: Color.lerp(
        loadingAccentEnd,
        other.loadingAccentEnd,
        t,
      )!,
    );
  }
}
