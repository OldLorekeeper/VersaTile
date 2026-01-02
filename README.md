# VersaTile

**VersaTile** is a hybrid tiling assistant for KDE Plasma 6 (Wayland). It bridges the gap between traditional tiling (grids) and absolute coordinate systems, allowing you to snap windows to precise coordinates or percentage-based layouts instantly.

## Features

- **Hybrid Layout Engine:** Supports three coordinate systems simultaneously:
    
    - **Absolute Pixels:** Define exact geometry (e.g., `1920x1080` at `0,0`) for maximum precision and specific window placement.
        
    - **Percentages:** Responsive layouts that adapt to any screen resolution (e.g., `50%` width).
        
    - **Grids:** Standard tiling grids (e.g., `2x2`, `3x1`).
        
- **Smart Popup UI:**
    
    - Appears automatically when you start moving a window.
        
    - **Opposite-Side Logic:** If you move a window on the _left_ of the screen, the popup appears on the _right_ (and vice versa) so it never obstructs your view.
        
- **Visual Previews:** See exactly where the window will snap before you click.
    
- **Multi-Monitor Support:** Correctly handles absolute coordinates across multiple displays.
    

## Prerequisites

- **KDE Plasma 6.0+**
    
- **Wayland** session (X11 is not actively tested)
    

## Installation

### Option 1: Install from Source (Recommended)

1. Clone the repository:
    
    Bash
    
    ```
    git clone https://github.com/OldLorekeeper/VersaTile.git
    cd VersaTile
    ```
    
2. Install the script using `kpackagetool6`:
    
    Bash
    
    ```
    # Install the script from the source directory
    kpackagetool6 --type KWin/Script -i src/
    ```
    
3. Enable the script:
    
    - Go to **System Settings** > **Window Management** > **KWin Scripts**.
        
    - Check **VersaTile**.
        
    - Click **Apply**.
        

### Updating

To update to a newer version of the code:

Bash

```
git pull
kpackagetool6 --type KWin/Script -u src/
```

## Usage

1. **Grab a window** (hold click on the title bar) and start moving it.
    
2. The **VersaTile Popup** will appear on the opposite side of the screen.
    
3. **Click a tile** in the popup to instantly snap the window to that layout.
    
    - _Note:_ The popup hides automatically if you release the window without clicking a tile.
        

## Customization

Currently, layouts are defined directly in the source code for performance. To add your own layouts:

1. Open `src/contents/ui/main.qml`.
    
2. Locate the `rawLayouts` property at the top of the file.
    
3. Add your layout string.
    

**Supported Formats:**

- **Grid:** `"2x2"` (Columns x Rows)
    
- **Percentages:** `"x,y,w,h"` (0-100 range)
    
    - Example: `"0,0,50,100"` (Left half vertical split)
        
- **Pixels:** `"x,y,w,h"` (Values > 100 or suffixed with `px`)
    
    - Example: `"0,0,1920px,1080px"` (1080p window at top-left)
        
- **Combined:** Join multiple tiles with `+`
    
    - Example: `"0,0,50,100+50,0,50,100"` (Two vertical splits)
        

## License

This project is licensed under the **GPLv3 License**. See the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.

## Author

**OldLorekeeper**
