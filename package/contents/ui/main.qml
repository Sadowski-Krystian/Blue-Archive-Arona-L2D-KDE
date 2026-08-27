import QtQuick 2.15
import org.kde.plasma.plasmoid
import BlueArchiveSpine 1.0

WallpaperItem {
    id: root

    // Helper function to convert Qt file URLs to raw filesystem paths for C++
    function getLocalPath(url) {
        return url.toString().replace("file://", "");
    }

    // Determine Day/Night based on system time (6:00 - 18:00 is Day)
    property int currentHour: new Date().getHours()
    property bool isDay: currentHour >= 6 && currentHour < 18

    // Periodically update the time every minute
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            root.currentHour = new Date().getHours()
        }
    }

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

        animation: "Idle_background_00"
    }

    // =========================================================
    // Layer 2: Animated Spine Character (Arona / Plana)
    // =========================================================
    SpineItem {
        id: spineCharacter
        anchors.fill: parent

        skelSource: root.getLocalPath(Qt.resolvedUrl("../assets/arona_spr.skel"))
        atlasSource: root.getLocalPath(Qt.resolvedUrl("../assets/arona_spr.atlas"))

        animation: "Idle_01"
    }
}