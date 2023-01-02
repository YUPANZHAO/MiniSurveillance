#include "FFmpeg_Decoder.h"

FFmpeg_Decoder::FFmpeg_Decoder(AVCodecID codec_id)
: codec_id(codec_id) {
    packet = av_packet_alloc();
    if(!packet) {
        debug("av_packet_alloc failed");
        return;
    }

    codec = (AVCodec*) avcodec_find_decoder(this->codec_id);
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

    if(avcodec_open2(codec_ctx, codec, NULL) < 0) {
        debug("can not open codec");
        return;
    }

    frame = av_frame_alloc();
    if(!frame) {
        debug("av_frame_alloc failed");
        return;
    }
}

FFmpeg_Decoder::~FFmpeg_Decoder() {
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
}

void FFmpeg_Decoder::receiveData(BYTE* data, UINT32 len) {
    UINT32 ret;
    while(len > 0) {
        ret = av_parser_parse2(codec_parser_ctx, codec_ctx, &packet->data, &packet->size,
                         data, len, AV_NOPTS_VALUE, AV_NOPTS_VALUE, 0);

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

        int errcode = avcodec_send_packet(codec_ctx, packet);
        if(errcode < 0) {
            debug("avcodec_send_packet failed errcode:", errcode);
            char bufff[1024];
            av_strerror(errcode, bufff, 1023);
            debug("err_msg", bufff);
            exit(1);
        }

        while(ret >= 0) {
            ret = avcodec_receive_frame(codec_ctx, frame);
            if(ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
                break;
            }else if(ret < 0) {
                debug("Error during decoding");
                break;
            }
            handleOneFrame(frame);
        }
    }
}
