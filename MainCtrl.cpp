#include "MainCtrl.h"

MainCtrl::MainCtrl()
: is_talking(false) {
    rpc = make_unique<IPCClient>();
}

MainCtrl::~MainCtrl() {

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

int MainCtrl::addDevice(const QString & key) {
    auto [ctx, ret] = rpc->call({
        { "method", "get_device_info" },
        { "key", key.toStdString() }
    });
    if(!ret) {
        debug("����豸ʧ��");
        return -1;
    }

    DeviceInfo info;
    info.name = ctx.value("name", "δ�����豸");
    info.key = key.toStdString();
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
    // ��ȡ�豸
    auto device = devices[device_idx];
    // �豸�����߻��豸���ڲ���
    debug("device info:", device.is_active, device.is_playing, device.rtmp_url);
    if(!device.is_active || device.is_playing) return -1;
    // ��ȡ��������
    int window_idx = findWindow();
    if(window_idx == -1) return -1;
    // ��Ƶ�ڲ�����ֹͣ����
    if(windows[window_idx].is_playing) {
        stopVideo(windows[window_idx].device_idx);
    }
    // ������Ƶ
    bool ret = windows[window_idx].video_ctrl->play(device.rtmp_url.c_str());
    if(!ret) return -1;
    // ������Ϣ
    windows[window_idx].device_idx = device_idx;
    windows[window_idx].is_playing = true;
    devices[device_idx].is_playing = true;
    devices[device_idx].window_idx = window_idx;
    return window_idx;
}

void MainCtrl::playAudio(int window_idx) {
    debug("playAudio", window_idx);
    if(window_idx < 0 || window_idx >= windows.size()) return;
    // ��ȡ����
    auto & window = windows[window_idx];
    if(window.device_idx < 0 || window.device_idx >= devices.size()) return;
    // ��ȡ�豸
    auto & device = devices[window.device_idx];
    // ������Ƶ
    if(window.is_playing) {
        window.video_ctrl->playAudio();
        device.is_playing_audio = true;
    }
}

void MainCtrl::stopVideo(int device_idx) {
    debug("stopVideo", device_idx);
    if(device_idx < 0 || device_idx >= devices.size()) return;
    // ��ȡ�豸
    auto & device = devices[device_idx];
    if(device.window_idx < 0 || device.window_idx >= windows.size()) return;
    // ��ȡ����
    auto & window = windows[device.window_idx];
    // �ر���Ƶ��Ƶ
    window.video_ctrl->stop();
    // ������Ϣ
    window.is_playing = false;
    window.device_idx = -1;
    device.is_playing = false;
    device.is_playing_audio = false;
    device.window_idx = -1;
}

void MainCtrl::stopAudio(int window_idx) {
    if(window_idx < 0 || window_idx >= windows.size()) return;
    // ��ȡ����
    auto & window = windows[window_idx];
    if(window.device_idx < 0 || window.device_idx >= devices.size()) return;
    // ��ȡ�豸
    auto & device = devices[window.device_idx];
    // �ر���Ƶ
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
    debug("����idx:", idx);
    return idx;
}

bool MainCtrl::startTalk(int window_idx) {
    if(is_talking) return false;
    if(window_idx < 0 || window_idx >= windows.size()) return false;
    // ��ȡ����
    auto & window = windows[window_idx];
    if(window.device_idx < 0 || window.device_idx >= devices.size()) return false;
    // ��ȡ�豸
    auto & device = devices[window.device_idx];
    // ֪ͨ�����豸
    auto [ctx, ret] = rpc->call({
        { "method", "talk_ctrl" },
        { "ctrl_type", "start" },
        { "device_key", device.key }
    });
    if(!ret) return false;
    string req_talk_ret = ctx.value("result", "");
    if(req_talk_ret != "success") {
        debug("�Խ�����ʧ��, err_msg:", ctx.value("err_msg", ""));
        return false;
    }
    talk_rtmp_push_url = ctx.value("rtmp_push_url", "");
    is_talking = true;
    return true;
}

void MainCtrl::stopTalk(int window_idx) {
    if(!is_talking) return;
    if(window_idx < 0 || window_idx >= windows.size()) return;
    // ��ȡ����
    auto & window = windows[window_idx];
    if(window.device_idx < 0 || window.device_idx >= devices.size()) return;
    // ��ȡ�豸
    auto & device = devices[window.device_idx];
    // ֪ͨ�����豸
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
