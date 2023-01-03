#ifndef VIDEOSENDER_H
#define VIDEOSENDER_H

#include <QObject>
#include <QVideoFrame>
#include "CameraFilter.h"
#include "VideoChannel.h"
#include <thread>
#include <memory>
#include "librtmp/rtmp.h"
#include "SafeQueue.hpp"

using namespace std;

class VideoSender : public QObject {

    Q_OBJECT
    Q_PROPERTY(CameraFilter* cameraSource READ cameraSource WRITE setCameraSource);

public:
    VideoSender();
    ~VideoSender();

    CameraFilter* cameraSource();
    void setCameraSource(CameraFilter* filter);

public slots:
    void receiveOneFrame(const QVideoFrame & frame);

public:
    Q_INVOKABLE void setRtmpUrl(const QString & url);
    Q_INVOKABLE void push();
    Q_INVOKABLE void stop();

private:
    CameraFilter* source;

    SafeQueue<RTMPPacket*> packets;
    uint32_t push_start_time;
    shared_ptr<std::thread> rtmp_push_thread;
    shared_ptr<VideoChannel> videoChannel;
    bool is_pushing;
    string rtmp_push_url;

};

#endif // VIDEOSENDER_H
