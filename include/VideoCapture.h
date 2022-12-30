#ifndef VIDEOCAPTURE_H
#define VIDEOCAPTURE_H

#include "librtmp/rtmp.h"
#include <functional>
#include "types.h"
#include <memory>
#include <thread>
#include "debug.h"
#include <windows.h>

using namespace std;
using namespace ZYP;

class VideoCapture {

    using NaluCallBack = function<void(NALU_TYPE,BYTE*,UINT32)>;

public:
    VideoCapture();
    ~VideoCapture();

public:
    void setNaluCB(NaluCallBack cb);
    void setRtmpURL(const string & url);
    bool start();
    void stop();

private:
    bool init();
    void unInit();
    void pull();

    void handle_packet(RTMPPacket* packet);
    void handle_sps_pps_packet(RTMPPacket* packet);
    void handle_nalu_frame_packet(RTMPPacket* packet);

    NaluCallBack naluCallBack;
    string rtmp_url;
    shared_ptr<thread> p_rtmp_pull_thread;
    bool is_pulling;
    RTMP* rtmp;
    RTMPPacket* packet;
};

#endif // VIDEOCAPTURE_H
