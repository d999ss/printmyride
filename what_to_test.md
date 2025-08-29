# Print My Ride TestFlight v0.2.0 - What to Test

**Test Environment:**
- iOS 16.0+ required
- iPhone 14-16 Pro recommended 
- No login required
- No internet connection needed

**Key Features to Test:**

## 1. GPX Route Import
- Import GPX → tap Import button, select GPX file from Files app
- Sample Route → tap "Sample" to load built-in cycling route
- Verify route displays properly centered in canvas

## 2. Style Controls  
- Style → adjust Stroke width, Line caps (Round/Square/Butt)
- Shadow → toggle Enable shadow, adjust radius if enabled
- Presets → try Light, Dark, Neon style presets

## 3. Canvas Settings
- Canvas → try Paper presets (18×24, 24×36, A2)  
- Adjust margins with slider (5-25%)
- Grid → toggle Show grid, adjust spacing (10-200pt)
- HUD → toggle "Show info HUD" to see paper/DPI/points stats

## 4. Undo/Redo
- Make style/canvas changes
- Use Undo/Redo buttons in top-right
- Verify haptic feedback on changes

## 5. Text Overlay (NEW!)
- Text → set Title "Epic Mountain Ride", Subtitle "Sunday Adventure"
- Adjust title size slider (18-48pt), verify text scales in preview
- Toggle distance/elevation/date, see stats appear/disappear in overlay
- Text renders in top-left, adapts to Dark Mode colors
- Apply → text persists in overlay during editing

## 6. Save & Gallery
- Save → creates thumbnail, adds to Gallery  
- Gallery → tap cards to reopen, long-press for context menu
- Duplicate → creates "(copy)" version
- Rename → edit title, Share → system share sheet

## 7. Text Persistence (KEY!)
- Create → Text → set custom title → Save → Gallery shows custom title
- Tap gallery card → reopens editor with text overlay intact
- Text settings preserved: title, subtitle, size, toggles

## 8. Export (Key Feature!)
- Export → choose PNG 300 DPI or PDF
- Bleed → try None, 0.125", 0.25" 
- Include grid → toggle on/off
- Verify share sheet appears with exported file
- Check Files app → Documents/Exports for saved files

## 9. Rotation & Layout
- Rotate device → route stays centered inside margins
- All controls remain accessible in landscape

**Expected Behavior:**
- Route rendering at 60fps when adjusting controls
- Grid fades smoothly in/out  
- Start/end markers visible on route
- Text overlay renders cleanly at all title sizes
- Distance auto-calculates from GPX data (km format)
- Export creates pixel-accurate files matching preview

**Report Issues:**
- Screenshots appreciated for visual bugs
- Text overlays that don't persist correctly
- Export files that don't match preview  
- Performance issues (laggy controls)
- Crashes or unresponsive UI

**v0.2.0 Highlights:**
- NEW: Text overlay system with title, subtitle, distance stats
- NEW: Text persistence across save/load cycles
- Enhanced: Design system with Dark Mode support
- Improved: Consistent typography and spacing throughout