# GifJot branding assets

- `GifJot-AppIcon-1024.png` is the high-resolution app-icon master. The
  production macOS sizes are in `Assets.xcassets/AppIcon.appiconset`.
- `GifJot-Watermark.png` is the transparent high-resolution watermark master.
  Compiled 1x and 2x copies are in `Assets.xcassets/Watermark.imageset`.

The watermark is intentionally an optional resource. GifJot's current product
promise is that exported recordings are local and unwatermarked, so this asset
must not be burned into every GIF without an explicit product decision.
