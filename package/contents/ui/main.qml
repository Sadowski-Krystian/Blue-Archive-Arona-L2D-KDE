import QtQuick 2.15
import org.kde.plasma.plasmoid
import "BlueArchiveSpine"

WallpaperItem {
    id: root
    
    property bool alerted: false

    // 0 = Auto (Time of Day), 1 = Always Arona (Day), 2 = Always Plana (Night)
    property int selectedMode: typeof root.configuration !== 'undefined' ? root.configuration.characterMode : 0

    property int currentHour: new Date().getHours()
    property bool isDaytime: currentHour >= 6 && currentHour < 18

    // Resolve whether Arona or Plana should be loaded
    property bool isArona: {
        if (selectedMode === 1) return true;
        if (selectedMode === 2) return false;
        return isDaytime; // Mode 0: Auto
    }

    function getLocalPath(url) {
        return url.toString().replace("file://", "");
    }
    
    // Arona has 3 sleep states (0, 1, 2). Plana has 4 sleep states (0, 1, 2, 3)
    property int startState: Math.floor(Math.random() * (isArona ? 3 : 4))

    function getBgName() {
        return isArona ? "arona_workpage_daytime" : "arona_workpage_nighttime"
    }

    function getSprName() {
        return isArona ? "arona_spr" : "NP0035_spr"
    }

    // =========================================================
    // Layer 1: Animated Spine Background
    // =========================================================
    SpineItem {
        id: spineBackground
        anchors.fill: parent

        skelSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getBgName() + ".skel"))
        atlasSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getBgName() + ".atlas"))

        Component.onCompleted: {
            setTrackAnimation(0, "Idle_background_00", true)
            setTrackAnimation(1, "Idle_0" + root.startState, true) 
        }
    }

    // =========================================================
    // Layer 2: Interactive Character
    // =========================================================
    SpineItem {
        id: spineCharacter
        anchors.fill: parent
        
        opacity: root.alerted ? 1.0 : 0.0 
        visible: opacity > 0

        skelSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getSprName() + ".skel"))
        atlasSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getSprName() + ".atlas"))
    }

    // =========================================================
    // Layer 3: Interaction Area
    // =========================================================
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!root.alerted && !wakeTimer.running) {
                spineBackground.setTrackAnimation(2, "Idle_0" + root.startState + "_Touch_M", false)
                spineBackground.setTrackAnimation(3, "Idle_0" + root.startState + "_Touch_A", false)
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