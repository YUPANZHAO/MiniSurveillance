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

int MainCtrl::addDevice(const QString & key) {
    auto [ctx, ret] = rpc->call({
        { "method", "get_device_info" },
        { "key", key.toStdString() }
    });
    if(!ret) {
        debug("�����豸ʧ��");
        return -1;
    }

    DeviceInfo info;
    info.name = ctx.value("name", "δ�����豸");
    info.rtmp_url = ctx.value("rtmp_url", "");
    info.is_active = true;
    info.is_playing = false;
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
        windows[window_idx].video_ctrl->stop();
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

}

void MainCtrl::stopVideo(int device_idx) {
    debug("stopVideo", device_idx);
    if(device_idx < 0 || device_idx >= devices.size()) return;
    // ��ȡ�豸
    auto & device = devices[device_idx];
    // ��ȡ����
    auto & window = windows[device.window_idx];
    // �ر���Ƶ��Ƶ
    window.video_ctrl->stop();
    // ������Ϣ
    window.is_playing = false;
    window.device_idx = -1;
    device.is_playing = false;
    device.window_idx = -1;
}

void MainCtrl::stopAudio(int window_idx) {

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