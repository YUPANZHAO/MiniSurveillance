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
import RecordCtrl 1.0

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
    MenuItem {
        id: menu_item_AudioTalk
        text: "开启/关闭语音对讲"
        onClicked: {
            if(camera.cameraState == Camera.ActiveState) {
                mainctrl.stopTalk(rclick_menu.window_idx)
                sender.stop()
                camera.stop()
                updateTalkWindowPos(rclick_menu.window_idx);
                talk_videoOutput.visible = false
            }else {
                let ret = mainctrl.startTalk(rclick_menu.window_idx)
                if(ret === false) {
                    console.log("开启对讲失败")
                    return
                }
                let rtmp_push_url = mainctrl.getTalkRtmpUrl();
                sender.setRtmpUrl(rtmp_push_url)
                sender.push();
                sender.openAudio()
                camera.start()
                updateTalkWindowPos(rclick_menu.window_idx);
                talk_videoOutput.visible = true
            }
        }
    }
}

function updateTalkWindowPos(window_idx) {
    if(window_idx === 0) {
        talk_videoOutput.x = surface1.x + surface1.width - talk_videoOutput.width - 10
        talk_videoOutput.y = surface1.y + 10
    }else if(window_idx === 1) {
        talk_videoOutput.x = surface2.x + surface2.width - talk_videoOutput.width - 10
        talk_videoOutput.y = surface2.y + 10
    }else if(window_idx === 2) {
        talk_videoOutput.x = surface3.x + surface3.width - talk_videoOutput.width - 10
        talk_videoOutput.y = surface3.y + 10
    }else {
        talk_videoOutput.x = surface4.x + surface4.width - talk_videoOutput.width - 10
        talk_videoOutput.y = surface4.y + 10
    }
}

Camera {
    id: camera
    Component.onCompleted: {
        camera.stop()
    }
}

CameraFilter {
    id: cameraFilter
    qmlCamera: camera
}

VideoSender {
    id: sender
    cameraSource: cameraFilter
}

// 设备列表单击事件
function onListItemClicked(item) {
    if(btn_change_window.window_name == "surveillance") {
        mainctrl.playVideo(item.id)
    }else if(btn_change_window.window_name == "record") {
        if(input_begin_time.length == 0 || input_end_time.length == 0) return;
        let file = mainctrl.getRecordFile(item.id, input_begin_time.text, input_end_time.text)
        if(file === "") return;
        record_window.record_file_name = file
        btn_play.clicked()
    }
}

Rectangle {
    id: mainWindow
    width: parent.width
    height: parent.height

    // 设备列表
    ListView {
        id: list
        width: 120
        height: mainWindow.height - btn_add_device.height - btn_change_window.height
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
                onClicked: onListItemClicked(model)
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

    // 对讲画面
    VideoOutput {
        id: talk_videoOutput
        width: surface1.width * 0.3
        height: width * 9 / 16
        source: camera
        visible: false

        MouseArea {
            anchors.fill: parent
            drag.target: talk_videoOutput
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: mainWindow.width - talk_videoOutput.width
            drag.maximumY: mainWindow.height - talk_videoOutput.height
        }
    }
}

Button {
    id: btn_change_window
    width: list.width
    height: 50
    text: "录像窗口"
    x: 0
    y: parent.height - height
    property string window_name: "surveillance"
    onClicked: {
        if(window_name == "surveillance") {
            window_name = "record"
            text = "监控窗口"
            record_window.visible = true
        }else if(window_name == "record") {
            window_name = "surveillance"
            text = "录像窗口"
            btn_stop.clicked()
            record_window.visible = false
        }
    }
}

RecordCtrl {
    id: record_ctrl
}

// 录像回放窗口
Rectangle {
    id: record_window
    width: parent.width - list.width
    height: parent.height
    visible: false
    x: list.width
    y: 0
    color: "white"

    property string record_file_name: ""

    Rectangle {
        id: record_surface
        width: parent.width
        height: parent.height - record_btn_group.height
        color: "black"
        VideoOutput {
            id: record_video_output
            source: record_ctrl.frameProvider
            anchors.fill: parent
        }
    }

    Rectangle {
        id: input_record_time_dlg
        width: 700
        height: 60
        anchors.centerIn: record_surface
        color: "white"

        Text {
            id: record_begin_time_text_hint
            text: "开始时间"
            font.pixelSize: input_begin_time.height / 2
            color: "grey"
            anchors.centerIn: input_begin_time
        }

        TextInput {
            id: input_begin_time
            width: parent.width / 2 - 10
            height: parent.height
            font.pixelSize: parent.height / 2
            clip: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            onTextChanged: {
                if(text.length == 0) record_begin_time_text_hint.visible = true
                else record_begin_time_text_hint.visible = false
            }
        }

        Text {
            id: record_end_time_text_hint
            text: "结束时间"
            font.pixelSize: input_end_time.height / 2
            color: "grey"
            anchors.centerIn: input_end_time
        }

        TextInput {
            id: input_end_time
            width: parent.width / 2 - 10
            height: parent.height
            anchors.left: input_begin_time.right
            anchors.leftMargin: 20
            font.pixelSize: parent.height / 2
            clip: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            onTextChanged: {
                if(text.length == 0) record_end_time_text_hint.visible = true
                else record_end_time_text_hint.visible = false
            }
        }
    }

    Rectangle {
        id: record_btn_group
        width: parent.width
        height: 60
        anchors.top: record_surface.bottom

        Button {
            id: btn_play
            text: "播放"
            height: 40
            anchors.top: parent.top
            anchors.topMargin: (record_btn_group.height - btn_play.height) / 2
            anchors.left: parent.left
            anchors.leftMargin: (parent.width - btn_play.width - btn_stop.width - btn_pause.width - btn_step_sec_backward.width - btn_step_sec_forward.width - btn_step_backward_one_frame.width - btn_step_forward_one_frame.width - 120) / 2
            onClicked: {
                if(record_window.record_file_name === "") return;
                record_ctrl.play(record_window.record_file_name)
                input_record_time_dlg.visible = false
            }
        }

        Button {
            id: btn_stop
            text: "关闭"
            anchors.top: parent.top
            anchors.topMargin: (record_btn_group.height - btn_play.height) / 2
            anchors.left: btn_play.right
            anchors.leftMargin: 20
            height: btn_play.height
            onClicked: {
                record_ctrl.stop()
                input_record_time_dlg.visible = true
            }
        }

        Button {
            id: btn_pause
            text: "暂停/继续"
            anchors.top: parent.top
            anchors.topMargin: (record_btn_group.height - btn_play.height) / 2
            anchors.left: btn_stop.right
            anchors.leftMargin: 20
            height: btn_play.height
            onClicked: {
                record_ctrl.pause()
            }
        }

        Button {
            id: btn_step_sec_backward
            text: "后退5秒"
            anchors.top: parent.top
            anchors.topMargin: (record_btn_group.height - btn_play.height) / 2
            anchors.left: btn_pause.right
            anchors.leftMargin: 20
            height: btn_play.height
            onClicked: {
                record_ctrl.step_by_second(-5)
            }
        }

        Button {
            id: btn_step_sec_forward
            text: "前进5秒"
            anchors.top: parent.top
            anchors.topMargin: (record_btn_group.height - btn_play.height) / 2
            anchors.left: btn_step_sec_backward.right
            anchors.leftMargin: 20
            height: btn_play.height
            onClicked: {
                record_ctrl.step_by_second(5)
            }
        }

        Button {
            id: btn_step_backward_one_frame
            text: "单帧后退"
            anchors.top: parent.top
            anchors.topMargin: (record_btn_group.height - btn_play.height) / 2
            anchors.left: btn_step_sec_forward.right
            anchors.leftMargin: 20
            height: btn_play.height
            onClicked: {
                record_ctrl.step_one_frame_backward()
            }
        }

        Button {
            id: btn_step_forward_one_frame
            text: "单帧前进"
            anchors.top: parent.top
            anchors.topMargin: (record_btn_group.height - btn_play.height) / 2
            anchors.left: btn_step_backward_one_frame.right
            anchors.leftMargin: 20
            height: btn_play.height
            onClicked: {
                record_ctrl.step_one_frame_forward()
            }
        }
    }
}

}
