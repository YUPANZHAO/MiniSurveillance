#ifndef MAINCTRL_H
#define MAINCTRL_H

#include "debug.h"
#include <QObject>
#include "VideoCtrl.h"
#include <vector>
#include <memory>
#include "IPCClient.h"

using namespace ZYP;
using namespace std;

// �豸��Ϣ
struct DeviceInfo {
    // �豸����
    string name;
    // RTMP����ַ
    string rtmp_url;
    // �Ƿ�����
    bool is_active;
    // �Ƿ����ڲ���
    bool is_playing;
    // ����ռ�ô�������ֵ
    int window_idx;
};

// ���Ŵ�����Ϣ
struct WindowInfo {
    // �Ƿ����ڲ���
    bool is_playing;
    // �����豸����ֵ
    int device_idx;
    // ���������ƾ��
    VideoCtrl* video_ctrl;
};

class MainCtrl : public QObject {

    Q_OBJECT

public:
    MainCtrl();
    ~MainCtrl();

public:
    // ��ȡ�豸��Ϣ
    Q_INVOKABLE QString getDeviceName(int idx);
    Q_INVOKABLE bool getDeviceIsPlaying(int idx);

    // ͨ���豸ע��������豸�������豸����ֵ
    Q_INVOKABLE int addDevice(const QString & key);
    // ��Ӳ��Ŵ��ڣ����ش�������ֵ
    Q_INVOKABLE int addWindow(VideoCtrl* videoCtrl);

    // ������Ƶ�����ض�Ӧ�Ĵ�������ֵ��-1����ʧ��
    Q_INVOKABLE int playVideo(int device_idx);
    // ������Ƶ������Ϊ playVideo �ķ���ֵ�������ڵ�����ֵ
    Q_INVOKABLE void playAudio(int window_idx);
    // �ر���Ƶ������ͬ������Ƶһ��
    Q_INVOKABLE void stopVideo(int device_idx);
    // �ر���Ƶ������ͬ������Ƶһ��
    Q_INVOKABLE void stopAudio(int window_idx);

private:
    // ���ҿ��ô��ڣ����޿��Դ��ڣ�Ĭ���滻��һ��
    int findWindow();

private:
    // �洢�豸��Ϣ
    vector<DeviceInfo> devices;
    // �洢��������Ϣ�����ƾ��
    vector<WindowInfo> windows;
    // RPC������
    unique_ptr<IPCClient> rpc;
};

#endif // MAINCTRL_H
