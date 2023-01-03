#include "AACDecoder.h"

AACDecoder::AACDecoder()
: FFmpeg_Decoder(AV_CODEC_ID_AAC)
, pcmCallBack(nullptr) {
    buf = new BYTE [MAX_BUF_SIZE];
}

AACDecoder::~AACDecoder() {
    if(buf) {
        delete [] buf;
        buf = nullptr;
    }
}

void AACDecoder::setPCMCallBack(PCMCallBack callback) {
    this->pcmCallBack = callback;
}

void AACDecoder::handleOneFrame(AVFrame* frame) {
    UINT32 data_size = av_get_bytes_per_sample(codec_ctx->sample_fmt);
    if(data_size < 0) {
        debug("failed to calculate data size");
        return;
    }
    UINT32 len = 0;
    for(int i=0; i < frame->nb_samples; ++i)
        for(int ch=0; ch < codec_ctx->channels; ++ch) {
            memcpy(buf + len, frame->data[ch] + data_size * i, data_size);
            len += data_size;
        }
    pcmCallBack(buf, len);
}
