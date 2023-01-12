#include "MainCtrl.h"

MainCtrl::MainCtrl() {
    rpc = make_unique<IPCClient>();
}

MainCtrl::~MainCtrl() {

}

QString MainCtrl::getDeviceName(int idx) {
    return devices[idx].name.c_str();
}

bool MainCtrl::getDeviceIsPlaying(int idx) {
    return devices[idx].is_playing;
}

bool MainCtrl::getWindowIsPlayingAudio(int idx) {
    return devices[windows[idx].device_idx].is_playing_audio;
}

int MainCtrl::getDeivceIdxByWindowIdx(int idx) {
    return windows[idx].device_idx;
}

int MainCtrl::addDevice(const QString & key) {
    auto [ctx, ret] = rpc->call({
        { "method", "get_device_info" },
        { "key", key.toStdString() }
    });
    if(!ret) {
        debug("添加设备失败");
        return -1;
    }

    DeviceInfo info;
    info.name = ctx.value("name", "未命名设备");
    info.rtmp_url = ctx.value("rtmp_url", "");
    info.is_active = true;
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
    bool ret = windows[window_idx].video_ctrl->play(device.rtmp_url.c_str());
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
