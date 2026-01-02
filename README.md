# VersaTile

VersaTile is a high-performance KWin script designed to tile windows efficiently using mouse gestures. It is built from the ground up to focus on code efficiency, stability, and expanded layout capabilities.

Key among its features is the ability to define layouts using **absolute pixel coordinates**, in addition to standard percentage-based and grid-based systems.

## Features

- **Hybrid Layout Engine**: Define tiles using a mix of measurement units to suit specific workflow needs:
    
    - **Percentages**: Standard relative sizing
        
    - **Grids**: Simple row/column divisions
        
    - **Absolute Pixels**: Precise coordinates for pixel-perfect layouts, essential for ultra-wide or specialized display setups
        
- **Mouse control**: A layout popup appears near your cursor. Drag the window onto a grid cell to resize it instantly.
    
- **Performance**: Built with a clean, efficient codebase to minimise overhead and ensure smooth animations and responsiveness.
    
- **Multi-Monitor Support**: Correctly handles layouts across different screen resolutions and scaling factors.
    

## Installation

### From Source

1. Clone the repository:
    
    ```
    git clone https://github.com/OldLorekeeper/VersaTile.git
    cd VersaTile
    ```
    
2. Install using `kpackagetool6`:
    
    ```
    kpackagetool6 --type=KWin/Script -i src/
    ```
    
3. Enable the script in System Settings or via command line:
    
    ```
    kwriteconfig6 --file kwinrc --group Plugins --key versatileEnabled true
    qdbus6 org.kde.KWin /KWin reconfigure
    ```
    

## Configuration

VersaTile uses a declarative syntax for defining layouts. You may define layouts using standard grids, specific coordinates (X,Y,W,H), or centered definitions.

### Layout Syntax

**1. Standard Grids** Define simple rows and columns.

- Example: `2x1` (Creates 4 equal quadrants)
    

**2. Coordinate-Based (X, Y, W, H)** Define specific positions and sizes. You can use percentages (raw numbers 0-100) or absolute pixels (`px`).

- **Syntax**: `X,Y,W,H`
    
- **Percentage Example**: `0,0,50,100 + 50,0,50,100` (Split screen vertical)
    
- **Absolute Pixel Example**: `0px,0px,1920px,1080px` (Full screen on a 1080p monitor)
    
- **Mixed Example**: `0px,0px,300px,100 + 300px,0,REST,100` (300px sidebar, remainder fills screen)
    

**3. Centered Layouts (C, W, H)** Automatically center a window of a specific size.

- **Syntax**: `C,W,H`
    
- **Example**: `C,800px,600px` (Centers an 800x600 window)
    
- **Percentage Example**: `C,50,50` (Centers a window taking up half the screen width and height)
    

## Licence

GPLv3