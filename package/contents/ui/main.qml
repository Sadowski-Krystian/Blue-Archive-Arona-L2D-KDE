import QtQuick 2.15
import BlueArchiveSpine 1.0

Item {
    width: 1920
    height: 1080

    SpineItem {
        anchors.fill: parent
        // Note: Paths are relative to the project root where you run qmlscene
        skelSource: "package/contents/assets/arona_spr.skel"
        atlasSource: "package/contents/assets/arona_spr.atlas"
        
        animation: "Idle_01" 
    }
}