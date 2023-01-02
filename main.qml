import QtQuick 2.15
import QtQuick.Window 2.15
import QtMultimedia 5.15
import QtQuick.Controls 1.4
import VideoCtrl 1.0
import QtQuick.Controls.Styles 1.4
import QtQml.Models 2.15

Window {
    width: 790
    height: 360
    visible: true
    title: qsTr("Mini Surveillance")

Rectangle {
    id: mainWindow
    width: parent.width
    height: parent.height

    // 设备列表单击事件
    function onListItemClicked(item) {
        if(surface.is_playing === false) {
            let ret = videoCtrl.play(item.rtmp_url)
            if(ret === true) {
                surface.is_playing = true
                surface.play_node_id = item.id
            }
        }else if(surface.play_node_id !== item.id) {
            videoCtrl.stop()
            surface.is_playing = false
            surface.play_node_id = -1
            let ret = videoCtrl.play(item.rtmp_url)
            if(ret === true) {
                surface.is_playing = true
                surface.play_node_id = item.id
            }
        }else {
            videoCtrl.stop()
            surface.is_playing = false
            surface.play_node_id = -1
        }
    }

    // 设备列表
    ListView {
        id: list
        width: mainWindow.width * 0.15
        height: mainWindow.height
        model: listModel
        delegate: listDelegate

        ListModel {
            id: listModel
            Component.onCompleted: {
                listModel.append({
                    "id":0,
                    "name":"WSL",
                    "rtmp_url":"rtmp://172.24.2.215:50051/hls/test"
                })
                listModel.append({
                    "id":1,
                    "name":"手机",
                    "rtmp_url":"rtmp://192.168.43.59:50051/hls/test"
                })
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

    // 监控画面
    Rectangle {
        id: surface
        width: mainWindow.width - list.width;
        height: surface.width * 9 / 16
        anchors.left: list.right
        anchors.top: mainWindow.top
        anchors.topMargin: (mainWindow.height - surface.height) / 2
        color: "black"

        property bool is_playing: false
        property int play_node_id: -1

        VideoOutput {
            id: videoOutput
            width: parent.width
            height: parent.height
            source: videoCtrl.frameProvider
        }

        VideoCtrl {
            id: videoCtrl
        }

    }

}

}
