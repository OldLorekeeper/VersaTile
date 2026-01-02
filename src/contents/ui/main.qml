// ------------------------------------------------------------------------------
// VersaTile Main Controller
// Core logic for hybrid tiling (Pixels/Percentages) and popup management.
// ------------------------------------------------------------------------------
//
// DEVELOPMENT RULES:
// 1. Formatting: Compact layout, no vertical whitespace inside blocks.
// 2. Separators: Sandwich headers (// ------) at column 0.
// 3. Logic: Declarative bindings, Timer polling for hit-tests.
// 4. Safety: Strong typing where possible.
//
// ------------------------------------------------------------------------------

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// ------------------------------------------------------------------------------
// 1. Properties & Prerequisites
// ------------------------------------------------------------------------------
// Purpose: Define external config and internal state.

Item {
    id: root
    readonly property var rawLayouts: [
        "720px,57px,2000px,1250px",
        "970px,203px,1500px,950px",
        "1220px,354px,1000px,650px",
        "720px,57px,2000px,1250px+100px,354px,1000px,650px+2344px,354px,1000px,650px",
        "720px,57px,2000px,1250px+100px,25px,1000px,650px+2344px,25px,1000px,650px+100px,700px,1000px,650px+2344px,700px,1000px,650px",
        "1120px,79px,1200px,1200px+100px,354px,1000px,650px+2344px,354px,1000px,650px",
        "2x1", "3x1", "2x2",
        "0,0,25,100+75,0,25,100+25,0,50,100",
        "0,0,67,100+67,0,33,100",
        "0,0,33,100+33,0,67,100"
    ]
    property var parsedLayouts: []
    property var activeClient: null
    property bool isMoving: false
    property int hoveredLayoutIdx: -1
    property int hoveredTileIdx: -1
// Visual state for the inner popup canvas
    property int popupX: 0
    property int popupY: 0

    Component.onCompleted: {
        console.info("VersaTile: Initializing...")
        var parsed = []
        for (var i = 0; i < rawLayouts.length; i++) {
            var layoutObj = parseLayout(rawLayouts[i])
            if (layoutObj) parsed.push(layoutObj)
        }
        parsedLayouts = parsed
        var clients = Workspace.stackingOrder
        for (var j = 0; j < clients.length; j++) {
            connectWindow(clients[j])
        }
    }

    Connections {
        target: Workspace
        function onWindowAdded(client) {
            connectWindow(client)
        }
    }

// ------------------------------------------------------------------------------
// 2. Main Logic
// ------------------------------------------------------------------------------
// Purpose: Handle window events and layout parsing.

    function connectWindow(client) {
        if (!client || !client.normalWindow) return
            try { client.interactiveMoveResizeStarted.disconnect(client.moveHandler) } catch(e) {}
            client.moveHandler = function() {
                root.isMoving = true
                root.activeClient = client
                showPopup()
            }
            client.interactiveMoveResizeStarted.connect(client.moveHandler)
            client.interactiveMoveResizeFinished.connect(function() {
                if (root.hoveredLayoutIdx !== -1 && root.hoveredTileIdx !== -1) {
                    applyLayout(root.hoveredLayoutIdx, root.hoveredTileIdx)
                }
                root.isMoving = false
                root.activeClient = null
                popup.visible = false
                root.hoveredLayoutIdx = -1
                root.hoveredTileIdx = -1
            })
    }

    function parseLayout(str) {
        var layout = { tiles: [] }
        var parts = str.split('+')
        if (parts.length === 1 && parts[0].indexOf(',') === -1 && parts[0].indexOf('x') !== -1) {
            var dim = parts[0].split('x')
            var cols = parseInt(dim[0]), rows = parseInt(dim[1])
            if (!isNaN(cols) && !isNaN(rows)) {
                var w = 100.0 / cols, h = 100.0 / rows
                for (var r = 0; r < rows; r++) {
                    for (var c = 0; c < cols; c++) {
                        layout.tiles.push({ type: '%', x: c * w, y: r * h, w: w, h: h })
                    }
                }
                return layout
            }
        }
        for (var i = 0; i < parts.length; i++) {
            var coords = parts[i].split(',')
            if (coords.length === 4) {
                var isPx = false, val = []
                for (var k = 0; k < 4; k++) {
                    var s = coords[k].trim()
                    if (s.indexOf('px') !== -1) isPx = true
                        var v = parseInt(s)
                        if (v > 100) isPx = true
                            val.push(v)
                }
                layout.tiles.push({ type: isPx ? 'px' : '%', x: val[0], y: val[1], w: val[2], h: val[3] })
            }
        }
        return layout
    }

    function applyLayout(lIdx, tIdx) {
        if (!root.activeClient || !root.parsedLayouts[lIdx]) return
            var tile = root.parsedLayouts[lIdx].tiles[tIdx]
            var screen = Workspace.activeScreen
            var area = Workspace.clientArea(KWin.FullScreenArea, screen, Workspace.currentDesktop)
            var finalRect = { x: 0, y: 0, w: 0, h: 0 }
            if (tile.type === "px") {
                finalRect.x = area.x + tile.x
                finalRect.y = area.y + tile.y
                finalRect.w = tile.w
                finalRect.h = tile.h
            } else {
                finalRect.x = area.x + (tile.x / 100.0 * area.width)
                finalRect.y = area.y + (tile.y / 100.0 * area.height)
                finalRect.w = (tile.w / 100.0 * area.width)
                finalRect.h = (tile.h / 100.0 * area.height)
            }
            root.activeClient.frameGeometry = Qt.rect(finalRect.x, finalRect.y, finalRect.w, finalRect.h)
    }

    function showPopup() {
        if (!root.activeClient) return
            var cursor = Workspace.cursorPos
            var area = Workspace.clientArea(KWin.FullScreenArea, Workspace.activeScreen, Workspace.currentDesktop)
            var centerX = area.x + (area.width / 2)
            var margin = 50
        // Calculate relative position for the background item within the full-screen canvas
            root.popupX = (cursor.x < centerX) ? (area.width - background.width - margin) : margin
            root.popupY = (area.height / 2) - (background.height / 2)
            popup.visible = true
    }

// ------------------------------------------------------------------------------
// 3. Visuals & Interaction
// ------------------------------------------------------------------------------
// Purpose: Render fullscreen overlay and handle hit-testing via timer.

    PlasmaCore.Dialog {
        id: popup
        visible: false
        x: Workspace.activeScreen.geometry.x
        y: Workspace.activeScreen.geometry.y
        width: Workspace.activeScreen.geometry.width
        height: Workspace.activeScreen.geometry.height
        flags: Qt.Popup | Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
        location: PlasmaCore.Types.Desktop
        backgroundHints: PlasmaCore.Types.NoBackground
        mainItem: canvas
        outputOnly: true // Click-through / Focus transparent

        Timer {
            interval: 50
            running: popup.visible && root.isMoving
            repeat: true
            onTriggered: {
                var cursor = Workspace.cursorPos
                var foundL = -1, foundT = -1
                for (var i = 0; i < layoutRepeater.count; i++) {
                    var item = layoutRepeater.itemAt(i)
                    var itemLocal = item.mapFromGlobal(cursor)
                    if (itemLocal.x >= 0 && itemLocal.x <= item.width && itemLocal.y >= 0 && itemLocal.y <= item.height) {
                        foundL = i
                        var tileRep = item.children[0]
                        for (var t = 0; t < tileRep.count; t++) {
                            var tileItem = tileRep.itemAt(t)
                            var tileLocal = tileItem.mapFromGlobal(cursor)
                            if (tileLocal.x >= 0 && tileLocal.x <= tileItem.width && tileLocal.y >= 0 && tileLocal.y <= tileItem.height) {
                                foundT = t
                                break
                            }
                        }
                        break
                    }
                }
                if (root.hoveredLayoutIdx !== foundL || root.hoveredTileIdx !== foundT) {
                    root.hoveredLayoutIdx = foundL
                    root.hoveredTileIdx = foundT
                }
            }
        }

        Item {
            id: canvas
            anchors.fill: parent
            Rectangle {
                id: background
                x: root.popupX
                y: root.popupY
                color: "transparent"
                width: gridLayout.implicitWidth + 40
                height: gridLayout.implicitHeight + 40
                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.95
                    radius: 12
                    border.color: Kirigami.Theme.highlightColor
                    border.width: 1
                }
                GridLayout {
                    id: gridLayout
                    anchors.centerIn: parent
                    columns: 3
                    rowSpacing: 15
                    columnSpacing: 15
                    Repeater {
                        id: layoutRepeater
                        model: root.parsedLayouts
                        Rectangle {
                            property int layoutIndex: index
                            width: 160
                            height: 90
                            color: "transparent"
                            border.color: (root.hoveredLayoutIdx === index) ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            border.width: (root.hoveredLayoutIdx === index) ? 2 : 1
                            opacity: (root.hoveredLayoutIdx === index) ? 1.0 : 0.5
                            radius: 4
                            Repeater {
                                model: modelData.tiles
                                Rectangle {
                                    property var tile: modelData
                                    property bool isPx: tile.type === "px"
                                    property bool isActive: (root.hoveredLayoutIdx === parent.layoutIndex && root.hoveredTileIdx === index)
                                    x: isPx ? (tile.x / 1920.0 * parent.width) : (tile.x / 100.0 * parent.width)
                                    y: isPx ? (tile.y / 1080.0 * parent.height) : (tile.y / 100.0 * parent.height)
                                    width: isPx ? (tile.w / 1920.0 * parent.width) : (tile.w / 100.0 * parent.width)
                                    height: isPx ? (tile.h / 1080.0 * parent.height) : (tile.h / 100.0 * parent.height)
                                    color: isActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.highlightColor
                                    opacity: isActive ? 0.9 : 0.3
                                    border.color: Kirigami.Theme.textColor
                                    border.width: 1
                                    radius: 2
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------
// End
// ------------------------------------------------------------------------------
