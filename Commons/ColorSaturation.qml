// File: Commons/ColorSaturation.qml
// =============================================================================
// Per-slot color saturation post-processor.
// Each of the 7 semantic slots (primary, secondary, tertiary, error, surface,
// background, outline) can have its saturation multiplied independently.
// The multiplier is read from Settings and applied via ColorsConvert.applySaturation().
//
// Functions:
//   slotOf(token)        - Map a color token name to its saturation slot
//   satFor(token)        - Get the current saturation multiplier for a token
//   apply(token, hex)    - Apply per-slot saturation multiplier to a hex color
//
// Properties:
//   saturationPrimary    - Saturation multiplier for the primary slot (0.0-1.0+)
//   saturationSecondary  - Saturation multiplier for the secondary slot
//   saturationTertiary   - Saturation multiplier for the tertiary slot
//   saturationSurface    - Saturation multiplier for the surface slot
//   saturationBackground - Saturation multiplier for the background slot
//   saturationError      - Saturation multiplier for the error slot
//   saturationOutline    - Saturation multiplier for the outline slot
//
//   slotTokens           - Map of slot name → array of token names
//   slotNames            - Ordered list of slot names
//   slotDisplayNames     - Human-readable slot labels for UI
// =============================================================================

// -- Slot & Token Index --
// Slot           | Tokens
// primary        | mPrimary, mOnPrimary, mPrimaryContainer, mOnPrimaryContainer
// secondary      | mSecondary, mOnSecondary, mSecondaryContainer, mOnSecondaryContainer
// tertiary       | mTertiary, mOnTertiary, mTertiaryContainer, mOnTertiaryContainer
// error          | mError, mOnError, mErrorContainer, mOnErrorContainer
// surface        | mSurface, mOnSurface, mSurfaceVariant, mOnSurfaceVariant,
//                | mSurfaceContainerLow, mSurfaceContainer, mSurfaceContainerHigh
// background     | mBackground, mOnBackground
// outline        | mOutline, mOutlineVariant
// unaffiliated   | mShadow, mHover, mOnHover

pragma Singleton

import QtQuick
import Quickshell
import "../Helpers/ColorsConvert.js" as CC
import qs.Commons

Singleton {
  id: root

  // -- Saturation multipliers (bound from Settings) --
  property real saturationPrimary: Settings.data.colorSchemes.saturation.primary
  property real saturationSecondary: Settings.data.colorSchemes.saturation.secondary
  property real saturationTertiary: Settings.data.colorSchemes.saturation.tertiary
  property real saturationSurface: Settings.data.colorSchemes.saturation.surface
  property real saturationBackground: Settings.data.colorSchemes.saturation.background
  property real saturationError: Settings.data.colorSchemes.saturation.error
  property real saturationOutline: Settings.data.colorSchemes.saturation.outline

  // -- Slot-to-token mapping (for introspection / UI previews) --
  readonly property var slotTokens: ({
                                       "primary": ["mPrimary", "mOnPrimary", "mPrimaryContainer", "mOnPrimaryContainer"],
                                       "secondary": ["mSecondary", "mOnSecondary", "mSecondaryContainer", "mOnSecondaryContainer"],
                                       "tertiary": ["mTertiary", "mOnTertiary", "mTertiaryContainer", "mOnTertiaryContainer"],
                                       "error": ["mError", "mOnError", "mErrorContainer", "mOnErrorContainer"],
                                       "surface": ["mSurface", "mOnSurface", "mSurfaceVariant", "mOnSurfaceVariant", "mSurfaceContainerLow", "mSurfaceContainer", "mSurfaceContainerHigh"],
                                       "background": ["mBackground", "mOnBackground"],
                                       "outline": ["mOutline", "mOutlineVariant"]
                                     })

  readonly property var slotNames: ["primary", "secondary", "tertiary", "error", "surface", "background", "outline"]

  // Order for UI display
  readonly property var slotDisplayNames: ["Primary", "Secondary", "Tertiary", "Error", "Surface", "Background", "Outline"]

  // -- Saturation Presets --
  /** Pre-defined saturation profiles users can apply with one click.
  *  Each preset has a `name`, `description`, and `values` dict mapping
  *  slot names to saturation multipliers. */
  readonly property var presets: [
    {
      name: "Vibrant",
      description: "Full saturation — all colors at maximum intensity",
      icon: "brightness",
      values: {
        primary: 1.0,
        secondary: 1.0,
        tertiary: 1.0,
        error: 1.0,
        surface: 1.0,
        background: 1.0,
        outline: 1.0
      }
    },
    {
      name: "Muted",
      description: "Reduced saturation — softer, calmer tones",
      icon: "moon",
      values: {
        primary: 0.7,
        secondary: 0.7,
        tertiary: 0.7,
        error: 0.7,
        surface: 0.6,
        background: 0.55,
        outline: 0.5
      }
    },
    {
      name: "Vintage",
      description: "Warm, desaturated palette with muted neutrals",
      icon: "palette",
      values: {
        primary: 0.85,
        secondary: 0.85,
        tertiary: 0.85,
        error: 0.85,
        surface: 0.75,
        background: 0.7,
        outline: 0.6
      }
    }
  ]

  /** Map a color token name to its saturation slot.
  *  Strips the 'm' prefix and does a case-insensitive prefix match.
  *  Unaffiliated tokens (shadow, hover) fall back to "primary" slot.
  *  @param token - Token name like "mPrimary" or "mSurfaceContainerLow"
  *  @returns Slot name: "primary", "secondary", "tertiary", "error", "surface", "background", or "outline" */
  function slotOf(token) // Map token name → saturation slot
  {
    // Strip leading 'm' for lookup
    const lookup = token.startsWith("m") ? token.substring(1) : token;
    const lower = lookup.charAt(0).toLowerCase() + lookup.slice(1);

    if (lower.startsWith("primary") || lower === "onprimary" || lower === "primarycontainer" || lower === "onprimarycontainer")
      return "primary";
    if (lower.startsWith("secondary") || lower === "onsecondary" || lower === "secondarycontainer" || lower === "onsecondarycontainer")
      return "secondary";
    if (lower.startsWith("tertiary") || lower === "ontertiary" || lower === "tertiarycontainer" || lower === "ontertiarycontainer")
      return "tertiary";
    if (lower.startsWith("error") || lower === "onerror" || lower === "errorcontainer" || lower === "onerrorcontainer")
      return "error";
    if (lower.startsWith("surface"))
      return "surface";
    if (lower.startsWith("background"))
      return "background";
    if (lower.startsWith("outline"))
      return "outline";
    return "primary"; // fallback for unaffiliated tokens (shadow, hover)
  }

  /** Get the current saturation multiplier for any token.
  *  Resolves the slot via slotOf(), then looks up the corresponding property.
  *  @param token - Token name like "mPrimary"
  *  @returns Saturation multiplier (0.0-1.0+) */
  function satFor(token) // Get saturation multiplier for a token
  {
    const slot = root.slotOf(token);
    return root["saturation" + slot.charAt(0).toUpperCase() + slot.slice(1)];
  }

  /** Apply per-slot saturation to a hex color.
  *  Returns early (no-op) for transparent/empty colors and when multiplier ≈ 1.0.
  *  @param token - Token name (to determine which saturation multiplier to use)
  *  @param hex - Hex color string (with or without #)
  *  @returns Hex string with saturation applied */
  function apply(token, hex) // Apply saturation multiplier to a hex color
  {
    if (!hex || hex === "#00000000" || hex.length < 4)
      return hex;
    const mult = root.satFor(token);
    // Skip conversion when multiplier is effectively 1.0 (avoids unnecessary parse+stringify)
    if (Math.abs(mult - 1.0) < 0.001)
      return hex;
    return CC.applySaturation(hex, mult);
  }

  // === MD3 Color Derivation Wrappers (exposed to qs.Commons consumers via ColorSaturation) ===

  /** Generate an MD3-style container color (tinted version of base accent).
  *  Delegates to ColorsConvert.generateContainerColor.
  *  @param baseColor - Source color hex string
  *  @param isDarkMode - Whether to use dark-mode formula
  *  @returns Container variant hex string */
  function generateContainerColor(baseColor, isDarkMode) // Wrapper: generate MD3 container
  {
    return CC.generateContainerColor(baseColor, isDarkMode);
  }

  /** Generate a stepped surface elevation variant.
  *  Delegates to ColorsConvert.generateSurfaceVariant.
  *  @param backgroundColor - Source background hex string
  *  @param step - Elevation step (1=low, 2=medium, 3=high)
  *  @param isDarkMode - Whether to use dark-mode formula
  *  @returns Surface variant hex string */
  function generateSurfaceVariant(backgroundColor, step, isDarkMode) // Wrapper: generate surface elevation
  {
    return CC.generateSurfaceVariant(backgroundColor, step, isDarkMode);
  }

  /** Adjust both lightness and saturation simultaneously.
  *  Delegates to ColorsConvert.adjustLightnessAndSaturation.
  *  @param hex - Source color hex
  *  @param lightnessAmount - Lightness delta (-100 to 100)
  *  @param saturationAmount - Saturation delta (-100 to 100)
  *  @returns Adjusted hex string */
  function adjustLightnessAndSaturation(hex, lightnessAmount, saturationAmount) // Wrapper: adjust L+S
  {
    return CC.adjustLightnessAndSaturation(hex, lightnessAmount, saturationAmount);
  }
}
