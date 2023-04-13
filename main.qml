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
import QtGraphicalEffects 1.0

Window {
    id: root
    width: 1101
    height: 641
    minimumWidth: 1101
    minimumHeight: 641
    visible: true
    color: "#00000000"
    flags: Qt.Window | Qt.FramelessWindowHint
    title: qsTr("Mini Surveillance")

    // 主窗口
    Rectangle {
        id: mainWindow
        anchors.fill: parent
        anchors.margins: root.visibility === Window.FullScreen ? 0 : 15
        color: "#f4f4f6"

        // 标题栏
        Rectangle {
            id: title_bar
            width: parent.width
            height: 50
            color: "#429efd"

            property bool is_pressed: false

            MouseArea {
                id: title_bar_mouse_area
                anchors.fill: parent
                property int dx
                property int dy
                property int pre_mouse_x: 0
                property int pre_mouse_y: 0
                onPressed: {
                    dx = mouseX; dy = mouseY
                    if(!containsMouse) return
                    pre_mouse_x = mouse.x
                    pre_mouse_y = mouse.y
                    parent.is_pressed = true
                }
                onReleased: {
                    parent.is_pressed = false
                    if(root.y + mainWindow.y < 0) {
                        if(root.y + mainWindow.y + title_bar.y + mouse.y === 0) {
                            root.visibility = Window.FullScreen
                            return
                        }
                        root.y = -15
                    }
                }
                hoverEnabled: true
                onPositionChanged: {
                    if(!parent.is_pressed) return
                    if(root.visibility === Window.FullScreen && (mouse.y !== pre_mouse_y || mouse.x !== pre_mouse_x)) {
                        root.visibility = Window.AutomaticVisibility
                        root.x = mouse.x - root.width / 2
                        root.y = mouse.y - title_bar.height / 2
                        pre_mouse_x = mouse.x - root.x
                        pre_mouse_y = mouse.y - root.y
                        return
                    }
                    root.x = mousePosition.cursorPos().x - pre_mouse_x - 15
                    root.y = mousePosition.cursorPos().y - pre_mouse_y - 15
                }

                onDoubleClicked: root.visibility = root.visibility === Window.FullScreen ? Window.AutomaticVisibility : Window.FullScreen
            }

            // 图标
            Image {
                id: system_icon
                source: "qrc:/skins/default/icon.png"
                width: parent.height * 0.8
                height: width
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
            }

            // 标题
            Text {
                id: system_title
                text: qsTr("Mini Surveillance")
                font.family: "Cascadia Mono"
                font.pixelSize: parent.height * 0.4
                color: "white"
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: system_icon.right
                anchors.leftMargin: 10
            }

            // 系统设置
            Rectangle {
                id: btn_system_setting
                width: parent.height * 0.8
                height: width
                anchors.right: btn_system_min.left
                anchors.verticalCenter: parent.verticalCenter
                color: btn_system_setting_mouse_area.containsMouse ? "#1A000000" : parent.color
                radius: 8
                Image {
                    source: "qrc:/skins/default/setting.png"
                    width: parent.width * 0.6
                    height: width
                    anchors.centerIn: parent
                }

                property string pre_window_name: ""

                MouseArea {
                    id: btn_system_setting_mouse_area
                    anchors.fill: parent
                    onClicked: {
                        btn_system_setting.pre_window_name = windows_option.current_window_name
                        windows_option.current_window_name = system_setting_window.window_name;
                    }
                    hoverEnabled: true
                }
            }

            // 最小化
            Rectangle {
                id: btn_system_min
                width: parent.height * 0.8
                height: width
                anchors.right: btn_system_max.left
                anchors.verticalCenter: parent.verticalCenter
                color: btn_system_min_mouse_area.containsMouse ? "#1A000000" : parent.color
                radius: 8
                Image {
                    source: "qrc:/skins/default/Minimize.png"
                    width: parent.width * 0.5
                    height: width
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: btn_system_min_mouse_area
                    anchors.fill: parent
                    onClicked: {
                        root.visibility = Window.Minimized
                    }
                    hoverEnabled: true
                }
            }

            // 最大化
            Rectangle {
                id: btn_system_max
                width: parent.height * 0.8
                height: width
                anchors.right: btn_system_close.left
                anchors.verticalCenter: parent.verticalCenter
                color: btn_system_max_mouse_area.containsMouse ? "#1A000000" : parent.color
                radius: 8
                Image {
                    source: "qrc:/skins/default/" + (root.visibility === Window.FullScreen ? "Maximize_2.png" : "Maximize_1.png")
                    width: parent.width * 0.5
                    height: width
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: btn_system_max_mouse_area
                    anchors.fill: parent
                    onClicked: {
                        root.visibility = root.visibility === Window.FullScreen ? Window.AutomaticVisibility : Window.FullScreen
                    }
                    hoverEnabled: true
                }
            }

            // 关闭
            Rectangle {
                id: btn_system_close
                width: parent.height * 0.8
                height: width
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: btn_system_close_mouse_area.containsMouse ? "#4AFF0000" : parent.color
                radius: 8
                Image {
                    source: "qrc:/skins/default/Close.png"
                    width: parent.width * 0.5
                    height: width
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: btn_system_close_mouse_area
                    anchors.fill: parent
                    onClicked: {
                        close()
                    }
                    hoverEnabled: true
                }
            }
        }

        // 侧边栏
        Rectangle {
            id: side_bar
            width: 220
            height: parent.height - title_bar.height
            anchors.top: title_bar.bottom
            color: "#e9ebee"

            // 用户账号信息
            Rectangle {
                id: user_info_layout
                width: parent.width
                height: avatar.height + username.height + 15 + 20 + 20
                color: "#e9ebee"
                // 头像
                Image {
                    id: avatar
                    width: 90
                    height: width
                    visible: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    source: "/skins/default/avatar.png"
                }
                // 圆形遮罩
                Rectangle {
                    id: avatar_mask
                    width: avatar.width
                    height: avatar.height
                    radius: height
                    color: "red"
                    visible: false
                }
                // 遮罩设置
                OpacityMask {
                    anchors.fill: avatar
                    source: avatar
                    maskSource: avatar_mask
                }
                // 用户名
                Text {
                    id: username
                    text: "用户名"
                    font.family: "黑体"
                    font.pixelSize: 20
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: avatar.bottom
                    anchors.topMargin: 15
                }
            }

            // 窗口切换面板
            Rectangle {
                id: windows_option
                width: parent.width
                height: surveillance_window_option.height + record_window_option.height + add_device_window_option.height + 4 * 10
                anchors.top: user_info_layout.bottom
                property string current_window_name: "监控窗口"
                color: "#e9ebee"

                // 监控窗口
                Rectangle {
                    id: surveillance_window_option
                    width: parent.width - 30
                    height: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    radius: 5
                    color: windows_option.current_window_name == surveillance_window_option_text.text || surveillance_window_option_mouse_area.containsMouse ? "#0A000000" : "#00000000"

                    Text {
                        id: surveillance_window_option_text
                        text: "监控窗口"
                        font.family: "等线"
                        font.pixelSize: windows_option.current_window_name == text || surveillance_window_option_mouse_area.containsMouse ? 18 : 16
                        font.bold: windows_option.current_window_name == text || surveillance_window_option_mouse_area.containsMouse ? true : false
                        color: "#FA000000"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: surveillance_window_option_mouse_area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            windows_option.current_window_name = surveillance_window_option_text.text
                        }
                    }
                }

                // 录像回放
                Rectangle {
                    id: record_window_option
                    width: parent.width - 30
                    height: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: surveillance_window_option.bottom
                    anchors.topMargin: 10
                    radius: 5
                    color: windows_option.current_window_name == record_window_option_text.text || record_window_option_mouse_area.containsMouse ? "#0A000000" : "#00000000"

                    Text {
                        id: record_window_option_text
                        text: "录像回放"
                        font.family: "等线"
                        font.pixelSize: windows_option.current_window_name == text || record_window_option_mouse_area.containsMouse ? 18 : 16
                        font.bold: windows_option.current_window_name == text || record_window_option_mouse_area.containsMouse ? true : false
                        color: "#FA000000"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: record_window_option_mouse_area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            windows_option.current_window_name = record_window_option_text.text
                        }
                    }
                }

                // 添加设备
                Rectangle {
                    id: add_device_window_option
                    width: parent.width - 30
                    height: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: record_window_option.bottom
                    anchors.topMargin: 10
                    radius: 5
                    color: windows_option.current_window_name == add_device_window_option_text.text || add_device_window_option_mouse_area.containsMouse ? "#0A000000" : "#00000000"

                    Text {
                        id: add_device_window_option_text
                        text: "添加设备"
                        font.family: "等线"
                        font.pixelSize: windows_option.current_window_name == text || add_device_window_option_mouse_area.containsMouse ? 18 : 16
                        font.bold: windows_option.current_window_name == text || add_device_window_option_mouse_area.containsMouse ? true : false
                        color: "#FA000000"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: add_device_window_option_mouse_area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            windows_option.current_window_name = add_device_window_option_text.text
                        }
                    }
                }
            }

            // 标签 - "我的设备"
            Rectangle {
                id: label_my_device
                width: parent.width
                height: lable_my_device_text.height
                anchors.top: windows_option.bottom
                anchors.topMargin: 10
                color: "#e9ebee"

                Label {
                    id: lable_my_device_text
                    text: "我的设备: " + device_list_model.count + " 台"
                    font.family: "等线"
                    font.pixelSize: 14
                    color: "#AA000000"
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                }
            }

            // 设备列表
            ListView {
                id: device_list
                width: parent.width
                anchors.top: label_my_device.bottom
                anchors.topMargin: 5
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                model: device_list_model
                delegate: device_list_delegate
                clip: true

                ListModel {
                    id: device_list_model
                }

                Timer {
                    id: timer_handle_device_statu;
                    interval: 500;//设置定时器定时时间为500ms,默认1000ms
                    repeat: true //是否重复定时,默认为false
                    running: true //是否开启定时，默认是false，当为true的时候，进入此界面就开始定时
                    triggeredOnStart: true // 是否开启定时就触发onTriggered，一些特殊用户可以用来设置初始值。
                    onTriggered: {
                        //定时触发槽,定时完成一次就进入一次
                        var rowCount = device_list_model.count;
                        for(var i = 0;i < rowCount; i++) {
                            var model = device_list_model.get(i);
                            var is_active = mainctrl.getDeviceIsActive(i);
                            if(model.is_active && !is_active) {
                                mainctrl.stopVideo(model.idx);
                                mainWindow.info("设备 "+model.device_name+" 掉线!");
                            }else if(!model.is_active && is_active) {
                                mainWindow.info("设备 "+model.device_name+" 上线!")
                            }

                            model.is_active = is_active;
                            device_list_model.set(i, model);
                        }
                    }
                }

                Component {
                    id: device_list_delegate
                    Column { Row { // 绘制列表的单个Item

                    Rectangle {
                        width: device_list.width
                        height: 55
                        color: "#e9ebee"

                        Rectangle {
                            id: device_btn
                            width: parent.width - 30
                            height: parent.height - 10
                            anchors.centerIn: parent
                            radius: 10

                            Text {
                                text: model.device_name
                                font.pixelSize: 17
                                width: parent.width - 45
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideMiddle

                                MouseArea {
                                    id: device_btn_text_mouse_area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }

                            ToolTip {
                                id: device_btn_text_tip
                                text: model.device_name
                                visible: device_btn_text_mouse_area.containsMouse ? true : false
                                delay: Qt.styleHints.mousePressAndHoldInterval
                                x: device_btn_text_mouse_area.mouseX
                                y: device_btn_text_mouse_area.mouseY - height / 2 - 5
                            }

                            Rectangle {
                                id: active_light
                                width: 5
                                height: 5
                                radius: 2.5
                                color: model.is_active ? "green" : "red"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 15
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    mainWindow.onListItemClicked(model)
                                }
                                onPressed: {
                                    parent.color = "#0A000000"
                                }
                                onReleased: {
                                    parent.color = "white"
                                }
                            }
                        }

                        DropShadow {
                            anchors.fill: device_btn
                            horizontalOffset: 0
                            verticalOffset: 0
                            radius: 5
                            samples: 16
                            source: device_btn
                            color: "#4F000000"
                            Behavior on radius { PropertyAnimation { duration: 100 } }
                        }
                    }

                    } } // end of Column { Row {
                }
            }
        }

        // 全局焦点
        MouseArea {
            id: mainWindow_mouse_area
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: {
                forceActiveFocus()
                mouse.accepted = false
            }
            onPressed: {
                forceActiveFocus()
                mouse.accepted = false
            }
            onReleased: {
                forceActiveFocus()
                mouse.accepted = false
            }

            onWidthChanged: {
                if(talk_videoOutput.visible === true) {
                    if(talk_videoOutput.x + talk_videoOutput.width > mainWindow.width) {
                        talk_videoOutput.x = mainWindow.width - talk_videoOutput.width
                    }
                    if(talk_videoOutput.y + talk_videoOutput.height > mainWindow.height) {
                        talk_videoOutput.y = mainWindow.height - talk_videoOutput.height
                    }
                }
            }
            onHeightChanged: {
                if(talk_videoOutput.visible === true) {
                    if(talk_videoOutput.x + talk_videoOutput.width > mainWindow.width) {
                        talk_videoOutput.x = mainWindow.width - talk_videoOutput.width
                    }
                    if(talk_videoOutput.y + talk_videoOutput.height > mainWindow.height) {
                        talk_videoOutput.y = mainWindow.height - talk_videoOutput.height
                    }
                }
            }
        }

        // 间隔线
        Rectangle {
            id: spacer_1
            width: 1
            height: parent.height - title_bar.height
            anchors.top: title_bar.bottom
            anchors.left: side_bar.right
            color: "#10000000"
        }

        // 监控窗口
        Rectangle {
            id: surveillance_window
            height: parent.height - title_bar.height
            anchors.top: title_bar.bottom
            anchors.left: spacer_1.right
            anchors.right: parent.right
            property string window_name: "监控窗口"
            visible: windows_option.current_window_name == window_name ? true : false
            color: "#f4f4f6"

            // 监控画面1
            Rectangle {
                id: surface1
                width: (parent.width - 1) / 2
                height: (parent.height - 1) / 2
                anchors.left: parent.left
                anchors.top: parent.top
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
                        console.log(parent.x, parent.y)
                        rclick_menu.x = mouse.x + parent.x + surveillance_window.x
                        rclick_menu.y = mouse.y + parent.y + surveillance_window.y
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
                width: (parent.width - 1) / 2
                height: (parent.height - 1) / 2
                anchors.right: parent.right
                anchors.top: parent.top
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
                        rclick_menu.x = mouse.x + parent.x + surveillance_window.x
                        rclick_menu.y = mouse.y + parent.y + surveillance_window.y
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
                width: (parent.width - 1) / 2
                height: (parent.height - 1) / 2
                anchors.left: parent.left
                anchors.bottom: parent.bottom
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
                        rclick_menu.x = mouse.x + parent.x + surveillance_window.x
                        rclick_menu.y = mouse.y + parent.y + surveillance_window.y
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
                width: (parent.width - 1) / 2
                height: (parent.height - 1) / 2
                anchors.right: parent.right
                anchors.bottom: parent.bottom
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
                        rclick_menu.x = mouse.x + parent.x + surveillance_window.x
                        rclick_menu.y = mouse.y + parent.y + surveillance_window.y
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

        // 录像回放窗口
        Rectangle {
            id: record_window
            height: parent.height - title_bar.height
            anchors.top: title_bar.bottom
            anchors.left: spacer_1.right
            anchors.right: parent.right
            color: "green"
            property string window_name: "录像回放"
            visible: windows_option.current_window_name == window_name ? true : false

            property string record_file_name: ""
            property string record_encryption: ""

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
                color: "#f4f4f6"
                radius: 5

                Text {
                    id: record_begin_time_text_hint
                    text: "开始时间"
                    font.family: "微软雅黑"
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
                    font.family: "微软雅黑"
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
                color: "#f4f4f6"

                Row {
                    anchors.centerIn: parent
                    spacing: 15

                    // 前进单帧按钮
                    Rectangle {
                        width: 35
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#00000000"
                        Rectangle {
                            id: btn_one_frame_backward
                            width: 35
                            height: width
                            radius: 8
                            color: btn_one_frame_backward_mouse_area.containsMouse ? "#0A000000" : "#00000000"
                            anchors.centerIn: parent

                            Image {
                                width: parent.width * 0.5
                                height: width
                                anchors.centerIn: parent
                                source: "/skins/default/one_backward.png"
                            }
                            MouseArea {
                                id: btn_one_frame_backward_mouse_area
                                anchors.fill: parent
                                onClicked: {
                                    record_ctrl.step_one_frame_backward()
                                    btn_play.is_pause = true
                                }
                                onPressed: {
                                    parent.width = 30
                                }
                                onReleased: {
                                    parent.width = 35
                                }
                                hoverEnabled: true
                            }
                            ToolTip {
                                text: "单帧后退"
                                visible: btn_one_frame_backward_mouse_area.containsMouse ? true : false
                            }
                        }
                    }

                    // 快退按钮
                    Rectangle {
                        width: 35
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#00000000"
                        Rectangle {
                            id: btn_fast_backward
                            width: 35
                            height: width
                            radius: 8
                            color: btn_fast_backward_mouse_area.containsMouse ? "#0A000000" : "#00000000"
                            anchors.centerIn: parent

                            Image {
                                width: parent.width * 0.8
                                height: width
                                anchors.centerIn: parent
                                source: "/skins/default/fast_backward.png"
                            }
                            MouseArea {
                                id: btn_fast_backward_mouse_area
                                anchors.fill: parent
                                onClicked: {
                                    record_ctrl.step_by_second(-5)
                                    btn_play.is_pause = false
                                }
                                onPressed: {
                                    parent.width = 30
                                }
                                onReleased: {
                                    parent.width = 35
                                }
                                hoverEnabled: true
                            }
                            ToolTip {
                                text: "快退5秒"
                                visible: btn_fast_backward_mouse_area.containsMouse ? true : false
                            }
                        }
                    }

                    // 播放/暂停按钮
                    Rectangle {
                        width: 40
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#00000000"
                        Rectangle {
                            id: btn_play
                            width: 40
                            height: width
                            radius: 8
                            color: btn_play_mouse_area.containsMouse ? "#0A000000" : "#00000000"
                            anchors.centerIn: parent

                            property bool is_playing: false
                            property bool is_pause: false

                            Image {
                                id: btn_play_image
                                width: parent.width * 0.8
                                height: width
                                anchors.centerIn: parent
                                source: parent.is_playing && !parent.is_pause ? "/skins/default/pause.png" : "/skins/default/play.png"
                            }
                            MouseArea {
                                id: btn_play_mouse_area
                                anchors.fill: parent
                                onClicked: {
                                    parent.record_btn_play_impl()
                                }
                                onPressed: {
                                    parent.width = 35
                                }
                                onReleased: {
                                    parent.width = 40
                                }
                                hoverEnabled: true
                            }
                            ToolTip {
                                text: parent.is_playing && !parent.is_pause ? "暂停" : "播放"
                                visible: btn_play_mouse_area.containsMouse ? true : false
                            }

                            function record_btn_play_impl() {
                                if(!btn_play.is_playing) {
                                    if(record_window.record_file_name === "") return;
                                    record_ctrl.play(record_window.record_file_name, record_window.record_encryption)
                                    input_record_time_dlg.visible = false
                                    btn_play.is_playing = true
                                    btn_play.is_pause = false
                                }else {
                                    record_ctrl.pause()
                                    if(btn_play.is_pause) btn_play.is_pause = false
                                    else btn_play.is_pause = true
                                }
                            }
                        }
                    }

                    // 关闭按钮
                    Rectangle {
                        width: 35
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#00000000"
                        Rectangle {
                            id: btn_stop
                            width: 35
                            height: width
                            radius: 8
                            color: btn_stop_mouse_area.containsMouse ? "#0A000000" : "#00000000"
                            anchors.centerIn: parent

                            Image {
                                width: parent.width * 0.4
                                height: width
                                anchors.centerIn: parent
                                source: "/skins/default/stop.png"
                            }
                            MouseArea {
                                id: btn_stop_mouse_area
                                anchors.fill: parent
                                onClicked: {
                                    record_ctrl.stop()
                                    btn_play.is_pause = false
                                    btn_play.is_playing = false
                                    input_record_time_dlg.visible = true
                                }
                                onPressed: {
                                    parent.width = 30
                                }
                                onReleased: {
                                    parent.width = 35
                                }
                                hoverEnabled: true
                            }
                            ToolTip {
                                text: "关闭"
                                visible: btn_stop_mouse_area.containsMouse ? true : false
                            }
                        }
                    }

                    // 快进按钮
                    Rectangle {
                        width: 35
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#00000000"
                        Rectangle {
                            id: btn_fast_forward
                            width: 35
                            height: width
                            radius: 8
                            color: btn_fast_forward_mouse_area.containsMouse ? "#0A000000" : "#00000000"
                            anchors.centerIn: parent

                            Image {
                                width: parent.width * 0.8
                                height: width
                                anchors.centerIn: parent
                                source: "/skins/default/fast_forward.png"
                            }
                            MouseArea {
                                id: btn_fast_forward_mouse_area
                                anchors.fill: parent
                                onClicked: {
                                    record_ctrl.step_by_second(5)
                                    btn_play.is_pause = false
                                }
                                onPressed: {
                                    parent.width = 30
                                }
                                onReleased: {
                                    parent.width = 35
                                }
                                hoverEnabled: true
                            }
                            ToolTip {
                                text: "快进5秒"
                                visible: btn_fast_forward_mouse_area.containsMouse ? true : false
                            }
                        }
                    }

                    // 前进单帧按钮
                    Rectangle {
                        width: 35
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#00000000"
                        Rectangle {
                            id: btn_one_frame_forward
                            width: 35
                            height: width
                            radius: 8
                            color: btn_one_frame_forward_mouse_area.containsMouse ? "#0A000000" : "#00000000"
                            anchors.centerIn: parent

                            Image {
                                width: parent.width * 0.5
                                height: width
                                anchors.centerIn: parent
                                source: "/skins/default/one_forward.png"
                            }
                            MouseArea {
                                id: btn_one_frame_forward_mouse_area
                                anchors.fill: parent
                                onClicked: {
                                    record_ctrl.step_one_frame_forward()
                                    btn_play.is_pause = true
                                }
                                onPressed: {
                                    parent.width = 30
                                }
                                onReleased: {
                                    parent.width = 35
                                }
                                hoverEnabled: true
                            }
                            ToolTip {
                                text: "单帧前进"
                                visible: btn_one_frame_forward_mouse_area.containsMouse ? true : false
                            }
                        }
                    }
                }
            }
        }

        // 添加设备窗口
        Rectangle {
            id: add_device_window
            height: parent.height - title_bar.height
            anchors.top: title_bar.bottom
            anchors.left: spacer_1.right
            anchors.right: parent.right
            property string window_name: "添加设备"
            visible: windows_option.current_window_name == window_name ? true : false
            color: "#f4f4f6"

            Row {
                id: key_input_layout
                width: 350
                height: 50
                spacing: 10
                anchors.centerIn: parent

                property int shadow_radius: 15
                property string shadow_color: "#3A000000"
                property string key_num_font_family: "等线"
                property string key_num_color: "#8F000000"

                TextInput {
                    id: key_input_text
                    text: "请输入注册码"
                    anchors.fill: parent
                    opacity: 0

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            key_input_text.forceActiveFocus()
                            if(key_input_text.text === "请输入注册码") key_input_text.text = ""
                        }
                    }

                    onTextChanged: {
                        if(text.length > 6) text = text.substring(0, 6)
                    }

                    onFocusChanged: {
                        if(text.length === 0) text = "请输入注册码"
                    }

                    onAccepted: {
                        if(text.length !== 6) return
                        let device_idx = mainctrl.addDevice(text)
                        if(device_idx !== -1) {
                            device_list_model.append({
                                "idx": device_idx,
                                "key": text,
                                "device_name": mainctrl.getDeviceName(device_idx),
                                "is_active": false,
                            });
                            text = ""
                        }
                    }
                }

                Rectangle {
                    id: key_input_1
                    width: parent.height + (key_input_text.length === 0 && key_input_text.focus === true ? 10 : 0)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 10
                    Text {
                        id: key_num_1
                        text: key_input_text.text[0] ? key_input_text.text[0] : ""
                        font.pixelSize: parent.height * 0.7
                        font.family: key_input_layout.key_num_font_family
                        color: key_input_layout.key_num_color
                        anchors.centerIn: parent
                    }
                }

                DropShadow {
                    anchors.fill: key_input_1
                    radius: key_input_layout.shadow_radius
                    samples: 16
                    source: key_input_1
                    color: key_input_layout.shadow_color
                    Behavior on radius { PropertyAnimation { duration: 100 } }
                }

                Rectangle {
                    id: key_input_2
                    width: parent.height + (key_input_text.length === 1 && key_input_text.focus === true ? 10 : 0)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 10
                    anchors.left: key_input_1.right
                    anchors.leftMargin: 10
                    Text {
                        id: key_num_2
                        text: key_input_text.text[1] ? key_input_text.text[1] : ""
                        font.pixelSize: parent.height * 0.7
                        font.family: key_input_layout.key_num_font_family
                        color: key_input_layout.key_num_color
                        anchors.centerIn: parent
                    }
                }

                DropShadow {
                    anchors.fill: key_input_2
                    radius: key_input_layout.shadow_radius
                    samples: 16
                    source: key_input_2
                    color: key_input_layout.shadow_color
                    Behavior on radius { PropertyAnimation { duration: 100 } }
                }

                Rectangle {
                    id: key_input_3
                    width: parent.height + (key_input_text.length === 2 && key_input_text.focus === true ? 10 : 0)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 10
                    anchors.left: key_input_2.right
                    anchors.leftMargin: 10
                    Text {
                        id: key_num_3
                        text: key_input_text.text[2] ? key_input_text.text[2] : ""
                        font.pixelSize: parent.height * 0.7
                        font.family: key_input_layout.key_num_font_family
                        color: key_input_layout.key_num_color
                        anchors.centerIn: parent
                    }
                }

                DropShadow {
                    anchors.fill: key_input_3
                    radius: key_input_layout.shadow_radius
                    samples: 16
                    source: key_input_3
                    color: key_input_layout.shadow_color
                    Behavior on radius { PropertyAnimation { duration: 100 } }
                }

                Rectangle {
                    id: key_input_4
                    width: parent.height + (key_input_text.length === 3 && key_input_text.focus === true ? 10 : 0)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 10
                    anchors.left: key_input_3.right
                    anchors.leftMargin: 10
                    Text {
                        id: key_num_4
                        text: key_input_text.text[3] ? key_input_text.text[3] : ""
                        font.pixelSize: parent.height * 0.7
                        font.family: key_input_layout.key_num_font_family
                        color: key_input_layout.key_num_color
                        anchors.centerIn: parent
                    }
                }

                DropShadow {
                    anchors.fill: key_input_4
                    radius: key_input_layout.shadow_radius
                    samples: 16
                    source: key_input_4
                    color: key_input_layout.shadow_color
                    Behavior on radius { PropertyAnimation { duration: 100 } }
                }

                Rectangle {
                    id: key_input_5
                    width: parent.height + (key_input_text.length === 4 && key_input_text.focus === true ? 10 : 0)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 10
                    anchors.left: key_input_4.right
                    anchors.leftMargin: 10
                    Text {
                        id: key_num_5
                        text: key_input_text.text[4] ? key_input_text.text[4] : ""
                        font.pixelSize: parent.height * 0.7
                        font.family: key_input_layout.key_num_font_family
                        color: key_input_layout.key_num_color
                        anchors.centerIn: parent
                    }
                }

                DropShadow {
                    anchors.fill: key_input_5
                    radius: key_input_layout.shadow_radius
                    samples: 16
                    source: key_input_5
                    color: key_input_layout.shadow_color
                    Behavior on radius { PropertyAnimation { duration: 100 } }
                }

                Rectangle {
                    id: key_input_6
                    width: parent.height + (key_input_text.length === 5 && key_input_text.focus === true ? 10 : 0)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 10
                    anchors.left: key_input_5.right
                    anchors.leftMargin: 10
                    Text {
                        id: key_num_6
                        text: key_input_text.text[5] ? key_input_text.text[5] : ""
                        font.pixelSize: parent.height * 0.7
                        font.family: key_input_layout.key_num_font_family
                        color: key_input_layout.key_num_color
                        anchors.centerIn: parent
                    }
                }

                DropShadow {
                    anchors.fill: key_input_6
                    radius: key_input_layout.shadow_radius
                    samples: 16
                    source: key_input_6
                    color: key_input_layout.shadow_color
                    Behavior on radius { PropertyAnimation { duration: 100 } }
                }
            }
        }

        // 登录注册窗口
        Rectangle {
            id: login_or_register_window
            height: parent.height - title_bar.height
            anchors.top: title_bar.bottom
            anchors.left: spacer_1.right
            anchors.right: parent.right
            property string window_name: "登录注册窗口"
            visible: windows_option.current_window_name == window_name || !logined ? true : false
            color: "#f4f4f6"
            z: 2

            MouseArea {
                propagateComposedEvents: parent.logined
                anchors.fill: parent
                onClicked: {
                    forceActiveFocus()
                    mouse.accepted = false
                }
            }

            property bool logined: false

            // 登录窗口
            Rectangle {
                id: lrwindow
                height: 480
                width: 380
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: (parent.width - width) * 0.8
                radius: 20
                color: "#f4f4f6"

                property bool isLoginWindow: true
                property int anim_speed: 300

                NumberAnimation on anchors.leftMargin {
                    id: login_window_animation
                    to: 0
                    duration: lrwindow.anim_speed
                    easing.overshoot: Easing.InOutBack

                    Component.onCompleted: {
                        stop()
                    }
                }

                function changeWindowStatu() {
                    lrwindow.isLoginWindow = !lrwindow.isLoginWindow
                    login_window_animation.to = (login_or_register_window.width - lrwindow.width) * (lrwindow.isLoginWindow ? 0.8 : 0.2)
                    lr_btn_push_animation.to = lrwindow.isLoginWindow ? 20 : 90
                    lr_check_password_input_animation.to = lrwindow.isLoginWindow ? 0 : 100
                    lr_check_password_input_impl.text = ""
                    login_window_animation.restart()
                    lr_btn_push_animation.restart()
                    lr_check_password_input_animation.restart()
                }

                function do_login() {
                    if(lr_username_input_impl.length === 0
                    || lr_password_input_impl.length === 0) {
                        mainWindow.error("用户名或密码不能为空")
                        return
                    }

                    let ret = mainctrl.login_user(lr_username_input_impl.text,
                                        lr_password_input_impl.text)

                    if(ret === "登录成功") {
                        mainWindow.success("登录成功")
                        login_or_register_window.logined = true
                        username.text = lr_username_input_impl.text

                        var device_list_str = mainctrl.getAllDeviceKey();
                        console.log("key ============================", device_list_str);
                        var device_list_json = JSON.parse(device_list_str);
                        console.log("json:", device_list_json);
                        for(var idx in device_list_json) {
                            let device_idx = mainctrl.addDevice(device_list_json[idx]);
                            if(device_idx !== -1) {
                                device_list_model.append({
                                    "idx": device_idx,
                                    "key": device_list_json[idx],
                                    "device_name": mainctrl.getDeviceName(device_idx),
                                    "is_active": false,
                                });
                            }
                        }
                        console.log("end ============================");


                        return
                    }

                    mainWindow.error(ret)
                }

                function do_register() {
                    if(lr_username_input_impl.length === 0
                    || lr_password_input_impl.length === 0
                    || lr_check_password_input_impl.length === 0) {
                        mainWindow.error("用户名或密码不能为空")
                        return
                    }

                    if(lr_password_input_impl.text !==
                            lr_check_password_input_impl.text) {
                        mainWindow.error("密码不一致")
                        return
                    }

                    let ret = mainctrl.register_user(lr_username_input_impl.text,
                                        lr_password_input_impl.text)

                    if(ret === "注册成功") {
                        mainWindow.success("注册成功")
                        return
                    }

                    mainWindow.error(ret)
                }

                Label {
                    id: lr_window_label
                    text: lrwindow.isLoginWindow ? "登录" : "注册"
                    font.bold: true
                    font.family: "黑体"
                    font.pointSize: 15
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 60
                    anchors.leftMargin: 30
                }

                Rectangle {
                    id: lr_username_input
                    width: parent.width - 60
                    height: 50
                    radius: 10
                    border.color: "#1F000000"
                    border.width: 2
                    anchors.top: lr_window_label.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 30

                    Text {
                        text: "请输入用户名"
                        width: parent.width - 30
                        height: parent.height - 20
                        anchors.top: parent.top
                        anchors.topMargin: 15
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        font.family: "等线"
                        font.pixelSize: height * 0.6
                        color: "#4F000000"
                        visible: lr_username_input_impl.length == 0 ? true : false
                    }

                    TextInput {
                        id: lr_username_input_impl
                        width: parent.width - 30
                        height: parent.height - 20
                        anchors.top: parent.top
                        anchors.topMargin: 15
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        font.family: "等线"
                        font.pixelSize: height * 0.6
                        clip: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            lr_username_input_impl.forceActiveFocus()
                        }
                    }
                }

                Rectangle {
                    id: lr_password_input
                    width: parent.width - 60
                    height: 50
                    radius: 10
                    border.color: "#1F000000"
                    border.width: 2
                    anchors.top: lr_username_input.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 30

                    Text {
                        text: "请输入密码"
                        width: parent.width - 30
                        height: parent.height - 20
                        anchors.top: parent.top
                        anchors.topMargin: 15
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        font.family: "等线"
                        font.pixelSize: height * 0.6
                        color: "#4F000000"
                        visible: lr_password_input_impl.length == 0 ? true : false
                    }

                    TextInput {
                        id: lr_password_input_impl
                        width: parent.width - 30
                        height: parent.height - 20
                        anchors.top: parent.top
                        anchors.topMargin: 17
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        font.family: "等线"
                        font.pixelSize: height * 0.5
                        clip: true
                        echoMode: TextInput.Password
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            lr_password_input_impl.forceActiveFocus()
                        }
                    }
                }

                Rectangle {
                    id: lr_check_password_input
                    width: parent.width - 60
                    height: 50
                    radius: 10
                    border.color: "#1F000000"
                    border.width: 2
                    anchors.top: lr_password_input.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 30
                    opacity: 0

                    Text {
                        text: "确认密码"
                        width: parent.width - 30
                        height: parent.height - 20
                        anchors.top: parent.top
                        anchors.topMargin: 15
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        font.family: "等线"
                        font.pixelSize: height * 0.6
                        color: "#4F000000"
                        visible: lr_check_password_input_impl.length == 0 ? true : false
                    }

                    TextInput {
                        id: lr_check_password_input_impl
                        width: parent.width - 30
                        height: parent.height - 20
                        anchors.top: parent.top
                        anchors.topMargin: 17
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        font.family: "等线"
                        font.pixelSize: height * 0.5
                        clip: true
                        echoMode: TextInput.Password
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            lr_check_password_input_impl.forceActiveFocus()
                        }
                    }

                    NumberAnimation on opacity {
                        id: lr_check_password_input_animation
                        to: 0
                        duration: lrwindow.anim_speed
                        easing.overshoot: Easing.InOutBack
                        Component.onCompleted: {
                            stop();
                        }
                    }
                }

                Rectangle {
                    id: lr_btn_push
                    width: parent.width - 60
                    height: 50
                    radius: 10
                    anchors.top: lr_password_input.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 30
                    color: lr_btn_push_mouse_area.containsMouse ? "#097ff9" : "#429efd"
                    z: 3

                    NumberAnimation on anchors.topMargin {
                        id: lr_btn_push_animation
                        to: 20
                        duration: lrwindow.anim_speed
                        easing.overshoot: Easing.InOutBack
                        Component.onCompleted: {
                            stop();
                        }
                    }

                    MouseArea {
                        id: lr_btn_push_mouse_area
                        anchors.fill: parent
                        onClicked:  {
                            if(lrwindow.isLoginWindow) lrwindow.do_login()
                            else lrwindow.do_register()
                        }
                        hoverEnabled: true
                    }

                    Text {
                        text: lrwindow.isLoginWindow ? "登 录" : "注 册"
                        color: "#f4f4f6"
                        font.pointSize: 14
                        font.family: "等线"
                        anchors.centerIn: parent
                    }
                }

                Image {
                    id: conner_change_btn
                    source: conner_change_btn_mouse_area.containsMouse &&
                            conner_change_btn_mouse_area.mouseX + 13 >= conner_change_btn_mouse_area.mouseY
                            ? "qrc:/skins/default/conner_dep.png" : "qrc:/skins/default/conner.png"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -13
                    anchors.rightMargin: -13
                    width: 100
                    height: 100

                    MouseArea {
                        id: conner_change_btn_mouse_area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if(conner_change_btn_mouse_area.containsMouse
                            && conner_change_btn_mouse_area.mouseX + 13 >= conner_change_btn_mouse_area.mouseY) {
                                lrwindow.changeWindowStatu()
                            }
                        }
                    }
                }

                Image {
                    id: lr_conner_text
                    width: 80
                    height: 40
                    source: lrwindow.isLoginWindow ? "qrc:/skins/default/register.png" : "qrc:/skins/default/login.png"
                    anchors.top: parent.top
                    anchors.topMargin: 15
                    anchors.right: parent.right
                    anchors.rightMargin: -5
                    rotation: 45
                }

                Text {
                    id: lr_window_rule
                    text: "规则: 用户名为全英文、密码为6-15为数字、英文或字符'$、#、.、%、!、@'"
                    width: parent.width - 60
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 30
                    anchors.right: parent.right
                    anchors.rightMargin: 30
                    wrapMode: Text.WrapAnywhere
                    font.family: "微软雅黑"
                    font.pointSize: 10
                    color: "#4F000000"
                }
            }

            // 窗口阴影
            DropShadow {
                anchors.fill: lrwindow
                horizontalOffset: 0
                verticalOffset: 0
                radius: 20
                samples: 20
                source: lrwindow
                color: "#24000000"
                Behavior on radius { PropertyAnimation { duration: 100 } }
            }

        }

        // 系统设置窗口
        Rectangle {
            id: system_setting_window
            height: parent.height - title_bar.height
            anchors.top: title_bar.bottom
            anchors.left: spacer_1.right
            anchors.right: parent.right
            property string window_name: "系统设置窗口"
            visible: windows_option.current_window_name == window_name
            color: "#f4f4f6"
            z: 2

            MouseArea {
                propagateComposedEvents: parent.logined
                anchors.fill: parent
                onClicked: {
                    forceActiveFocus()
                    mouse.accepted = false
                }
            }

            // 返回按钮
            Rectangle {
                id: btn_system_setting_return
                width: 40
                height: width
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 60
                anchors.topMargin: 40
                color: btn_system_setting_return_mouse_area.containsMouse ? "#1A000000" : parent.color
                radius: 8
                Image {
                    source: "qrc:/skins/default/return.png"
                    width: parent.width * 0.6
                    height: width
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: btn_system_setting_return_mouse_area
                    anchors.fill: parent
                    onClicked: {
                        windows_option.current_window_name = btn_system_setting.pre_window_name
                    }
                    hoverEnabled: true
                }
            }


        }

        // 主控控件
        MainCtrl {
            id: mainctrl
            Component.onCompleted: {
                videoCtrl1.window_idx = mainctrl.addWindow(videoCtrl1)
                videoCtrl2.window_idx = mainctrl.addWindow(videoCtrl2)
                videoCtrl3.window_idx = mainctrl.addWindow(videoCtrl3)
                videoCtrl4.window_idx = mainctrl.addWindow(videoCtrl4)
            }
        }

        // 录像播放器控件
        RecordCtrl {
            id: record_ctrl
        }

        // 监控窗口右键菜单
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
                    if(camera.cameraState === Camera.ActiveState) {
                        mainctrl.stopTalk(rclick_menu.window_idx)
                        sender.stop()
                        camera.stop()
                        mainWindow.updateTalkWindowPos(rclick_menu.window_idx);
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
                        mainWindow.updateTalkWindowPos(rclick_menu.window_idx);
                        talk_videoOutput.visible = true
                    }
                }
            }
        }

        // 更新语音对讲窗口的位置
        function updateTalkWindowPos(window_idx) {
            if(window_idx === 0) {
                talk_videoOutput.x = surveillance_window.x + surface1.x + surface1.width - talk_videoOutput.width - 10
                talk_videoOutput.y = surveillance_window.y + surface1.y + 10
            }else if(window_idx === 1) {
                talk_videoOutput.x = surveillance_window.x + surface2.x + surface2.width - talk_videoOutput.width - 10
                talk_videoOutput.y = surveillance_window.y + surface2.y + 10
            }else if(window_idx === 2) {
                talk_videoOutput.x = surveillance_window.x + surface3.x + surface3.width - talk_videoOutput.width - 10
                talk_videoOutput.y = surveillance_window.y + surface3.y + 10
            }else {
                talk_videoOutput.x = surveillance_window.x + surface4.x + surface4.width - talk_videoOutput.width - 10
                talk_videoOutput.y = surveillance_window.y + surface4.y + 10
            }
        }

        // 摄像头
        Camera {
            id: camera
            Component.onCompleted: {
                camera.stop()
            }
        }

        // 获取摄像头帧数据
        CameraFilter {
            id: cameraFilter
            qmlCamera: camera
        }

        // 推流器
        VideoSender {
            id: sender
            cameraSource: cameraFilter
        }

        // 设备列表单击事件
        function onListItemClicked(item) {
            if(windows_option.current_window_name === "监控窗口") {
                let ret = mainctrl.playVideo(item.idx);
                if(ret === -1) {
                    if(item.is_active === false) error("设备不在线!")
                    else error("播放失败!");
                }
            }else if(windows_option.current_window_name === "录像回放") {
                if(input_begin_time.length === 0 || input_end_time.length === 0) return;
                let file = mainctrl.getRecordFile(item.idx, input_begin_time.text, input_end_time.text)
                if(file === "") return;
                record_window.record_file_name = file
                record_window.record_encryption = mainctrl.getEncryption(item.idx)
                btn_play.record_btn_play_impl()
            }
        }

        // 信息弹窗控件
        ListView {
            id: message_box_list
            width: 300
            height: 220
            anchors.horizontalCenter: surveillance_window.horizontalCenter
            anchors.top: title_bar.bottom
            anchors.topMargin: 10
            model: message_box_list_model
            delegate: message_box_list_delegate
            clip: true
            z: 2

            MouseArea {
                propagateComposedEvents: true
                anchors.fill: parent
                onClicked: {
                    forceActiveFocus()
                    mouse.accepted = false
                }
            }

            ListModel {
                id: message_box_list_model
            }

            Component {
                id: message_box_list_delegate
                Column { Row { // 绘制列表的单个Item

                Rectangle {
                    width: message_box_list.width
                    height: 55
                    color: "#00000000"

                    Rectangle {
                        id: box
                        width: message_box_list.width
                        height: 50
                        radius: 6
                        color: {
                            if(model.type === "info") return "#D9E1FF"
                            else if(model.type === "success") return "#C6F3D7"
                            else if(model.type === "error") return "#FFD8D2"
                            return "#FFD8D2"
                        }
                    }

                    Image {
                        id: msg_icon
                        width: box.height / 3
                        height: width
                        anchors.verticalCenter: box.verticalCenter
                        anchors.left: box.left
                        anchors.leftMargin: 20
                        source: {
                            if(model.type === "info") return "qrc:/skins/default/info.png"
                            else if(model.type === "success") return "qrc:/skins/default/success.png"
                            else if(model.type === "error") return "qrc:/skins/default/alarm.png"
                            return "qrc:/skins/default/alarm.png"
                        }
                    }

                    Text {
                        id: msg_text
                        text: model.msg
                        anchors.verticalCenter: box.verticalCenter
                        anchors.left: msg_icon.right
                        anchors.leftMargin: 15
                        anchors.right: box.right
                        anchors.rightMargin: 20
                        font.family: "等线"
                        font.pixelSize: parent.height / 4
                        color: "#272727"
                        wrapMode: Text.WrapAnywhere
                    }
                }

                } } // end of Column { Row {
            }
        }
        Timer {
            id: timer_delete_first_msg;
            property int count: 0
            interval: 3000;//设置定时器定时时间为500ms,默认1000ms
            repeat: false //是否重复定时,默认为false
            running: false //是否开启定时，默认是false，当为true的时候，进入此界面就开始定时
            triggeredOnStart: false // 是否开启定时就触发onTriggered，一些特殊用户可以用来设置初始值。
            onTriggered: {
                //定时触发槽,定时完成一次就进入一次
                while(count > 0) {
                    message_box_list_model.remove(0)
                    count--
                }
            }
        }
        function info(msg) {
            message_box_list_model.append({
                "type": "info",
                "msg": msg
            })
            timer_delete_first_msg.count++
            timer_delete_first_msg.start()
        }
        function success(msg) {
            message_box_list_model.append({
                "type": "success",
                "msg": msg
            })
            timer_delete_first_msg.count++
            timer_delete_first_msg.start()
        }
        function error(msg) {
            message_box_list_model.append({
                "type": "error",
                "msg": msg
            })
            timer_delete_first_msg.count++
            timer_delete_first_msg.start()
        }

        // 对讲画面
        VideoOutput {
            id: talk_videoOutput
            width: surface1.width * 0.3
            height: width * 9 / 16
            source: camera
            visible: false
            z: 2

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

    // 窗口阴影
    DropShadow {
        anchors.fill: mainWindow
        horizontalOffset: 0
        verticalOffset: 0
        radius: mainWindow_mouse_area.pressed ? 15 : 10
        samples: 10
        source: mainWindow
        color: "#4F000000"
        Behavior on radius { PropertyAnimation { duration: 100 } }
    }

    // 右边框调整大小
    MouseArea {
        id: frame_right_edge
        width: 10
        height: mainWindow.height - 20
        anchors.left: mainWindow.right
        anchors.verticalCenter: mainWindow.verticalCenter
        cursorShape: Qt.SizeHorCursor

        property int pre_mouse_x: 0

        onPressed: {
            pre_mouse_x = mouse.x
        }

        onPositionChanged: {
            if(pressed && mouse.x !== pre_mouse_x) {
                root.width = root.width + mouse.x - pre_mouse_x > root.minimumWidth ? root.width + mouse.x - pre_mouse_x : root.minimumWidth
            }
        }
    }

    // 下边框调整大小
    MouseArea {
        id: frame_bottom_edge
        width: mainWindow.width - 20
        height: 10
        anchors.top: mainWindow.bottom
        anchors.horizontalCenter: mainWindow.horizontalCenter
        cursorShape: Qt.SizeVerCursor

        property int pre_mouse_y: 0

        onPressed: {
            pre_mouse_y = mouse.y
        }

        onPositionChanged: {
            if(pressed && mouse.y !== pre_mouse_y) {
                root.height = root.height + mouse.y - pre_mouse_y > root.minimumHeight ? root.height + mouse.y - pre_mouse_y : root.minimumHeight
            }
        }
    }

    // 右下角调整大小
    MouseArea {
        id: frame_right_bottom
        width: 20
        height: 20
        anchors.left: mainWindow.right
        anchors.top: mainWindow.bottom
        anchors.leftMargin: -10
        anchors.topMargin: -10
        cursorShape: Qt.SizeFDiagCursor

        property int pre_mouse_x: 0
        property int pre_mouse_y: 0

        onPressed: {
            pre_mouse_x = mouse.x
            pre_mouse_y = mouse.y
        }

        onPositionChanged: {
            if(pressed && (mouse.x !== pre_mouse_x || mouse.y !== pre_mouse_y)) {
                root.width = root.width + mouse.x - pre_mouse_x > root.minimumWidth ? root.width + mouse.x - pre_mouse_x : root.minimumWidth
                root.height = root.height + mouse.y - pre_mouse_y > root.minimumHeight ? root.height + mouse.y - pre_mouse_y : root.minimumHeight
            }
        }
    }
}
