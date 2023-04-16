#ifndef FFMPEG_ENCODE_H
#define FFMPEG_ENCODE_H

#include "debug.h"
#include "types.h"
#include <functional>

extern "C" {
    #include <libavcodec/avcodec.h>
    #include <libavformat/avformat.h>
    #include <libswscale/swscale.h>
    #include <libavutil/imgutils.h>
    #include <libavutil/opt.h>
}

using namespace std;
using namespace ZYP;

class FFmpeg_Encoder {
    using DataCallBack = function<void(BYTE* data, UINT32 len)>;

public:
    FFmpeg_Encoder(UINT32 width, UINT32 height, UINT32 fps, AVPixelFormat pix_fmt);
    ~FFmpeg_Encoder();

public:
    void receiveData(BYTE* data, UINT32 len, UINT32 width, UINT32 height, AVPixelFormat pix_fmt);
    void setDataCallBack(DataCallBack cb);

private:
    DataCallBack _data_cb;

    AVCodec * _codec;
    AVCodecContext * _codecCtx;
    AVFrame * _frame;

    UINT32 count;
};

#endif // FFMPEG_ENCODE_H
