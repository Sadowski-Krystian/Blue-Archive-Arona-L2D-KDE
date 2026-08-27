import QtQuick 2.15
import org.kde.plasma.plasmoid
import "BlueArchiveSpine"

WallpaperItem {
    id: root
    
    property bool alerted: false


    readonly property int maxTextureDim: 4096
    readonly property real ssFactor: {
        var factor = 2.0
        if (width * factor > maxTextureDim || height * factor > maxTextureDim) {
            factor = Math.min(maxTextureDim / width, maxTextureDim / height)
        }
        return Math.max(factor, 1.0)
    }

    function getLocalPath(url) {
        return url.toString().replace("file://", "");
    }

    property int currentHour: new Date().getHours()
    property bool isDay: currentHour >= 6 && currentHour < 18

    // =========================================================
    // Layer 1: Animated Spine Background
    // =========================================================
    SpineItem {
        id: spineBackground
        anchors.fill: parent

        skelSource: root.isDay
            ? root.getLocalPath(Qt.resolvedUrl("../assets/arona_workpage_daytime.skel"))
            : root.getLocalPath(Qt.resolvedUrl("../assets/arona_workpage_nighttime.skel"))

        atlasSource: root.isDay
            ? root.getLocalPath(Qt.resolvedUrl("../assets/arona_workpage_daytime.atlas"))
            : root.getLocalPath(Qt.resolvedUrl("../assets/arona_workpage_nighttime.atlas"))

        Component.onCompleted: {
            setTrackAnimation(0, "Idle_background_00", true)
            setTrackAnimation(1, "Idle_00", true) 
        }

        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(width * root.ssFactor, height * root.ssFactor)
    }

    // =========================================================
    // Layer 2: Interactive Arona
    // =========================================================
    SpineItem {
        id: spineCharacter
        anchors.fill: parent
        
        opacity: root.alerted ? 1.0 : 0.0 
        visible: opacity > 0

        skelSource: root.getLocalPath(Qt.resolvedUrl("../assets/arona_spr.skel"))
        atlasSource: root.getLocalPath(Qt.resolvedUrl("../assets/arona_spr.atlas"))

        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(width * root.ssFactor, height * root.ssFactor)
    }

    // =========================================================
    // Layer 3: Interaction Area
    // =========================================================
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!root.alerted) {
                spineBackground.setTrackAnimation(2, "Idle_00_Touch_M", false)
                spineBackground.setTrackAnimation(3, "Idle_00_Touch_A", false)
                wakeTimer.start()
            }
        }
    }

    Timer {
        id: wakeTimer
        interval: 2000 
        onTriggered: {
            spineBackground.clearTrack(1)
            spineBackground.clearTrack(2)
            spineBackground.clearTrack(3)
            
            root.alerted = true
            spineCharacter.setTrackAnimation(0, "Idle_01", true)
        }
    }
}
