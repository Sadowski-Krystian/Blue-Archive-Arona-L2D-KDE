import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import "BlueArchiveSpine"

WallpaperItem {
    id: root
    
    property bool alerted: false
    property int selectedMode: typeof root.configuration !== 'undefined' ? root.configuration.characterMode : 0
    property int currentHour: new Date().getHours()
    property bool isDaytime: currentHour >= 6 && currentHour < 18

    property bool isArona: {
        if (selectedMode === 1) return true;
        if (selectedMode === 2) return false;
        return isDaytime; 
    }

    property int startState: Math.floor(Math.random() * (isArona ? 3 : 4))

    function getLocalPath(url) { return url.toString().replace("file://", ""); }
    function getBgName() { return isArona ? "arona_workpage_daytime" : "arona_workpage_nighttime" }
    function getSprName() { return isArona ? "arona_spr" : "NP0035_spr" }
    
    function clamp(val, min, max) { return Math.max(min, Math.min(max, val)); }

    // --- Bone Tracking States ---
    property int mouseAction: -1 // 1: Pat, 2: Voice, 3: Look
    property point eyeBase: Qt.point(0, 0)
    property point patBase: Qt.point(0, 0)
    property point currentEye: Qt.point(0, 0)
    property point currentPat: Qt.point(0, 0)
    
    // Mouse deltas for tracking
    property real curMouseX: 0
    property real curMouseY: 0
    property real lastMouseX: 0
    property real lastMouseY: 0

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

    SpineItem {
        id: spineCharacter
        anchors.fill: parent
        opacity: root.alerted ? 1.0 : 0.0 
        visible: opacity > 0
        skelSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getSprName() + ".skel"))
        atlasSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getSprName() + ".atlas"))
        transform: Translate {
            x: -(root.width * 0.25)  
            y: -(root.height * 0.20) 
        }
    }

    // --- Dialogue UI ---
    FontLoader {
        id: notoSans
        source: "file://" + root.getLocalPath(Qt.resolvedUrl("../assets/font/NotoSans-Regular.ttf"))
    }

    Rectangle {
        id: dialogBox
        width: 300
        height: dialogText.contentHeight + 20 
        color: Qt.rgba(1, 1, 1, 0.87)
        border.color: Qt.rgba(1, 1, 1, 0.9)
        border.width: 1
        radius: 10
        
        x: (root.width * 0.35) 
        y: (root.height * 0.6)
        opacity: 0
        
        // This single animation now controls the box, the text, and the shadow perfectly
        Behavior on opacity { NumberAnimation { duration: 500 } }
        
        // CSS box-shadow nested as a child
        Rectangle {
            z: -1 // Forces it to render behind the white box
            width: parent.width
            height: parent.height
            x: 5
            y: 5
            color: Qt.rgba(0, 0, 0, 0.26)
            radius: 10
        }
        
        Text {
            id: dialogText
            anchors.fill: parent
            anchors.margins: 10 
            color: "black" 
            font.pixelSize: 24 
            font.family: notoSans.name 
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // --- Interaction Area ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onPressed: (mouse) => {
            root.lastMouseX = mouse.x;
            root.lastMouseY = mouse.y;
            root.curMouseX = mouse.x;
            root.curMouseY = mouse.y;

            if (!root.alerted && !wakeTimer.running) {
                spineBackground.setTrackAnimation(2, "Idle_0" + root.startState + "_Touch_M", false)
                spineBackground.setTrackAnimation(3, "Idle_0" + root.startState + "_Touch_A", false)
                wakeTimer.start()
                return;
            } 
            
            if (root.alerted) {
                sleepTimer.restart()
                
                var relX = mouse.x / root.width
                var relY = mouse.y / root.height
                
                if (relX > 0.15 && relX < 0.35 && relY > 0.20 && relY < 0.40) {
                    root.mouseAction = 1 
                    spineCharacter.setTrackAnimation(1, "Pat_01_M", false)
                    spineCharacter.setTrackAnimation(2, "Pat_01_A", false)
                } 
                else if (relX > 0.15 && relX < 0.35 && relY >= 0.40 && relY < 0.80) {
                    root.mouseAction = 2 
                    dialogText.text = root.isArona ? "Sensei! Pick a task. I'll back you up!" : "Sensei. Please select whatever task you wish to do."
                    dialogBox.opacity = 1
                    
                    spineCharacter.setTrackAnimation(1, root.isArona ? "25" : "03", true) 
                    voiceTimer.start()
                } 
                else {
                    root.mouseAction = 3 
                    spineCharacter.setTrackAnimation(1, "Look_01_M", false)
                    if (root.isArona) spineCharacter.setTrackAnimation(2, "Look_01_A", false)
                }
                boneEngine.start()
            }
        }

        onPositionChanged: (mouse) => {
            var deltaX = mouse.x - root.lastMouseX;
            var deltaY = mouse.y - root.lastMouseY;
            root.lastMouseX = mouse.x;
            root.lastMouseY = mouse.y;
            root.curMouseX = mouse.x;
            root.curMouseY = mouse.y;

            if (root.mouseAction === 1) {
                var HEADPAT_STEP = 5;
                var HEADPAT_CLAMP = 30;
                var midX = root.width * 0.25;
                var midY = root.height * 0.3;

                // Incremental bone movement mimicking JS delta physics
                if ((mouse.y < midY && deltaY < 0) || (mouse.x >= midX && deltaX > 0)) {
                    root.currentPat.y = root.clamp(root.currentPat.y - HEADPAT_STEP, root.patBase.y - HEADPAT_CLAMP, root.patBase.y + HEADPAT_CLAMP);
                } else if ((mouse.y >= midY && deltaY > 0) || (mouse.x < midX && deltaX < 0)) {
                    root.currentPat.y = root.clamp(root.currentPat.y + HEADPAT_STEP, root.patBase.y - HEADPAT_CLAMP, root.patBase.y + HEADPAT_CLAMP);
                }
            }
        }

        onReleased: {
            if (root.mouseAction === 1) {
                spineCharacter.setTrackAnimation(1, "PatEnd_01_M", false)
                if (root.isArona) spineCharacter.setTrackAnimation(2, "PatEnd_01_A", false)
            }
            else if (root.mouseAction === 3) {
                spineCharacter.setTrackAnimation(1, "LookEnd_01_M", false)
                if (root.isArona) spineCharacter.setTrackAnimation(2, "LookEnd_01_A", false)
            }
            root.mouseAction = -1
        }
    }

    // --- Timers ---
    Timer {
        id: wakeTimer
        interval: 2000 
        onTriggered: {
            spineBackground.clearTrack(1)
            spineBackground.clearTrack(2)
            spineBackground.clearTrack(3)
            
            root.alerted = true
            spineCharacter.setTrackAnimation(0, "Idle_01", true)
            
            root.eyeBase = spineCharacter.getBonePosition("Touch_Eye")
            root.patBase = spineCharacter.getBonePosition("Touch_Point")
            root.currentEye = root.eyeBase
            root.currentPat = root.patBase
            
            sleepTimer.start()
        }
    }

    Timer {
        id: voiceTimer
        interval: 4000 
        onTriggered: {
            dialogBox.opacity = 0
            spineCharacter.setTrackAnimation(1, "00", true) 
        }
    }

    Timer {
        id: sleepTimer
        interval: 300000 
        onTriggered: {
            root.alerted = false
            root.startState = Math.floor(Math.random() * (root.isArona ? 3 : 4))
            spineBackground.setTrackAnimation(0, "Idle_background_00", true)
            spineBackground.setTrackAnimation(1, "Idle_0" + root.startState, true)
            
            spineCharacter.clearTrack(0)
            spineCharacter.clearTrack(1)
            spineCharacter.clearTrack(2)
            boneEngine.stop()
        }
    }

    // --- JS Replicated 60FPS Bone Engine ---
    Timer {
        id: boneEngine
        interval: 20
        repeat: true
        onTriggered: {
            if (root.mouseAction === 3) {
                var adjX = (root.curMouseX / root.width) - 0.25;
                var adjY = (root.curMouseY / root.height) - 0.5;
                
                var EYE_CLAMP_X = 200;
                var EYE_CLAMP_Y = 112.5; 
                var EYE_STEP = 10;

                var signX = adjX > 0 ? 1 : (adjX < 0 ? -1 : 0);
                var signY = adjY > 0 ? 1 : (adjY < 0 ? -1 : 0);
                
                root.currentEye.y -= signX * EYE_STEP;
                root.currentEye.x -= signY * EYE_STEP;

                // Strict hard cap limits to absolutely prevent multi-monitor tearing
                var limitY = Math.min(Math.abs(adjX) * EYE_CLAMP_X, EYE_CLAMP_X);
                var limitX = Math.min(Math.abs(adjY) * EYE_CLAMP_Y, EYE_CLAMP_Y);

                root.currentEye.y = root.clamp(root.currentEye.y, root.eyeBase.y - limitY, root.eyeBase.y + limitY);
                root.currentEye.x = root.clamp(root.currentEye.x, root.eyeBase.x - limitX, root.eyeBase.x + limitX);
            }
            else if (root.mouseAction === -1) {
                root.currentEye.x += (root.eyeBase.x - root.currentEye.x) * 0.15;
                root.currentEye.y += (root.eyeBase.y - root.currentEye.y) * 0.15;
                root.currentPat.y += (root.patBase.y - root.currentPat.y) * 0.15;

                if (Math.abs(root.currentEye.x - root.eyeBase.x) < 1 &&
                    Math.abs(root.currentEye.y - root.eyeBase.y) < 1 &&
                    Math.abs(root.currentPat.y - root.patBase.y) < 1) {
                    
                    spineCharacter.clearBonePosition("Touch_Eye");
                    spineCharacter.clearBonePosition("Touch_Point");
                    boneEngine.stop();
                    return;
                }
            }

            if (root.mouseAction !== -1 || boneEngine.running) {
                spineCharacter.setBonePosition("Touch_Eye", root.currentEye.x, root.currentEye.y);
                spineCharacter.setBonePosition("Touch_Point", root.patBase.x, root.currentPat.y);
            }
        }
    }
}