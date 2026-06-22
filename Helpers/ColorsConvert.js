// File: Helpers/ColorsConvert.js
// =============================================================================
// Color space conversion and manipulation utilities.
// All functions operate on 6-digit hex strings (#RRGGBB) and use the HSL/HSV
// cylindrical color models for intuitive adjustments.
//
// Functions:
//   hexToHSL(hex)                    - Convert hex → HSL object
//   hslToHex(h, s, l)               - Convert HSL → hex
//   hexToRgb(hex)                    - Convert hex → RGB object
//   rgbToHex(r, g, b)               - Convert RGB → hex
//   rgbToHsl(r, g, b)               - Convert RGB → HSL object
//   hslToRgb(h, s, l)               - Convert HSL → RGB object
//   rgbToHsv(r, g, b)               - Convert RGB → HSV object
//   hsvToRgb(h, s, v)               - Convert HSV → RGB object
//   getLuminance(hex)               - WCAG relative luminance
//   getContrastRatio(hex1, hex2)    - WCAG contrast ratio between two colors
//   isLightColor(hex)               - Heuristic: luminance > 0.5
//   adjustLightness(hex, amount)    - Add/subtract lightness (-100 to 100)
//   adjustSaturation(hex, amount)   - Add/subtract saturation (-100 to 100)
//   applySaturation(hex, mult)      - Multiply saturation (0.0 = gray, 1.0 = original)
//   adjustLightnessAndSaturation()  - Combined lightness + saturation adjustment
//   generateOnColor(base, isDark)   - Generate contrast-safe text/icon color
//   generateContainerColor()        - Generate container variant (darker/lighter)
//   generateSurfaceVariant()        - Generate stepped surface variant
// =============================================================================

// === Color Space Conversions ===

/** Convert a hex color string to HSL.
 *  @param hex - 6-digit hex string with or without leading #
 *  @returns {{h, s, l}} HSL object (h: 0-360, s: 0-100, l: 0-100) or null */
function hexToHSL(hex) // Hex → HSL
{
  const rgb = hexToRgb(hex);
  if (!rgb) return null;
  return rgbToHsl(rgb.r, rgb.g, rgb.b);
}

/** Convert HSL to a hex color string.
 *  @param h - Hue (0-360)
 *  @param s - Saturation (0-100)
 *  @param l - Lightness (0-100)
 *  @returns 6-digit hex string with # prefix */
function hslToHex(h, s, l) // HSL → hex
{
  const rgb = hslToRgb(h, s, l);
  return rgbToHex(rgb.r, rgb.g, rgb.b);
}

/** Parse a hex color string to RGB components.
 *  Returns black (0,0,0) for invalid input rather than throwing,
 *  so callers don't need null-check every conversion.
 *  @param hex - 6-digit hex string with or without leading #
 *  @returns {{r, g, b}} RGB object (0-255) */
function hexToRgb(hex) // Hex → RGB
{
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : { r: 0, g: 0, b: 0 };
}

/** Convert RGB components to a hex color string.
  * @param r - Red (0-255)
  * @param g - Green (0-255)
  * @param b - Blue (0-255)
  * @returns 6-digit hex string with # prefix */
function rgbToHex(r, g, b) // RGB → hex
{
  return "#" + [r, g, b].map(x => {
    const hex = Math.round(Math.max(0, Math.min(255, x))).toString(16);
    return hex.length === 1 ? "0" + hex : hex;
  }).join("");
}

/** Convert RGB components to HSL.
  * Uses the standard cylindrical transformation.
  * @param r - Red (0-255)
  * @param g - Green (0-255)
  * @param b - Blue (0-255)
  * @returns {{h, s, l}} HSL object (h: 0-360, s: 0-100, l: 0-100) */
function rgbToHsl(r, g, b) // RGB → HSL
{
  r /= 255;
  g /= 255;
  b /= 255;
  
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h, s, l = (max + min) / 2;

  if (max === min) {
    h = s = 0; // achromatic
  } else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    
    switch (max) {
      case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
      case g: h = ((b - r) / d + 2) / 6; break;
      case b: h = ((r - g) / d + 4) / 6; break;
    }
  }
  
  return { h: h * 360, s: s * 100, l: l * 100 };
}

/** Convert HSL to RGB components.
  * @param h - Hue (0-360)
  * @param s - Saturation (0-100)
  * @param l - Lightness (0-100)
  * @returns {{r, g, b}} RGB object (0-255) */
function hslToRgb(h, s, l) // HSL → RGB
{
  h /= 360;
  s /= 100;
  l /= 100;
  
  let r, g, b;

  if (s === 0) {
    r = g = b = l; // achromatic
  } else {
    const hue2rgb = (p, q, t) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1/6) return p + (q - p) * 6 * t;
      if (t < 1/2) return q;
      if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
      return p;
    };
    
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    
    r = hue2rgb(p, q, h + 1/3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1/3);
  }
  
  return { r: Math.round(r * 255), g: Math.round(g * 255), b: Math.round(b * 255) };
}

// -- HSV Conversions (used by UI color pickers) --

/** Convert RGB to HSV.
  * @param r - Red (0-255)
  * @param g - Green (0-255)
  * @param b - Blue (0-255)
  * @returns {{h, s, v}} HSV object (h: 0-360, s: 0-100, v: 0-100) */
function rgbToHsv(r, g, b) // RGB → HSV
{
  r /= 255;
  g /= 255;
  b /= 255;
  var max = Math.max(r, g, b), min = Math.min(r, g, b);
  var h, s, v = max;
  var d = max - min;
  s = max === 0 ? 0 : d / max;
  if (max === min) {
    h = 0;
  } else {
    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      case b:
        h = (r - g) / d + 4;
        break;
    }
    h /= 6;
  }
  return { h: h * 360, s: s * 100, v: v * 100 };
}

/** Convert HSV to RGB.
  * @param h - Hue (0-360)
  * @param s - Saturation (0-100)
  * @param v - Value (0-100)
  * @returns {{r, g, b}} RGB object (0-255) */
function hsvToRgb(h, s, v) // HSV → RGB
{
  h /= 360;
  s /= 100;
  v /= 100;

  var r, g, b;
  var i = Math.floor(h * 6);
  var f = h * 6 - i;
  var p = v * (1 - s);
  var q = v * (1 - f * s);
  var t = v * (1 - (1 - f) * s);

  switch (i % 6) {
    case 0:
      r = v;
      g = t;
      b = p;
      break;
    case 1:
      r = q;
      g = v;
      b = p;
      break;
    case 2:
      r = p;
      g = v;
      b = t;
      break;
    case 3:
      r = p;
      g = q;
      b = v;
      break;
    case 4:
      r = t;
      g = p;
      b = v;
      break;
    case 5:
      r = v;
      g = p;
      b = q;
      break;
  }

  return { r: Math.round(r * 255), g: Math.round(g * 255), b: Math.round(b * 255) };
}

// === WCAG Contrast & Luminance ===

/** Calculate the relative luminance of a color per WCAG 2.1 (sRGB linearization).
  * Used as the basis for contrast ratio calculations.
  * @param hex - 6-digit hex string
  * @returns Relative luminance (0.0 = black, 1.0 = white) */
function getLuminance(hex) // WCAG relative luminance
{
  const rgb = hexToRgb(hex);
  const [r, g, b] = [rgb.r, rgb.g, rgb.b].map(val => {
    val /= 255;
    return val <= 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** Calculate the contrast ratio between two colors per WCAG 2.1.
  * Ratio ranges from 1:1 (identical luminance) to 21:1 (black on white).
  * @param hex1 - First color hex
  * @param hex2 - Second color hex
  * @returns Contrast ratio (≥4.5 for AA normal text, ≥3.0 for AA large text) */
function getContrastRatio(hex1, hex2) // WCAG contrast ratio
{
  const lum1 = getLuminance(hex1);
  const lum2 = getLuminance(hex2);
  const brightest = Math.max(lum1, lum2);
  const darkest = Math.min(lum1, lum2);
  return (brightest + 0.05) / (darkest + 0.05);
}

/** Quick heuristic test: is this color perceived as "light"?
  * Threshold of 0.5 luminance is a common approximation for WCAG guidance.
  * @param hex - 6-digit hex string
  * @returns true if luminance > 0.5 */
function isLightColor(hex) // Check if color appears light
{
  return getLuminance(hex) > 0.5;
}

// === Color Adjustments ===

/** Add or subtract lightness from a color.
  * Values outside 0-100 are clamped.
  * @param hex - Source color
  * @param amount - Lightness delta (-100 to 100, positive = lighter)
  * @returns Adjusted hex string */
function adjustLightness(hex, amount) // Add/subtract lightness
{
  const hsl = hexToHSL(hex);
  hsl.l = Math.max(0, Math.min(100, hsl.l + amount));
  return hslToHex(hsl.h, hsl.s, hsl.l);
}

/** Add or subtract saturation from a color.
  * Values outside 0-100 are clamped.
  * @param hex - Source color
  * @param amount - Saturation delta (-100 to 100, positive = more saturated)
  * @returns Adjusted hex string */
function adjustSaturation(hex, amount) // Add/subtract saturation
{
  const hsl = hexToHSL(hex);
  hsl.s = Math.max(0, Math.min(100, hsl.s + amount));
  return hslToHex(hsl.h, hsl.s, hsl.l);
}

/** Apply a saturation multiplier to a hex color.
  * 0.0 = fully desaturated (grayscale), 1.0 = full source saturation.
  * Values >1.0 boost saturation beyond original (up to 100).
  * Used by the ColorSaturation post-processing layer.
  * @param hex - Source color hex
  * @param multiplier - 0.0 (gray) to ~1.5 (boosted)
  * @returns Adjusted hex string */
function applySaturation(hex, multiplier) // Multiply saturation
{
  const hsl = hexToHSL(hex);
  if (!hsl) return hex;
  hsl.s = Math.max(0, Math.min(100, hsl.s * multiplier));
  return hslToHex(hsl.h, hsl.s, hsl.l);
}

/** Adjust both lightness and saturation simultaneously.
  * @param hex - Source color
  * @param lightnessAmount - Lightness delta (-100 to 100)
  * @param saturationAmount - Saturation delta (-100 to 100)
  * @returns Adjusted hex string */
function adjustLightnessAndSaturation(hex, lightnessAmount, saturationAmount) // Combined L+S adjustment
{
  const hsl = hexToHSL(hex);
  hsl.l = Math.max(0, Math.min(100, hsl.l + lightnessAmount));
  hsl.s = Math.max(0, Math.min(100, hsl.s + saturationAmount));
  return hslToHex(hsl.h, hsl.s, hsl.l);
}

// === Semantic Color Generation ===

/** Generate an "on" color (for text/icons) that has sufficient contrast
  * against the base color per WCAG AA (≥4.5:1).
  * Tries pure black/white first, falls back to near-black/near-white.
  * @param baseColor - The background/base color hex
  * @param isDarkMode - Whether the current theme is dark mode
  * @returns Contrast-safe hex string for text/icons */
function generateOnColor(baseColor, isDarkMode) // Generate contrast-safe text color
{
  const isBaseLight = isLightColor(baseColor);
  
  // If base is light, we need dark text; if base is dark, we need light text
  if (isBaseLight) {
    // Try black first (maximum contrast)
    let testColor = "#000000";
    if (getContrastRatio(baseColor, testColor) >= 4.5) {
      return testColor;
    }
    // Fallback to dark gray
    return "#1c1b1f";
  } else {
    // Try white first (maximum contrast)
    let testColor = "#ffffff";
    if (getContrastRatio(baseColor, testColor) >= 4.5) {
      return testColor;
    }
    // Fallback to light gray
    return "#e6e1e5";
  }
}

/** Generate a container variant of a base color.
  * In dark mode: darker and more saturated.
  * In light mode: lighter and less saturated.
  * Approximates Material Design 3 container color semantics.
  * @param baseColor - Source color hex
  * @param isDarkMode - Whether the current theme is dark mode
  * @returns Container variant hex string */
function generateContainerColor(baseColor, isDarkMode) // Generate MD3-style container color
{
  const rgb = hexToRgb(baseColor);
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
  
  if (isDarkMode) {
    // Dark mode: containers go darker (-20 lightness) and +10 saturation
    hsl.l = Math.max(10, Math.min(30, hsl.l - 20));
    hsl.s = Math.min(100, hsl.s + 10);
  } else {
    // Light mode: containers go lighter (+30 lightness) and -10 saturation
    hsl.l = Math.min(90, Math.max(75, hsl.l + 30));
    hsl.s = Math.max(0, hsl.s - 10);
  }
  
  const newRgb = hslToRgb(hsl.h, hsl.s, hsl.l);
  return rgbToHex(newRgb.r, newRgb.g, newRgb.b);
}

/** Generate stepped surface variant colors (e.g. surface container low/medium/high).
  * Progressively lightens in dark mode, darkens in light mode.
  * @param backgroundColor - Source background color hex
  * @param step - Elevation step (0 = base, 1+ = progressively further from base)
  * @param isDarkMode - Whether the current theme is dark mode
  * @returns Surface variant hex string */
function generateSurfaceVariant(backgroundColor, step, isDarkMode) // Generate surface elevation variant
{
  const rgb = hexToRgb(backgroundColor);
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
  
  if (isDarkMode) {
    // Dark mode: higher surfaces are lighter (closer to white)
    hsl.l = Math.min(100, hsl.l + (step * 3));
  } else {
    // Light mode: higher surfaces are darker (closer to black)
    hsl.l = Math.max(0, hsl.l - (step * 2));
  }
  
  const newRgb = hslToRgb(hsl.h, hsl.s, hsl.l);
  return rgbToHex(newRgb.r, newRgb.g, newRgb.b);
}
