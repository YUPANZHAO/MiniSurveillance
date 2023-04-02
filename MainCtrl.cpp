#include "MainCtrl.h"

MainCtrl::MainCtrl()
: is_talking(false)
, msg_cb_thread(nullptr) {
    rpc = make_unique<IPCClient>();
}

MainCtrl::~MainCtrl() {
    rpc->call({
        { "method", "logout" },
        { "token", token }
    });
    msg_cb_thread->join();
}

QString MainCtrl::getDeviceName(int idx) {
    if(idx < 0 || idx >= devices.size()) return "";
    return devices[idx].name.c_str();
}

bool MainCtrl::getDeviceIsPlaying(int idx) {
    if(idx < 0 || idx >= devices.size()) return false;
    return devices[idx].is_playing;
}

bool MainCtrl::getWindowIsPlayingAudio(int idx) {
    if(idx < 0 || idx >= windows.size()) return false;
    int window_idx = windows[idx].device_idx;
    if(window_idx < 0 || window_idx >= devices.size()) return false;
    return devices[window_idx].is_playing_audio;
}

int MainCtrl::getDeivceIdxByWindowIdx(int idx) {
    if(idx < 0 || idx >= windows.size()) return -1;
    return windows[idx].device_idx;
}

bool MainCtrl::getDeviceIsActive(int idx) {
    if(idx < 0 || idx >= devices.size()) return false;
    return devices[idx].is_active;
}

QString MainCtrl::getAllDeviceKey() {
    return init_device_list.c_str();
}

int MainCtrl::addDevice(const QString & key) {
    auto [ctx, ret] = rpc->call({
        { "method", "get_device_info" },
        { "user", token },
        { "key", key.toStdString() }
    });
    if(!ret) {
        debug("添加设备失败");
        return -1;
    }

    DeviceInfo info;
    info.name = ctx.value("name", "未命名设备");
    info.key = key.toStdString();
    info.rtmp_url = ctx.value("rtmp_url", "");
    info.encryption = ctx.value("encryption", "");
    info.is_active = false;
    info.is_playing = false;
    info.is_playing_audio = false;
    info.window_idx = -1;
    devices.push_back(info);
    return devices.size() - 1;
}

int MainCtrl::addWindow(VideoCtrl* videoCtrl) {
    WindowInfo info;
    info.is_playing = false;
    info.device_idx = -1;
    info.video_ctrl = videoCtrl;
    windows.push_back(info);
    return windows.size() - 1;
}

int MainCtrl::playVideo(int device_idx) {
    debug("playVideo", device_idx);
    if(device_idx < 0 || device_idx >= devices.size()) return -1;
    // 获取设备
    auto device = devices[device_idx];
    // 设备不在线或设备正在播放
    debug("device info:", device.is_active, device.is_playing, device.rtmp_url);
    if(!device.is_active || device.is_playing) return -1;
    // 获取窗口索引
    int window_idx = findWindow();
    if(window_idx == -1) return -1;
    // 视频在播放则停止覆盖
    if(windows[window_idx].is_playing) {
        stopVideo(windows[window_idx].device_idx);
    }
    // 播放视频
    bool ret = windows[window_idx].video_ctrl->play(device.rtmp_url.c_str(), device.encryption.c_str());
    if(!ret) return -1;
    // 更新信息
    windows[window_idx].device_idx = device_idx;
    windows[window_idx].is_playing = true;
    devices[device_idx].is_playing = true;
    devices[device_idx].window_idx = window_idx;
    return window_idx;
}

void MainCtrl::playAudio(int window_idx) {
    debug("playAudio", window_idx);
    if(window_idx < 0 || window_idx >= windows.size()) return;
    // 获取窗口
    auto & window = windows[window_idx];
    if(window.device_idx < 0 || window.device_idx >= devices.size()) return;
    // 获取设备
    auto & device = devices[window.device_idx];
    // 开启音频
    if(window.is_playing) {
        window.video_ctrl->playAudio();
        device.is_playing_audio = true;
    }
}

void MainCtrl::stopVideo(int device_idx) {
    debug("stopVideo", device_idx);
    if(device_idx < 0 || device_idx >= devices.size()) return;
    // 获取设备
    auto & device = devices[device_idx];
    if(device.window_idx < 0 || device.window_idx >= windows.size()) return;
    // 获取窗口
    auto & window = windows[device.window_idx];
    // 关闭视频音频
    window.video_ctrl->stop();
    // 更新信息
    window.is_playing = false;
    window.device_idx = -1;
    device.is_playing = false;
    device.is_playing_audio = false;
    device.window_idx = -1;
}

void MainCtrl::stopAudio(int window_idx) {
    if(window_idx < 0 || window_idx >= windows.size()) return;
    // 获取窗口
    auto & window = windows[window_idx];
    if(window.device_idx < 0 || window.device_idx >= devices.size()) return;
    // 获取设备
    auto & device = devices[window.device_idx];
    // 关闭音频
    if(window.is_playing) {
        window.video_ctrl->stopAudio();
    }
    device.is_playing_audio = false;
}

int MainCtrl::findWindow() {
    int idx = -1;
    for(int i=0; i < windows.size(); ++i) {
        idx = 0;
        if(windows[i].is_playing) continue;
        idx = i;
        break;
    }
    debug("窗口idx:", idx);
    return idx;
}

bool MainCtrl::startTalk(int window_idx) {
    if(is_talking) return false;
    if(window_idx < 0 || window_idx >= windows.size()) return false;
    // 获取窗口
    auto & window = windows[window_idx];
    if(window.device_idx < 0 || window.device_idx >= devices.size()) return false;
    // 获取设备
    auto & device = devices[window.device_idx];
    // 通知连接设备
    auto [ctx, ret] = rpc->call({
        { "method", "talk_ctrl" },
        { "ctrl_type", "start" },
        { "device_key", device.key }
    });
    if(!ret) return false;
    string req_talk_ret = ctx.value("result", "");
    if(req_talk_ret != "success") {
        debug("对讲开启失败, err_msg:", ctx.value("err_msg", ""));
        return false;
    }
    talk_rtmp_push_url = ctx.value("rtmp_push_url", "");
    is_talking = true;
    return true;
}

void MainCtrl::stopTalk(int window_idx) {
    if(!is_talking) return;
    if(window_idx < 0 || window_idx >= windows.size()) return;
    // 获取窗口
    auto & window = windows[window_idx];
    if(window.device_idx < 0 || window.device_idx >= devices.size()) return;
    // 获取设备
    auto & device = devices[window.device_idx];
    // 通知连接设备
    rpc->call({
        { "method", "talk_ctrl" },
        { "ctrl_type", "stop" },
        { "device_key", device.key }
    });
    is_talking = false;
}

QString MainCtrl::getTalkRtmpUrl() {
    return talk_rtmp_push_url.c_str();
}

void MainCtrl::startMessageCallBack() {
    msg_cb_thread = make_unique<std::thread>([this]() {
        this->rpc->streamCall({
            { "method", "message_callback" },
            { "id", this->token }
        },
        [this](const string & msg) {
            this->MessageHandle(msg);
        });
    });
}

void MainCtrl::MessageHandle(const string & msg) {
    debug("receive msg:", msg);
    json js_msg = json::parse(msg);
    if(js_msg.value("reply", json()) != json()) {
        json reply = js_msg.value("reply", json());
        if(reply.value("operation", "") == "device status change") {
            string device_id = reply.value("device_id", "");
            string device_status = reply.value("device_status", "");
            if(device_id != "" && device_status != "") {
                for(auto & device : devices) {
                    if(device.key == device_id) {
                        device.is_active = device_status == "active" ? true : false;
                        debug("changed", device_id, device_status);
                        break;
                    }
                }
            }
        }
    }
}

QString MainCtrl::getRecordFile(int device_idx, QString begin_time, QString end_time) {
    if(device_idx < 0 || device_idx >= devices.size()) return "";
    // 获取设备
    auto & device = devices[device_idx];

    auto ret = rpc->recordDownload({
        { "key", device.key },
        { "begin_time", begin_time.toStdString() },
        { "end_time", end_time.toStdString() }
    });
    if(ret == nullopt) {
        debug("录像文件获取失败");
        return "";
    }
    return (*ret).c_str();
}

QString MainCtrl::getEncryption(int device_idx) {
    if(device_idx < 0 || device_idx >= devices.size()) return "";
    // 获取设备
    auto & device = devices[device_idx];
    return device.encryption.c_str();
}

QString MainCtrl::register_user(const QString & username, const QString & password) {
    auto [reply,ret] = rpc->call({
        { "method", "register" },
        { "username", username.toStdString() },
        { "password", password.toStdString() }
    });
    if(ret && reply.value("msg", "failure") == "success") {
        return "注册成功";
    }
    return reply.value("reason", "注册失败").c_str();
}

QString MainCtrl::login_user(const QString & username, const QString & password) {
    auto [reply,ret] = rpc->call({
        { "method", "login" },
        { "username", username.toStdString() },
        { "password", password.toStdString() }
    });
    debug("login reply:", reply.dump());
    if(ret && reply.value("msg", "failure") == "success") {
        token = reply.value("token", "");
        if(!token.empty()) {
            startMessageCallBack();
            auto device_list = reply.value("device_list", json::array());
            init_device_list = device_list.dump();
        }
        return token == "" ? "登录失败" :  "登录成功";
    }
    return "登录失败";
}
