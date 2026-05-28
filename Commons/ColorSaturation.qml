// File: Commons/ColorSaturation.qml
// Functions:
//   slotOf(token)        - Map a color token name to its saturation slot
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
import qs.Commons
import "../Helpers/ColorsConvert.js" as CC

Singleton {
  id: root

  // -- Saturation multipliers (bound from Settings) --
  property real saturationPrimary:     Settings.data.colorSchemes.saturation.primary
  property real saturationSecondary:   Settings.data.colorSchemes.saturation.secondary
  property real saturationTertiary:    Settings.data.colorSchemes.saturation.tertiary
  property real saturationSurface:     Settings.data.colorSchemes.saturation.surface
  property real saturationBackground:  Settings.data.colorSchemes.saturation.background
  property real saturationError:       Settings.data.colorSchemes.saturation.error
  property real saturationOutline:     Settings.data.colorSchemes.saturation.outline

  // -- Slot-to-token mapping (for introspection / UI previews) --
  readonly property var slotTokens: ({
    "primary":    ["mPrimary", "mOnPrimary", "mPrimaryContainer", "mOnPrimaryContainer"],
    "secondary":  ["mSecondary", "mOnSecondary", "mSecondaryContainer", "mOnSecondaryContainer"],
    "tertiary":   ["mTertiary", "mOnTertiary", "mTertiaryContainer", "mOnTertiaryContainer"],
    "error":      ["mError", "mOnError", "mErrorContainer", "mOnErrorContainer"],
    "surface":    ["mSurface", "mOnSurface", "mSurfaceVariant", "mOnSurfaceVariant",
                   "mSurfaceContainerLow", "mSurfaceContainer", "mSurfaceContainerHigh"],
    "background": ["mBackground", "mOnBackground"],
    "outline":    ["mOutline", "mOutlineVariant"]
  })

  readonly property var slotNames: ["primary", "secondary", "tertiary", "error",
                                    "surface", "background", "outline"]

  // Order for UI display
  readonly property var slotDisplayNames: [
    "Primary", "Secondary", "Tertiary", "Error",
    "Surface", "Background", "Outline"
  ]

  // -- Map token name → slot name --
  function slotOf(token) {
    // Strip leading 'm' for lookup
    const lookup = token.startsWith("m") ? token.substring(1) : token;
    const lower = lookup.charAt(0).toLowerCase() + lookup.slice(1);

    if (lower.startsWith("primary")   || lower === "onprimary"   || lower === "primarycontainer"   || lower === "onprimarycontainer")   return "primary";
    if (lower.startsWith("secondary") || lower === "onsecondary" || lower === "secondarycontainer" || lower === "onsecondarycontainer") return "secondary";
    if (lower.startsWith("tertiary")  || lower === "ontertiary"  || lower === "tertiarycontainer"  || lower === "ontertiarycontainer")  return "tertiary";
    if (lower.startsWith("error")     || lower === "onerror"     || lower === "errorcontainer"     || lower === "onerrorcontainer")     return "error";
    if (lower.startsWith("surface"))  return "surface";
    if (lower.startsWith("background")) return "background";
    if (lower.startsWith("outline"))  return "outline";
    return "primary"; // fallback for unaffiliated tokens (shadow, hover)
  }

  // -- Get current saturation for any token --
  function satFor(token) {
    const slot = root.slotOf(token);
    return root["saturation" + slot.charAt(0).toUpperCase() + slot.slice(1)];
  }

  // -- Apply saturation to a hex color for a given token --
  function apply(token, hex) {
    if (!hex || hex === "#00000000" || hex.length < 4) return hex;
    const mult = root.satFor(token);
    // No-op if multiplier is 1.0
    if (Math.abs(mult - 1.0) < 0.001) return hex;
    return CC.applySaturation(hex, mult);
  }
}
