import QtQuick
import QtQuick.Controls
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager
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
    property string audioExt: ".ogg"

    function getLocalPath(url) { return url.toString().replace("file://", ""); }
    function getBgName() { return isArona ? "arona_workpage_daytime" : "arona_workpage_nighttime" }
    function getSprName() { return isArona ? "arona_spr" : "NP0035_spr" }
    function clamp(val, min, max) { return Math.max(min, Math.min(max, val)); }

    function getScreenX(baseX) {
        var scale = Math.max(root.width / 2880.0, root.height / 1620.0)
        return (root.width / 2.0) + (baseX - 1440.0) * scale
    }

    function getScreenY(baseY) {
        var scale = Math.max(root.width / 2880.0, root.height / 1620.0)
        return (root.height / 2.0) + (baseY - 810.0) * scale
    }

    property bool pauseOnFullscreen: typeof root.configuration !== 'undefined' ? root.configuration.pauseOnFullscreen : true
    property bool isWindowFullscreen: false
    property bool pendingSleepIn: false

    onIsWindowFullscreenChanged: {
        if (!isWindowFullscreen && pendingSleepIn) {
            pendingSleepIn = false
            playSleepIn()
        }
    }

    TaskManager.TasksModel {
        id: tasksModel
    }

    Instantiator {
        id: tasksInstantiator
        model: root.pauseOnFullscreen ? tasksModel : null
        delegate: QtObject {
            property bool isMaxOrFull: (model.IsFullScreen === true || model.isFullScreen === true || 
                                        model.IsMaximized === true || model.isMaximized === true)
            property bool isMin: (model.IsMinimized === true || model.isMinimized === true)
            
            property bool isCovering: isMaxOrFull && !isMin
        }
    }

    Timer {
        id: windowCheckTimer
        interval: 1000 
        repeat: true
        running: root.pauseOnFullscreen
        onTriggered: {
            var found = false;
            for (var i = 0; i < tasksInstantiator.count; i++) {
                var obj = tasksInstantiator.objectAt(i);
                if (obj && obj.isCovering) {
                    found = true;
                    break;
                }
            }
            
            if (root.isWindowFullscreen !== found) {
                root.isWindowFullscreen = found;
                if (found && voicePlayer.playbackState === MediaPlayer.PlayingState) {
                    voicePlayer.pause();
                } else if (!found && voicePlayer.playbackState === MediaPlayer.PausedState) {
                    voicePlayer.play();
                }
            }
        }
    }

    property bool audioEnabled: typeof root.configuration !== 'undefined' ? root.configuration.audioEnabled : true
    property real audioVolume: typeof root.configuration !== 'undefined' ? root.configuration.audioVolume / 100.0 : 0.5
    // Safely reads the custom seconds value and converts to milliseconds, defaulting to 60000 (60s)
    property int idleVoiceIntervalMs: typeof root.configuration !== 'undefined' && root.configuration.idleVoiceInterval !== undefined ? (root.configuration.idleVoiceInterval * 1000) : 60000

    Component.onCompleted: reloadTimer.start()
    onIsAronaChanged: reloadTimer.restart()

    MediaPlayer {
        id: voicePlayer
        audioOutput: AudioOutput {
            volume: root.audioVolume
            muted: !root.audioEnabled
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                dialogBox.opacity = 0
                if (root.alerted) spineCharacter.setTrackAnimation(1, "00", true)
            }
        }
    }

    property var voiceDatabase: {
        "arona": {
            "pos": [
                { x: 680, y: 860 },  
                { x: 1000, y: 350 }, 
                { x: 750, y: 500 }   
            ],
            "in": [
                { t: ["Zzz. Strawberry milk... Heeheehee.", "Eat all that? No, I couldn't..."], f: ["Arona/arona_work_sleep_in_1", "Arona/arona_work_sleep_in_2"] },
                { t: ["Another day means another clear sky.", "Hmm... Maybe it'll rain."], f: ["Arona/arona_work_watch_in_1", "Arona/arona_work_watch_in_2"] },
                { t: ["Mm-hmm...♬"], f: ["Arona/arona_work_sit_in_1"] }
            ],
            "idle": [
                { t: ["Sensei, you're so...", "...Heeheehee.", "Zzz..."], f: ["Arona/arona_work_sleep_talk_1", "Arona/arona_work_sleep_talk_2", "Arona/arona_work_sleep_talk_3"] },
                { t: ["I wonder what's out there...", "Hmm..."], f: ["Arona/arona_work_watch_talk_1", "Arona/arona_work_watch_talk_3"] },
                { t: ["La, lala, lala! ♪", "Hmm hmm hmm... ♩"], f: ["Arona/arona_work_sit_talk_1", "Arona/arona_work_sit_talk_2"] }
            ],
            "exit": [
                { t: ["Wh-wha...huh?", "Ah?!"], f: ["Arona/arona_work_sleep_exit_1", "Arona/arona_work_sleep_exit_2"] },
                { t: ["Ah!", "Huh?"], f: ["Arona/arona_work_watch_exit_1", "Arona/arona_work_watch_exit_2"] },
                { t: ["Eh?", "Huh?"], f: ["Arona/arona_work_sit_exit_1", "Arona/arona_work_sit_exit_2"] }
            ],
            "wake": {
                t: ["Sensei! I've been waiting for you!", "Let's get to work!", "Any task you want to do in particular, sensei?"],
                f: ["Arona/arona_work_in_1", "Arona/arona_work_in_2", "Arona/arona_work_in_3"],
                e: ["12", "25", "31"]
            },
            "interact": {
                t: ["Manage tasks you need to complete from here!", "Sensei! Pick a task. I'll back you up!", "Here's everything on your docket. Adults have it rough, huh?"],
                f: ["Arona/arona_work_talk_1", "Arona/arona_work_talk_2", "Arona/arona_work_talk_3"],
                e: ["00", "25", "13"]
            }
        },
        "plana": {
            "pos": [
                { x: 450, y: 300 },  
                { x: 1100, y: 550 }, 
                { x: 1200, y: 400 }, 
                { x: 900, y: 220 }   
            ],
            "in": [
                { t: ["So, that's what this is...", "...So that's how it is."], f: ["NP0035/np0035_work_cabinet_in_1", "NP0035/np0035_work_cabinet_in_2"] },
                { t: ["Mmm...", "Hmm..."], f: ["NP0035/np0035_work_sit_in_1", "NP0035/np0035_work_sit_in_2"] },
                { t: ["If it rains..."], f: ["NP0035/np0035_work_umbrella_in_1"] },
                { t: ["Do you mean that, senpai?"], f: ["NP0035/np0035_work_planawatchsky_in_1_2"] }
            ],
            "idle": [
                { t: ["Hmm... I see.", "Hmm... So that's how it's structured."], f: ["NP0035/np0035_work_cabinet_talk_1", "NP0035/np0035_work_cabinet_talk_1"] },
                { t: ["..."], f: ["NP0035/np0035_work_sit_talk_1"] },
                { t: ["Would this be useful?", "Me too. Together."], f: ["NP0035/np0035_work_umbrella_talk_1", "NP0035/np0035_work_umbrella_talk_2"] },
                { t: ["Mmm..."], f: ["NP0035/np0035_work_planawatchsky_talk_1_2"] }
            ],
            "exit": [
                { t: ["...Ah."], f: ["NP0035/np0035_work_cabinet_exit_1"] },
                { t: ["Ah."], f: ["NP0035/np0035_work_sit_exit_1"] },
                { t: ["Ah."], f: ["NP0035/np0035_work_umbrella_exit_1"] },
                { t: ["...Ah."], f: ["NP0035/np0035_work_planawatchsky_exit_1"] }
            ],
            "wake": {
                t: ["Sensei, I've been waiting for you.", "It's time to get to work.", "Which task would you like to start with, Sensei?"],
                f: ["NP0035/np0035_work_in_1_2", "NP0035/np0035_work_in_2", "NP0035/np0035_work_in_3"],
                e: ["03", "03", "00"]
            },
            "interact": {
                t: ["You can carry out your various tasks here, Sensei.", "Sensei. Please select whatever task you wish to do.", "There are many tasks that need to be resolved. Now then, if you please."],
                f: ["NP0035/np0035_work_talk_1", "NP0035/np0035_work_talk_2", "NP0035/np0035_work_talk_3"],
                e: ["03", "03", "03"]
            }
        }
    }

    function playSleepIn() {
        var charKey = root.isArona ? "arona" : "plana"
        var stateData = root.voiceDatabase[charKey].in[root.startState]
        var statePos = root.voiceDatabase[charKey].pos[root.startState]
        var idx = Math.floor(Math.random() * stateData.f.length)
        playVoice(stateData.f[idx], stateData.t[idx], "", statePos.x, statePos.y)
    }

    function playVoice(file, text, expression, posX, posY) {
        if (root.audioEnabled) {
            voicePlayer.source = Qt.resolvedUrl("../voice/" + file + root.audioExt)
            voicePlayer.play()
            voiceTimer.stop()
        } else {
            voiceTimer.restart()
        }

        if (posX !== undefined && posY !== undefined) {
            dialogBox.x = root.getScreenX(posX)
            dialogBox.y = root.getScreenY(posY)
        } else {
            dialogBox.x = root.getScreenX(1100)
            dialogBox.y = root.getScreenY(750)
        }

        dialogText.text = text
        dialogBox.opacity = 1
        if (expression !== "") spineCharacter.setTrackAnimation(1, expression, true)
    }

    property int mouseAction: -1 
    property point eyeBase: Qt.point(0, 0)
    property point patBase: Qt.point(0, 0)
    property point currentEye: Qt.point(0, 0)
    property point currentPat: Qt.point(0, 0)
    property real curMouseX: 0
    property real curMouseY: 0
    property real lastMouseX: 0
    property real lastMouseY: 0

    SpineItem {
        id: spineBackground
        anchors.fill: parent
        paused: root.isWindowFullscreen
        skelSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getBgName() + ".skel"))
        atlasSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getBgName() + ".atlas"))
    }

    SpineItem {
        id: spineCharacter
        anchors.fill: parent
        opacity: root.alerted ? 1.0 : 0.0 
        visible: opacity > 0
        paused: root.isWindowFullscreen
        skelSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getSprName() + ".skel"))
        atlasSource: root.getLocalPath(Qt.resolvedUrl("../assets/" + root.getSprName() + ".atlas"))
        transform: Translate {
            x: -(root.width * 0.25)  
            y: -(root.height * 0.20) 
        }
    }

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

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.isWindowFullscreen

        onPressed: (mouse) => {
            root.pendingSleepIn = false;
            
            if (voicePlayer.playbackState === MediaPlayer.PlayingState || voiceTimer.running) {
                return;
            }

            root.lastMouseX = mouse.x; root.lastMouseY = mouse.y;
            root.curMouseX = mouse.x;  root.curMouseY = mouse.y;

            if (!root.alerted && !wakeTimer.running) {
                var charKey = root.isArona ? "arona" : "plana"
                var stateData = root.voiceDatabase[charKey].exit[root.startState]
                var statePos = root.voiceDatabase[charKey].pos[root.startState]
                var idx = Math.floor(Math.random() * stateData.f.length)
                
                playVoice(stateData.f[idx], stateData.t[idx], "", statePos.x, statePos.y)

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
                    var charKey = root.isArona ? "arona" : "plana"
                    var actData = root.voiceDatabase[charKey].interact
                    var idx = Math.floor(Math.random() * actData.f.length)
                    playVoice(actData.f[idx], actData.t[idx], actData.e[idx])
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
                var midX = root.width * 0.25;
                var midY = root.height * 0.3;

                if ((mouse.y < midY && deltaY < 0) || (mouse.x >= midX && deltaX > 0)) {
                    root.currentPat.y = root.clamp(root.currentPat.y - 5, root.patBase.y - 30, root.patBase.y + 30);
                } else if ((mouse.y >= midY && deltaY > 0) || (mouse.x < midX && deltaX < 0)) {
                    root.currentPat.y = root.clamp(root.currentPat.y + 5, root.patBase.y - 30, root.patBase.y + 30);
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

    Timer {
        id: reloadTimer
        interval: 100 
        onTriggered: {
            root.alerted = false
            root.mouseAction = -1
            root.startState = Math.floor(Math.random() * (root.isArona ? 3 : 4))
            root.pendingSleepIn = false
            
            wakeTimer.stop()
            sleepTimer.stop()
            voiceTimer.stop()
            boneEngine.stop()
            if (voicePlayer.playbackState === MediaPlayer.PlayingState) {
                voicePlayer.stop()
            }
            dialogBox.opacity = 0
            
            spineCharacter.clearBonePosition("Touch_Eye")
            spineCharacter.clearBonePosition("Touch_Point")
            spineCharacter.clearTrack(0)
            spineCharacter.clearTrack(1)
            spineCharacter.clearTrack(2)
            
            spineBackground.clearTrack(1)
            spineBackground.clearTrack(2)
            spineBackground.clearTrack(3)
            spineBackground.setTrackAnimation(0, "Idle_background_00", true)
            spineBackground.setTrackAnimation(1, "Idle_0" + root.startState, true)
            
            if (root.isWindowFullscreen) {
                root.pendingSleepIn = true
            } else {
                playSleepIn()
            }
        }
    }

    Timer {
        id: idleVoiceTimer
        interval: root.idleVoiceIntervalMs
        repeat: true
        running: !root.alerted && !root.isWindowFullscreen
        onTriggered: {
            if (voicePlayer.playbackState === MediaPlayer.PlayingState) return;

            var charKey = root.isArona ? "arona" : "plana"
            var stateData = root.voiceDatabase[charKey].idle[root.startState]
            var statePos = root.voiceDatabase[charKey].pos[root.startState]
            var idx = Math.floor(Math.random() * stateData.f.length)
            playVoice(stateData.f[idx], stateData.t[idx], "", statePos.x, statePos.y)
        }
    }

    Timer {
        id: wakeTimer
        interval: 700 
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
            
            var charKey = root.isArona ? "arona" : "plana"
            var wakeData = root.voiceDatabase[charKey].wake
            var idx = Math.floor(Math.random() * wakeData.f.length)
            playVoice(wakeData.f[idx], wakeData.t[idx], wakeData.e[idx])
            
            sleepTimer.start()
        }
    }

    Timer {
        id: voiceTimer
        interval: 4000 
        onTriggered: {
            dialogBox.opacity = 0
            if (root.alerted) spineCharacter.setTrackAnimation(1, "00", true) 
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
            
            if (root.isWindowFullscreen) {
                root.pendingSleepIn = true
            } else {
                playSleepIn()
            }
        }
    }

    Timer {
        id: boneEngine
        interval: 20
        repeat: true
        running: !root.isWindowFullscreen
        onTriggered: {
            if (root.mouseAction === 3) {
                var adjX = (root.curMouseX / root.width) - 0.25;
                var adjY = (root.curMouseY / root.height) - 0.5;

                var signX = adjX > 0 ? 1 : (adjX < 0 ? -1 : 0);
                var signY = adjY > 0 ? 1 : (adjY < 0 ? -1 : 0);
                
                root.currentEye.y -= signX * 10;
                root.currentEye.x -= signY * 10;

                var limitY = Math.min(Math.abs(adjX) * 200, 200);
                var limitX = Math.min(Math.abs(adjY) * 112.5, 112.5);

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