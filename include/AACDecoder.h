#ifndef AACDECODER_H
#define AACDECODER_H

#include "debug.h"
#include "types.h"
#include <memory.h>
#include <functional>
#include "FFmpeg_Decoder.h"

using namespace ZYP;
using namespace std;

class AACDecoder : public FFmpeg_Decoder {

    using PCMCallBack = function<void(BYTE*,UINT32)>;

    static const int MAX_BUF_SIZE = 1024 * 1024;

public:
    AACDecoder();
    ~AACDecoder();

public:
    void setPCMCallBack(PCMCallBack callback);

private:
    void handleOneFrame(AVFrame* frame);

private:
    PCMCallBack pcmCallBack;
    BYTE* buf;

};

#endif // AACDECODER_H
