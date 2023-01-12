import QtQuick 2.15
import QtQuick.Window 2.15
import QtMultimedia 5.15
import QtQuick.Controls 1.4
import VideoCtrl 1.0
import QtQuick.Controls.Styles 1.4
import QtQml.Models 2.15
import CameraFilter 1.0
import VideoSender 1.0

Window {
    width: 1401
    height: 721
    visible: true
    title: qsTr("Mini Surveillance")

Rectangle {
    id: mainWindow
    width: parent.width
    height: parent.height

    // 设备列表单击事件
    function onListItemClicked(item) {
        if(surface1.is_playing) {
            videoCtrl1.stop()
            surface1.is_playing = false
        }else {
            videoCtrl1.playBykey(item.id)
            surface1.is_playing = true
        }
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
                text: model.id
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
            listModel.append({
                "id":"1A2U52",
                "rtmp_url":"rtmp://192.168.43.59:50051/live/1A2U52"
            })
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

        property bool is_playing: false
        property string play_node_id: ""

        VideoOutput {
            id: videoOutput1
            anchors.fill: parent
            source: videoCtrl1.frameProvider
        }

        VideoCtrl {
            id: videoCtrl1
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

        property bool is_playing: false
        property string play_node_id: ""

        VideoOutput {
            id: videoOutput2
            anchors.fill: parent
            source: videoCtrl2.frameProvider
        }

        VideoCtrl {
            id: videoCtrl2
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

        property bool is_playing: false
        property string play_node_id: ""

        VideoOutput {
            id: videoOutput3
            anchors.fill: parent
            source: videoCtrl3.frameProvider
        }

        VideoCtrl {
            id: videoCtrl3
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

        property bool is_playing: false
        property string play_node_id: ""

        VideoOutput {
            id: videoOutput4
            anchors.fill: parent
            source: videoCtrl4.frameProvider
        }

        VideoCtrl {
            id: videoCtrl4
        }
    }

}

}
