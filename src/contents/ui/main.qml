import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: root

    // --- 1. CONFIGURATION ---
    readonly property var rawLayouts: [
        "720px,57px,2000px,1250px",
        "970px,203px,1500px,950px",
        "1220px,354px,1000px,650px",
        "720px,57px,2000px,1250px+100px,354px,1000px,650px+2344px,354px,1000px,650px",
        "720px,57px,2000px,1250px+100px,25px,1000px,650px+2344px,25px,1000px,650px+100px,700px,1000px,650px+2344px,700px,1000px,650px",
        "1120px,79px,1200px,1200px+100px,354px,1000px,650px+2344px,354px,1000px,650px",
        "2x1",
        "3x1",
        "2x2",
        "0,0,25,100+75,0,25,100+25,0,50,100",
        "0,0,67,100+67,0,33,100",
        "0,0,33,100+33,0,67,100"
    ]

    property var parsedLayouts: []
    property var activeClient: null
    property bool isMoving: false

    // --- 2. INITIALIZATION & PARSING ---
    Component.onCompleted: {
        console.info("VersaTile: Initializing...");

        // Parse layouts
        var parsed = [];
        for (var i = 0; i < rawLayouts.length; i++) {
            var layoutObj = parseLayout(rawLayouts[i]);
            if (layoutObj) parsed.push(layoutObj);
        }
        parsedLayouts = parsed;
        console.info("VersaTile: Parsed " + parsedLayouts.length + " layouts.");

        // Hook existing windows
        var clients = Workspace.stackingOrder;
        for (var j = 0; j < clients.length; j++) {
            connectWindow(clients[j]);
        }
    }

    Connections {
        target: Workspace
        function onWindowAdded(client) {
            connectWindow(client);
        }
    }

    // --- 3. WINDOW MANAGEMENT ---
    function connectWindow(client) {
        if (!client || !client.normalWindow) return;

        // Disconnect first to avoid duplicates if re-added
        try { client.interactiveMoveResizeStarted.disconnect(client.moveHandler); } catch(e) {}

        // Define handler
        client.moveHandler = function() {
            console.info("VersaTile: Move detected for " + client.caption);
            isMoving = true;
            activeClient = client;
            showPopup();
        };

        client.interactiveMoveResizeStarted.connect(client.moveHandler);

        client.interactiveMoveResizeFinished.connect(function() {
            isMoving = false;
            activeClient = null;
            popup.visible = false;
        });
    }

    function applyLayout(layoutIndex, tileIndex) {
        if (!activeClient || !parsedLayouts[layoutIndex]) return;

        var layout = parsedLayouts[layoutIndex];
        var tile = layout.tiles[tileIndex];
        if (!tile) return;

        var screen = Workspace.activeScreen;
        var area = Workspace.clientArea(KWin.FullScreenArea, screen, Workspace.currentDesktop);
        var finalRect = { x: 0, y: 0, width: 100, height: 100 };

        if (tile.type === "px") {
            finalRect.x = area.x + tile.x;
            finalRect.y = area.y + tile.y;
            finalRect.width = tile.w;
            finalRect.height = tile.h;
        } else {
            finalRect.x = area.x + (tile.x / 100.0 * area.width);
            finalRect.y = area.y + (tile.y / 100.0 * area.height);
            finalRect.width = (tile.w / 100.0 * area.width);
            finalRect.height = (tile.h / 100.0 * area.height);
        }

        activeClient.frameGeometry = Qt.rect(finalRect.x, finalRect.y, finalRect.width, finalRect.height);
        popup.visible = false;
        isMoving = false;
    }

    // --- 4. PARSER LOGIC ---
    function parseLayout(str) {
        var layout = { tiles: [] };
        var parts = str.split('+');

        // Grid Detection
        if (parts.length === 1 && parts[0].indexOf(',') === -1 && parts[0].indexOf('x') !== -1) {
            var dim = parts[0].split('x');
            var cols = parseInt(dim[0]);
            var rows = parseInt(dim[1]);

            if (!isNaN(cols) && !isNaN(rows)) {
                var w = 100.0 / cols;
                var h = 100.0 / rows;
                for (var r = 0; r < rows; r++) {
                    for (var c = 0; c < cols; c++) {
                        layout.tiles.push({ type: '%', x: c * w, y: r * h, w: w, h: h });
                    }
                }
                return layout;
            }
        }

        // Coordinate Detection
        for (var i = 0; i < parts.length; i++) {
            var coords = parts[i].split(',');
            if (coords.length === 4) {
                var isPx = false;
                var val = [];
                for(var k=0; k<4; k++) {
                    var s = coords[k].trim();
                    if (s.indexOf('px') !== -1) isPx = true;
                    var v = parseInt(s);
                    if (v > 100) isPx = true;
                    val.push(v);
                }
                layout.tiles.push({ type: isPx ? 'px' : '%', x: val[0], y: val[1], w: val[2], h: val[3] });
            }
        }
        return layout;
    }

    // --- 5. POPUP UI ---
    function showPopup() {
        if (!activeClient) return;

        var cursor = Workspace.cursorPos;
        var screen = Workspace.activeScreen;
        var area = Workspace.clientArea(KWin.FullScreenArea, screen, Workspace.currentDesktop);
        var centerX = area.x + (area.width / 2);
        var margin = 50;

        popup.opacity = 0;
        popup.scale = 0.95;

        if (cursor.x < centerX) {
            popup.x = (area.x + area.width) - popup.width - margin;
        } else {
            popup.x = area.x + margin;
        }

        popup.y = area.y + (area.height / 2) - (popup.height / 2);
        popup.visible = true;
        popupAnim.restart();
    }

    PlasmaCore.Dialog {
        id: popup
        visible: false
        flags: Qt.Popup | Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
        location: PlasmaCore.Types.Desktop
        backgroundHints: PlasmaCore.Types.NoBackground

        // Critical for visibility in some Plasma versions
        mainItem: background

        ParallelAnimation {
            id: popupAnim
            NumberAnimation { target: popup; property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutQuad }
            NumberAnimation { target: popup; property: "scale"; from: 0.95; to: 1; duration: 150; easing.type: Easing.OutBack }
        }

        Rectangle {
            id: background
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
                    model: parsedLayouts
                    Rectangle {
                        width: 160
                        height: 90
                        color: "transparent"
                        border.color: Kirigami.Theme.textColor
                        border.width: 1
                        opacity: 0.5
                        radius: 4

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onEntered: parent.opacity = 1.0
                            onExited: parent.opacity = 0.5
                        }

                        Repeater {
                            model: modelData.tiles
                            Rectangle {
                                property var tile: modelData
                                property bool isPx: tile.type === "px"

                                x: isPx ? (tile.x / 1920.0 * parent.width) : (tile.x / 100.0 * parent.width)
                                y: isPx ? (tile.y / 1080.0 * parent.height) : (tile.y / 100.0 * parent.height)
                                width: isPx ? (tile.w / 1920.0 * parent.width) : (tile.w / 100.0 * parent.width)
                                height: isPx ? (tile.h / 1080.0 * parent.height) : (tile.h / 100.0 * parent.height)

                                color: Kirigami.Theme.highlightColor
                                opacity: 0.3
                                border.color: Kirigami.Theme.textColor
                                border.width: 1
                                radius: 2

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: parent.opacity = 0.9
                                    onExited: parent.opacity = 0.3
                                    onClicked: {
                                        var layoutIdx = findLayoutIndex(modelData);
                                        var tileIdx = -1;
                                        if (layoutIdx !== -1) tileIdx = parsedLayouts[layoutIdx].tiles.indexOf(modelData);
                                        if (layoutIdx !== -1 && tileIdx !== -1) applyLayout(layoutIdx, tileIdx);
                                    }
                                }
                            }
                        }

                        function findLayoutIndex(tileObj) {
                            for(var i=0; i<parsedLayouts.length; i++) {
                                if (parsedLayouts[i].tiles.indexOf(tileObj) !== -1) return i;
                            }
                            return -1;
                        }
                    }
                }
            }
        }
    }
}
