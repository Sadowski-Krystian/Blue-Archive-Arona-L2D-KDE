import QtQuick
import QtQuick.Controls
import QtMultimedia
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

    // --- Audio System ---
    property bool audioEnabled: typeof root.configuration !== 'undefined' ? root.configuration.audioEnabled : true
    property real audioVolume: typeof root.configuration !== 'undefined' ? root.configuration.audioVolume / 100.0 : 0.5

    MediaPlayer {
        id: voicePlayer
        audioOutput: AudioOutput {
            volume: root.audioVolume
            muted: !root.audioEnabled
        }
    }

    QtObject {
        id: voiceData
        property var aronaInteractText: ["Manage tasks you need to complete from here!", "Sensei! Pick a task. I'll back you up!", "Here's everything on your docket. Adults have it rough, huh?"]
        property var aronaInteractFile: ["Arona/arona_work_talk_1", "Arona/arona_work_talk_2", "Arona/arona_work_talk_3"]
        property var aronaInteractExpr: ["00", "25", "13"]

        property var planaInteractText: ["You can carry out your various tasks here, Sensei.", "Sensei. Please select whatever task you wish to do.", "There are many tasks that need to be resolved. Now then, if you please."]
        property var planaInteractFile: ["NP0035/NP0035_Work_Talk_1", "NP0035/NP0035_Work_Talk_2", "NP0035/NP0035_Work_Talk_3"]
        property var planaInteractExpr: ["03", "03", "03"]
        
        property var aronaWakeText: ["Sensei! I've been waiting for you!", "Let's get to work!", "Any task you want to do in particular, sensei?"]
        property var aronaWakeFile: ["Arona/arona_work_In_1", "Arona/arona_work_In_2", "Arona/arona_work_In_3"]
        property var aronaWakeExpr: ["12", "25", "31"]

        property var planaWakeText: ["Sensei, I've been waiting for you.", "It's time to get to work.", "Which task would you like to start with, Sensei?"]
        property var planaWakeFile: ["NP0035/NP0035_Work_In_1_2", "NP0035/NP0035_Work_In_2", "NP0035/NP0035_Work_In_3"]
        property var planaWakeExpr: ["03", "03", "00"]
    }

    function playVoice(file, text, expression) {
        if (root.audioEnabled) {
            voicePlayer.source = "file://" + root.getLocalPath(Qt.resolvedUrl("../voice/" + file + ".mp3"))
            voicePlayer.play()
        }
        dialogText.text = text
        dialogBox.opacity = 1
        spineCharacter.setTrackAnimation(1, expression, true)
        voiceTimer.restart()
    }

    // --- Bone Tracking States ---
    property int mouseAction: -1 
    property point eyeBase: Qt.point(0, 0)
    property point patBase: Qt.point(0, 0)
    property point currentEye: Qt.point(0, 0)
    property point currentPat: Qt.point(0, 0)
    property real curMouseX: 0
    property real curMouseY: 0
    property real lastMouseX: 0
    property real lastMouseY: 0

    // --- Render Layers ---
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
        Behavior on opacity { NumberAnimation { duration: 500 } }
        
        Rectangle {
            z: -1 
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
            root.lastMouseX = mouse.x; root.lastMouseY = mouse.y;
            root.curMouseX = mouse.x;  root.curMouseY = mouse.y;

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
                    if (root.isArona) spineCharacter.setTrackAnimation(2, "Pat_01_A", false)
                } 
                else if (relX > 0.15 && relX < 0.35 && relY >= 0.40 && relY < 0.80) {
                    root.mouseAction = 2 
                    var idx = Math.floor(Math.random() * 3)
                    if (root.isArona) {
                        playVoice(voiceData.aronaInteractFile[idx], voiceData.aronaInteractText[idx], voiceData.aronaInteractExpr[idx])
                    } else {
                        playVoice(voiceData.planaInteractFile[idx], voiceData.planaInteractText[idx], voiceData.planaInteractExpr[idx])
                    }
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
            
            var idx = Math.floor(Math.random() * 3)
            if (root.isArona) {
                playVoice(voiceData.aronaWakeFile[idx], voiceData.aronaWakeText[idx], voiceData.aronaWakeExpr[idx])
            } else {
                playVoice(voiceData.planaWakeFile[idx], voiceData.planaWakeText[idx], voiceData.planaWakeExpr[idx])
            }
            
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