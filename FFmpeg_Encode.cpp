#include "FFmpeg_Encode.h"

FFmpeg_Encoder::FFmpeg_Encoder(UINT32 width, UINT32 height, UINT32 fps, AVPixelFormat pix_fmt) {
    debug("init _codec");
    _codec = (AVCodec*) avcodec_find_encoder(AV_CODEC_ID_H264);
    if(!_codec) {
        debug("_codec init failed");
        return;
    }
    debug("init _codecCtx");
    _codecCtx = avcodec_alloc_context3(_codec);
    if(!_codecCtx) {
        debug("_codecCtx init failed");
        return;
    }
    _codecCtx->width = width;
    _codecCtx->height = height;
    _codecCtx->time_base.num = 1;
    _codecCtx->time_base.den = fps;
    _codecCtx->pix_fmt = pix_fmt;

    av_opt_set(_codecCtx->priv_data, "tune", "zerolatency", 0);

    debug("avcodec_open2");
    int ret = avcodec_open2(_codecCtx, _codec, NULL);
    if(ret < 0) {
        debug("avcodec_open2 failed");
        return;
    }

    debug("av_frame_alloc");
    _frame = av_frame_alloc();
    _frame->format = pix_fmt;
    _frame->width = width;
    _frame->height = height;
    debug("av_frame_get_buffer");
    ret = av_frame_get_buffer(_frame, 32);
    if(ret < 0) {
        debug("av_frame_get_buffer failed");
        return;
    }

    count = 0;
}

FFmpeg_Encoder::~FFmpeg_Encoder() {
    if(_codecCtx) {
        debug("avcodec_close");
        avcodec_close(_codecCtx);
        debug("avcodec_free_context");
        avcodec_free_context(&_codecCtx);
    }
    if(_frame) {
        debug("av_frame_free");
        av_frame_free(&_frame);
    }
}

void FFmpeg_Encoder::receiveData(BYTE* data, UINT32 len, UINT32 width, UINT32 height, AVPixelFormat pix_fmt) {
    av_image_fill_arrays(_frame->data, _frame->linesize, data, pix_fmt, width, height, 1);
    _frame->pts = count++ * (_codecCtx->time_base.num * 1000 / _codecCtx->time_base.den);
    int ret = avcodec_send_frame(_codecCtx, _frame);
    if(ret != 0) return;
    while(true) {
        AVPacket * pkt = av_packet_alloc();
        ret = avcodec_receive_packet(_codecCtx, pkt);
        if(ret != 0) break;
        _data_cb(pkt->data, pkt->size);
        av_packet_free(&pkt);
    }
}

void FFmpeg_Encoder::setDataCallBack(DataCallBack cb) {
    _data_cb = cb;
}
