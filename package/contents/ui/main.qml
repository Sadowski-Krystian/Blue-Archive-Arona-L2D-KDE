import QtQuick 2.15
import org.kde.plasma.plasmoid
import BlueArchiveSpine 1.0

WallpaperItem {
    id: root
    
    property bool alerted: false

    function getLocalPath(url) {
        return url.toString().replace("file://", "");
    }

    property int currentHour: new Date().getHours()
    property bool isDay: currentHour >= 6 && currentHour < 18

    // =========================================================
    // Layer 1: Animated Spine Background (Handles Sleeping Arona)
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
            // Track 0: Room environment
            setTrackAnimation(0, "Idle_background_00", true)
            // Track 1: Sleeping Arona
            setTrackAnimation(1, "Idle_00", true) 
        }
    }

    // =========================================================
    // Layer 2: Interactive Arona (Hidden while sleeping)
    // =========================================================
    SpineItem {
        id: spineCharacter
        anchors.fill: parent
        opacity: root.alerted ? 1.0 : 0.0 // Hide when sleeping
        
        // Disable processing when invisible for performance
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
            if (!root.alerted) {
                // 1. Play the wake-up transition on the background layer
                spineBackground.setTrackAnimation(2, "Idle_00_Touch_M", false)
                spineBackground.setTrackAnimation(3, "Idle_00_Touch_A", false)
                
                // 2. Wait for her to wake up, then switch models
                wakeTimer.start()
            }
        }
    }

    Timer {
        id: wakeTimer
        // Adjust this based on how long her wake animation takes (in ms)
        interval: 2000 
        onTriggered: {
            // Clear the background Arona
            spineBackground.clearTrack(1)
            spineBackground.clearTrack(2)
            spineBackground.clearTrack(3)
            
            // Show the main interactive Arona
            root.alerted = true
            spineCharacter.setTrackAnimation(0, "Idle_01", true)
        }
    }
}