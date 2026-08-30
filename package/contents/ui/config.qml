import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
    property alias cfg_characterMode: characterComboBox.currentIndex

    ComboBox {
        id: characterComboBox
        Kirigami.FormData.label: "Mode / Character:"
        model: ["Auto (Time of Day: Day = Arona, Night = Plana)", "Always Arona (Day)", "Always Plana (Night)"]
    }
}