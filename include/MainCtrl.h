#ifndef MAINCTRL_H
#define MAINCTRL_H

#include "debug.h"
#include <QObject>
#include "VideoCtrl.h"
#include <vector>
#include <memory>
#include <thread>
#include "IPCClient.h"

using namespace ZYP;
using namespace std;

// 设备信息
struct DeviceInfo {
    // 设备名称
    string name;
    // 设备注册码
    string key;
    // RTMP流地址
    string rtmp_url;
    // 是否在线
    bool is_active;
    // 是否正在播放
    bool is_playing;
    // 是否正在播放音频
    bool is_playing_audio;
    // 播放占用窗口索引值
    int window_idx;
};

// 播放窗口信息
struct WindowInfo {
    // 是否正在播放
    bool is_playing;
    // 播放设备索引值
    int device_idx;
    // 播放器控制句柄
    VideoCtrl* video_ctrl;
};

class MainCtrl : public QObject {

    Q_OBJECT

public:
    MainCtrl();
    ~MainCtrl();

public:
    // 获取设备信息
    Q_INVOKABLE QString getDeviceName(int idx);
    Q_INVOKABLE bool getDeviceIsPlaying(int idx);
    Q_INVOKABLE bool getWindowIsPlayingAudio(int idx);
    Q_INVOKABLE int getDeivceIdxByWindowIdx(int idx);

    // 通过设备注册码添加设备，返回设备索引值
    Q_INVOKABLE int addDevice(const QString & key);
    // 添加播放窗口，返回窗口索引值
    Q_INVOKABLE int addWindow(VideoCtrl* videoCtrl);

    // 播放视频，返回对应的窗口索引值，-1代表失败
    Q_INVOKABLE int playVideo(int device_idx);
    // 播放音频，参数为 playVideo 的返回值，即窗口的索引值
    Q_INVOKABLE void playAudio(int window_idx);
    // 关闭视频，参数同播放视频一致
    Q_INVOKABLE void stopVideo(int device_idx);
    // 关闭音频，参数同播放音频一致
    Q_INVOKABLE void stopAudio(int window_idx);

    // 开启对讲
    Q_INVOKABLE bool startTalk(int window_idx);
    // 关闭对讲
    Q_INVOKABLE void stopTalk(int window_idx);
    // 获取对讲的rtmp地址
    Q_INVOKABLE QString getTalkRtmpUrl();

    // 获取录像文件
    Q_INVOKABLE QString getRecordFile(int device_idx, QString begin_time, QString end_time);

private:
    // 查找可用窗口，若无可以窗口，默认替换第一个
    int findWindow();

    // 开启消息回调
    void startMessageCallBack();
    // 消息回调处理函数
    void MessageHandle(const string & msg);

private:
    // 存储设备信息
    vector<DeviceInfo> devices;
    // 存储播放器信息及控制句柄
    vector<WindowInfo> windows;
    // RPC请求类
    unique_ptr<IPCClient> rpc;
    // 是否正在对讲
    bool is_talking;
    // 对讲的rtmp地址
    string talk_rtmp_push_url;
    // 消息回调线程
    unique_ptr<std::thread> msg_cb_thread;
    // 用户Token
    string token;
};

#endif // MAINCTRL_H
