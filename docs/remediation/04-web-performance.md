# REM-04: Web First-Load Performance

## Problem

Flutter web with CanvasKit renderer requires downloading and compiling a 7.2MB WebAssembly binary on first load. This takes 15-20 seconds on average connections, creating a poor first impression.

## Severity: HIGH

## Risk: User abandonment — 15-20 seconds exceeds acceptable load time for web apps

## Affected Modules

- All (global load time affects entire app)

## Root Cause

Flutter web defaults to CanvasKit renderer which uses Skia compiled to WebAssembly. The `canvaskit.wasm` file is 7.2MB. Even with `--no-web-resources-cdn` (local bundling), the browser must parse and compile the WASM binary before any Flutter frame renders.

## Options

### Option A: HTML Renderer (removed in Flutter 3.38+)

Not available. Flutter 3.38+ only supports CanvasKit and Skwasm.

### Option B: Loading Indicator in index.html

Add a visible loading spinner in `index.html` that displays immediately while CanvasKit loads. This doesn't reduce load time but eliminates the "blank white screen" perception.

```html
<style>
  .loading { display: flex; justify-content: center; align-items: center;
    height: 100vh; font-family: sans-serif; color: #5F5E5A; }
  .loading .spinner { width: 24px; height: 24px; border: 2px solid #D3D1C7;
    border-top-color: #0C447C; border-radius: 50%; animation: spin 0.8s linear infinite; }
  @keyframes spin { to { transform: rotate(360deg); } }
</style>
<div class="loading" id="loading">
  <div><div class="spinner"></div><p style="margin-top:16px;font-size:13px">Loading Manager Connect...</p></div>
</div>
```

Flutter removes this `div` automatically when the app renders.

### Option C: Service Worker Caching (already present)

Flutter's build already includes `flutter_service_worker.js`. After first load, subsequent visits load from cache in 2-3 seconds. The issue is first-visit only.

### Option D: Preload Hints

Add resource hints to `index.html`:
```html
<link rel="preload" href="main.dart.js" as="script">
<link rel="preload" href="canvaskit/chromium/canvaskit.wasm" as="fetch" crossorigin>
```

### Option E: Deferred Loading / Code Splitting

Not natively supported by Flutter web's dart2js compiler. Would require architectural changes.

## Recommended Approach

**Option B + D combined.** Add loading indicator + preload hints. This is the lowest-effort, highest-impact fix.

## Files Impacted

| File | Change |
|------|--------|
| `frontend/web/index.html` | MODIFY — add loading indicator + preload hints |

## Dependencies

None. Pure HTML/CSS change.

## Validation Steps

1. Clear browser cache + service worker
2. Load `http://localhost:4200`
3. Verify loading spinner appears within 1 second
4. Verify spinner disappears when app renders
5. Measure total load time (should be same but perceived as better)
6. Verify second load is 2-3 seconds (service worker cache)

## Rollback Plan

Remove the loading indicator HTML/CSS. No functional impact.

## Estimated Effort: 30 minutes
