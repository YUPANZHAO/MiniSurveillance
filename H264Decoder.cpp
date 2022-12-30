#include "H264Decoder.h"

H264Decoder::H264Decoder()
: frameCallBack(nullptr)
, buf(nullptr) {
    packet = av_packet_alloc();
    if(!packet) {
        debug("av_packet_alloc failed");
        return;
    }

    codec = (AVCodec*) avcodec_find_decoder(AV_CODEC_ID_H264);
    if(!codec) {
        debug("avcodec_find_decoder failed");
        return;
    }

    codec_parser_ctx = av_parser_init(codec->id);
    if(!codec_parser_ctx) {
        debug("av_parser_init failed");
        return;
    }

    codec_ctx = avcodec_alloc_context3(codec);
    if(!codec_ctx) {
        debug("avcodec_alloc_context3 failed");
        return;
    }

    codec_ctx->pix_fmt = AV_PIX_FMT_YUV420P;
    codec_ctx->codec_id = AV_CODEC_ID_H264;
    codec_ctx->codec_type = AVMEDIA_TYPE_VIDEO;

    if(avcodec_open2(codec_ctx, codec, NULL) < 0) {
        debug("can not open codec");
        return;
    }

    frame = av_frame_alloc();
    if(!frame) {
        debug("av_frame_alloc failed");
        return;
    }

    buf = new BYTE[MAX_BUF_SIZE];
}

H264Decoder::~H264Decoder() {
    if(frame)
    {
       av_frame_free(&frame);
       frame = NULL;
    }

    if(codec_parser_ctx)
    {
       av_parser_close(codec_parser_ctx);
       codec_parser_ctx = NULL;
    }

    if(codec_ctx)
    {
       avcodec_close(codec_ctx);
       avcodec_free_context(&codec_ctx);
       codec_ctx = NULL;
    }

    if(buf) {
        delete [] buf;
        buf = nullptr;
    }
}

void H264Decoder::setFrameCallBack(FrameCallBack cb) {
    this->frameCallBack = cb;
}

void H264Decoder::receiveOneNalu(NALU_TYPE type, BYTE* data, UINT32 len) {
    UINT32 ret;
    while(len > 0) {
        ret = av_parser_parse2(codec_parser_ctx, codec_ctx, &packet->data, &packet->size,
                         data, len, AV_NOPTS_VALUE, AV_NOPTS_VALUE, AV_NOPTS_VALUE);

        if(ret < 0) {
            debug("Error while parsing");
            exit(1);
        }

        // debug(len, ret);

        data += ret;
        len -= ret;

        if(!packet->size) {
            // debug("packet size is zero");
            continue;
        }

        if(avcodec_send_packet(codec_ctx, packet) < 0) {
            debug("avcodec_send_packet failed");
            exit(1);
        }

        while(ret >= 0) {
            ret = avcodec_receive_frame(codec_ctx, frame);
            if(ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
                break;
            }else if(ret < 0) {
                debug("Error during decoding");
                exit(1);
            }
            UINT32 width = frame->width;
            UINT32 height = frame->height;
//            debug("»ñµÃÒ»Ö¡", width, height);
            int ysize = width * height;
            int uvsize = ysize >> 2;
            int bufsize = ysize + (uvsize << 1);
            memcpy(buf, frame->data[0], ysize);
            memcpy(buf + ysize, frame->data[1], uvsize);
            memcpy(buf + ysize + uvsize, frame->data[2], uvsize);
            frameCallBack(buf, bufsize, width, height, codec_ctx->pix_fmt);
        }
    }
}
