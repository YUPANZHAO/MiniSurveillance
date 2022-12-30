#ifndef H264DECODER_H
#define H264DECODER_H

#include "debug.h"
#include "types.h"
#include <functional>

extern "C" {
    #include <libavcodec/avcodec.h>
}

using namespace std;
using namespace ZYP;

class H264Decoder {

    // data len width height pix_fmt
    using FrameCallBack = function<void(BYTE*,UINT32,UINT32,UINT32,AVPixelFormat)>;

    static const int MAX_BUF_SIZE = 1920 * 1080 * 3 / 2;

public:
    H264Decoder();
    ~H264Decoder();

public:
    void setFrameCallBack(FrameCallBack cb);
    void receiveOneNalu(NALU_TYPE type, BYTE* data, UINT32 len);

private:
    FrameCallBack frameCallBack;

    AVCodec* codec = nullptr;
    AVCodecParserContext* codec_parser_ctx = nullptr;
    AVCodecContext* codec_ctx = nullptr;
    AVFrame* frame = nullptr;
    AVPacket* packet = nullptr;

    BYTE* buf;

};

#endif // H264DECODER_H
