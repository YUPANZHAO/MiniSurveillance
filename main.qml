import QtQuick 2.15
import QtQuick.Window 2.15
import QtMultimedia 5.15
import QtQuick.Controls 2.15
import VideoCtrl 1.0
import QtQuick.Controls.Styles 1.4
import QtQml.Models 2.15
import CameraFilter 1.0
import VideoSender 1.0
import MainCtrl 1.0

Window {
    width: 1401
    height: 721
    visible: true
    title: qsTr("Mini Surveillance")

MainCtrl {
    id: mainctrl
    Component.onCompleted: {
        videoCtrl1.window_idx = mainctrl.addWindow(videoCtrl1)
        videoCtrl2.window_idx = mainctrl.addWindow(videoCtrl2)
        videoCtrl3.window_idx = mainctrl.addWindow(videoCtrl3)
        videoCtrl4.window_idx = mainctrl.addWindow(videoCtrl4)
    }
}

Menu {
    id: rclick_menu
    width: 100

    property int window_idx: -1

    MenuItem {
        id: menu_item_AudioCtrl
        text: "开启/关闭音频"
        onClicked: {
            if(mainctrl.getWindowIsPlayingAudio(rclick_menu.window_idx)) {
                mainctrl.stopAudio(rclick_menu.window_idx)
            }else {
                mainctrl.playAudio(rclick_menu.window_idx)
            }
        }
    }
    MenuItem {
        id: menu_item_closeVideo
        text: "关闭视频"
        onClicked: {
            mainctrl.stopVideo(mainctrl.getDeivceIdxByWindowIdx(rclick_menu.window_idx))
        }
    }
}

Rectangle {
    id: mainWindow
    width: parent.width
    height: parent.height

    // 设备列表单击事件
    function onListItemClicked(item) {
        mainctrl.playVideo(item.id)
    }

    // 设备列表
    ListView {
        id: list
        width: 120
        height: mainWindow.height - btn_add_device.height
        anchors.top: btn_add_device.bottom
        model: listModel
        delegate: listDelegate

        ListModel {
            id: listModel
            Component.onCompleted: {
            }
        }

        Component {
            id: listDelegate
            Column { Row { // 绘制列表的单个Item

            Button {
                width: list.width
                height: 50
                text: model.name
                onClicked: mainWindow.onListItemClicked(model)
            }

            } } // end of Column { Row {
        }
    }

    Button {
        id: btn_add_device
        width: list.width
        height: 50
        text: "添加设备"
        onClicked: {
            add_device_dlg.open()
        }
    }

    Popup {
        id: add_device_dlg
        width: 180
        height: 60
        x: 0
        y: btn_add_device.height

        onClosed: {
            input_key.text = ""
        }

        Rectangle {
            width: parent.width
            height: 30
            anchors.centerIn: parent
            border.color: "grey"

            Text {
                id: add_device_input_text_hint
                text: "请输入设备注册码"
                font.pixelSize: parent.height / 2
                color: "grey"
                anchors.centerIn: parent
            }

            TextInput {
                id: input_key
                anchors.fill: parent
                font.pixelSize: parent.height-4
                clip: true

                onAccepted: {
                    if(text.length == 0) return
                    let device_idx = mainctrl.addDevice(text)
                    if(device_idx !== -1) {
                        listModel.append({
                            "id": device_idx,
                            "name": mainctrl.getDeviceName(device_idx)
                        });
                    }
                    text = ""
                    add_device_dlg.close()
                }

                onTextChanged: {
                    if(text.length == 0) add_device_input_text_hint.visible = true
                    else add_device_input_text_hint.visible = false
                }
            }
        }
    }

    // 监控画面1
    Rectangle {
        id: surface1
        width: (parent.width - list.width) / 2
        height: parent.height / 2;
        anchors.left: list.right
        anchors.top: mainWindow.top
        color: "black"

        VideoOutput {
            id: videoOutput1
            anchors.fill: parent
            source: videoCtrl1.frameProvider
        }

        VideoCtrl {
            id: videoCtrl1
            property int window_idx: -1
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: {
                if(!mainctrl.getDeviceIsPlaying(
                    mainctrl.getDeivceIdxByWindowIdx(
                    videoCtrl1.window_idx))) return;
                rclick_menu.x = mouse.x + parent.x
                rclick_menu.y = mouse.y + parent.y
                if(mainctrl.getWindowIsPlayingAudio(videoCtrl1.window_idx))
                    menu_item_AudioCtrl.text = "关闭音频"
                else
                    menu_item_AudioCtrl.text = "开启音频"
                rclick_menu.window_idx = videoCtrl1.window_idx
                rclick_menu.open()
            }
        }
    }

    // 监控画面2
    Rectangle {
        id: surface2
        width: (parent.width - list.width) / 2
        height: parent.height / 2;
        anchors.left: surface1.right
        anchors.top: mainWindow.top
        anchors.leftMargin: 1
        color: "black"

        VideoOutput {
            id: videoOutput2
            anchors.fill: parent
            source: videoCtrl2.frameProvider
        }

        VideoCtrl {
            id: videoCtrl2
            property int window_idx: -1
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: {
                if(!mainctrl.getDeviceIsPlaying(
                    mainctrl.getDeivceIdxByWindowIdx(
                    videoCtrl2.window_idx))) return;
                rclick_menu.x = mouse.x + parent.x
                rclick_menu.y = mouse.y + parent.y
                if(mainctrl.getWindowIsPlayingAudio(videoCtrl2.window_idx))
                    menu_item_AudioCtrl.text = "关闭音频"
                else
                    menu_item_AudioCtrl.text = "开启音频"
                rclick_menu.window_idx = videoCtrl2.window_idx
                rclick_menu.open()
            }
        }
    }

    // 监控画面3
    Rectangle {
        id: surface3
        width: (parent.width - list.width) / 2
        height: parent.height / 2;
        anchors.left: list.right
        anchors.top: surface1.bottom
        anchors.topMargin: 1
        color: "black"

        VideoOutput {
            id: videoOutput3
            anchors.fill: parent
            source: videoCtrl3.frameProvider
        }

        VideoCtrl {
            id: videoCtrl3
            property int window_idx: -1
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: {
                if(!mainctrl.getDeviceIsPlaying(
                    mainctrl.getDeivceIdxByWindowIdx(
                    videoCtrl3.window_idx))) return;
                rclick_menu.x = mouse.x + parent.x
                rclick_menu.y = mouse.y + parent.y
                if(mainctrl.getWindowIsPlayingAudio(videoCtrl3.window_idx))
                    menu_item_AudioCtrl.text = "关闭音频"
                else
                    menu_item_AudioCtrl.text = "开启音频"
                rclick_menu.window_idx = videoCtrl3.window_idx
                rclick_menu.open()
            }
        }
    }

    // 监控画面4
    Rectangle {
        id: surface4
        width: (parent.width - list.width) / 2
        height: parent.height / 2;
        anchors.left: surface3.right
        anchors.top: surface2.bottom
        anchors.leftMargin: 1
        anchors.topMargin: 1
        color: "black"

        VideoOutput {
            id: videoOutput4
            anchors.fill: parent
            source: videoCtrl4.frameProvider
        }

        VideoCtrl {
            id: videoCtrl4
            property int window_idx: -1
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: {
                if(!mainctrl.getDeviceIsPlaying(
                    mainctrl.getDeivceIdxByWindowIdx(
                    videoCtrl4.window_idx))) return;
                rclick_menu.x = mouse.x + parent.x
                rclick_menu.y = mouse.y + parent.y
                if(mainctrl.getWindowIsPlayingAudio(videoCtrl4.window_idx))
                    menu_item_AudioCtrl.text = "关闭音频"
                else
                    menu_item_AudioCtrl.text = "开启音频"
                rclick_menu.window_idx = videoCtrl4.window_idx
                rclick_menu.open()
            }
        }
    }

}

}
