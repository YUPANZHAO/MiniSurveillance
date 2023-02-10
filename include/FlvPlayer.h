#ifndef FLVPLAYER_H
#define FLVPLAYER_H

#include <iostream>
#include <string>
#include <unistd.h>
#include <fcntl.h>
#include <memory>
#include <thread>
#include "debug.h"
#include <functional>
#include "types.h"
#include <mutex>

using namespace std;
using namespace ZYP;

class FlvPlayer {

public:

    using VideoCallBack = function<void(NALU_TYPE,BYTE*,UINT32,bool)>;
    using AudioCallBack = function<void(AUDIO_TYPE,AUDIO_CHANNEL_TYPE,BYTE*,UINT32,bool)>;

public:
    FlvPlayer();
    ~FlvPlayer();

    void set_file_path(const string & file_path);
    void start();
    void stop();
    void pause();
    void step_one_frame_forward();
    void step_one_frame_backward();
    void step_by_seconds(int sec);

    void set_video_callback(VideoCallBack cb);
    void set_audio_callback(AudioCallBack cb);
    void sleep_once(int fps);

private:

    static const int FLV_HEADER_LENGTH = 9;

    static const int TAG_HEADER_SIZE = 11;
    static const int TAG_DATA_SIZE = 1024 * 1024;

    enum class TAG_TYPE {
        AUDIO = 0x08,
        VIDEO = 0x09,
        SCRIPT_DATA = 0x12
    };

    char flv_header[FLV_HEADER_LENGTH] = { 0x46, 0x4C, 0x56, 0x01, 0x00, 0x00, 0x00, 0x00, 0x09 };

    string file_path;
    int file_fd;

    mutex file_mutex;

    UINT32 fps;

    bool is_playing;
    bool is_pause;
    bool need_sleep;
    bool need_I_frame;
    bool is_regulating;
    bool request_step;
    bool step_one_frame;

    int regulate_tag_count;

    unique_ptr<thread> feed_thread;

    long cur_idx;
    long total_bytes;

    BYTE* tag_header;
    BYTE* tag_data;
    UINT32 buf_len;

    VideoCallBack video_callback;
    AudioCallBack audio_callback;

private:
    void feed_task();

    bool is_flv_header(BYTE* buf);

    void handle_tag(TAG_TYPE type, BYTE* buf, UINT32 len);
    void handle_video_tag_data(BYTE* buf, UINT32 len);
    void handle_sps_pps(BYTE* buf, UINT32 len);
    void handle_frame(BYTE* buf, UINT32 len);
    void handle_audio_tag_data(BYTE* buf, UINT32 len);
    void handle_audio_decode_info(BYTE* buf, UINT32 len);
    void handle_audio_data(BYTE* buf, UINT32 len);

    void step_by_frame(int count);
    // return: is I frame?
    bool move(int tag_count, TAG_TYPE& type);
    void move_forward(int tag_count);
    void move_backward(int tag_count);
};

#endif // FLVPLAYER_H
