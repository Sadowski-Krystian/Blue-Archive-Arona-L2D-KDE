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
    
    // Pick a random sleep state (0-2 for day, 0-3 for night) matching original JS
    property int startState: Math.floor(Math.random() * (isDay ? 3 : 4))

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
            // Play the randomly selected sleeping animation
            setTrackAnimation(1, "Idle_0" + root.startState, true) 
        }
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
    }

    // =========================================================
    // Layer 3: Interaction Area
    // =========================================================
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Block spam clicks if already alerted or if currently waking up
            if (!root.alerted && !wakeTimer.running) {
                // Play the matching Touch transition for whatever sleep state she was in
                spineBackground.setTrackAnimation(2, "Idle_0" + root.startState + "_Touch_M", false)
                spineBackground.setTrackAnimation(3, "Idle_0" + root.startState + "_Touch_A", false)
                
                // Start the countdown to swap the characters
                wakeTimer.start()
            }
        }
    }

    Timer {
        id: wakeTimer
        interval: 2000 
        onTriggered: {
            // Clear the sleep and wake transition tracks
            spineBackground.clearTrack(1)
            spineBackground.clearTrack(2)
            spineBackground.clearTrack(3)
            
            // Show the main character and play her standard idle
            root.alerted = true
            spineCharacter.setTrackAnimation(0, "Idle_01", true)
        }
    }
}