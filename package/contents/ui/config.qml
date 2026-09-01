import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
    property alias cfg_characterMode: characterComboBox.currentIndex
    property alias cfg_audioEnabled: audioToggle.checked
    property alias cfg_audioVolume: volumeSlider.value

    ComboBox {
        id: characterComboBox
        Kirigami.FormData.label: "Character Mode:"
        model: ["Auto (Time of Day)", "Always Arona (Day)", "Always Plana (Night)"]
    }

    CheckBox {
        id: audioToggle
        Kirigami.FormData.label: "Enable Voice:"
        text: "Play interactions and wake-up audio"
    }

    Slider {
        id: volumeSlider
        Kirigami.FormData.label: "Voice Volume:"
        from: 0
        to: 100
        stepSize: 1
    }
}