#include "VideoCtrl.h"

VideoCtrl::VideoCtrl()
: videoCapture(make_unique<VideoCapture>())
, video_decoder(make_unique<H264Decoder>())
, provider(make_unique<FrameProvider>())
, frame(nullptr)
, audio_decoder(make_unique<AACDecoder>())
, is_playing(false)
, audio(nullptr)
, audio_io(nullptr) {
    // 信号槽绑定
    connect(this, &VideoCtrl::sendOneFrame, provider.get(), &FrameProvider::onNewFrameReceived);
    // RTMP拉流，获取Nalu单元
    videoCapture->setNaluCB([this](NALU_TYPE type, BYTE* data, UINT32 len) {
        if(type == NALU_TYPE_IDR) {
            BYTE nalu_header [] = { 0x00, 0x00, 0x01 };
            this->video_decoder->receiveData(nalu_header, 3);
        }else {
            BYTE nalu_header [] = { 0x00, 0x00, 0x00, 0x01 };
            this->video_decoder->receiveData(nalu_header, 4);
        }
//        debug("type:", type, "len:", len);
        this->video_decoder->receiveData(data, len);
    });
    // 获取音频数据
    videoCapture->setAudioCB([this](AUDIO_TYPE type, AUDIO_CHANNEL_TYPE channelCfg, BYTE* data, UINT32 len) {
        debug("audio data, type:", type, "channelCfg:", channelCfg, "len:", len);
        if(type == AUDIO_INFO) {
            UINT32 num0 = data[0] & 0x7;
            UINT32 num1 = data[1] & 0x80;
            UINT32 sampleIdx = ((num0 << 1) | (num1 >> 7));
            UINT32 channelsIdx = ((data[1] & 0x78) >> 3);
            debug("get one audio info, sampleIdx:", sampleIdx, "channelsIdx:", channelsIdx);
            BYTE temp [] = { 0xFF, 0xF1, 0x40, 0x00, 0x00, 0x1F, 0xFC };
            temp[2] |= (sampleIdx << 2) & 0x3C;
            temp[2] |= ((channelsIdx & 0x4) >> 2) & 0x1;
            temp[3] |= ((channelsIdx & 0x3) << 6) & 0xC0;
            memcpy(adts_header, temp, 7);
            // 初始化播放器
            audioFormat.setSampleRate(sampleIdx == 4 ? 44100 : 8000);
            audioFormat.setSampleSize(32);
            audioFormat.setChannelCount(channelsIdx == 1 ? 1 : 2);
            audioFormat.setCodec("audio/pcm");
            audioFormat.setByteOrder(QAudioFormat::LittleEndian);
            audioFormat.setSampleType(QAudioFormat::SampleType::Float);
            audio = new QAudioOutput(audioFormat);
            audio_io = audio->start();
        }else {
            UINT32 all_len = 7 + len;
            BYTE num0 = ((all_len & 0x1800) >> 11) & 0x3;
            BYTE num1 = ((all_len & 0x7F8) >> 3) & 0xFF;
            BYTE num2 = ((all_len & 0x7) << 5) & 0xE0;
            adts_header[3] &= 0xFC;
            adts_header[4] &= 0x00;
            adts_header[5] &= 0x1F;
            adts_header[3] |= num0;
            adts_header[4] |= num1;
            adts_header[5] |= num2;
            this->audio_decoder->receiveData(adts_header, 7);
            this->audio_decoder->receiveData(data, len);
        }
    });
    // H264 解码，获取帧原始数据
    video_decoder->setFrameCallBack([this](BYTE* data, UINT32 len, UINT32 width, UINT32 height, AVPixelFormat pix_fmt) {
        if(!frame) {
            frame = make_unique<QVideoFrame>(len, QSize(width, height), width, convertFormat(pix_fmt));
        }
        if(frame->map(QAbstractVideoBuffer::WriteOnly)) {
            memcpy(frame->bits(), data, len);
            frame->unmap();
            emit this->sendOneFrame(*frame.get());
        }
    });
    // AAC 解码，获取 PCM 数据
    audio_decoder->setPCMCallBack([this](BYTE* data, UINT32 len) {
        debug("获取到一帧PCM, len:", len);
        if(audio)
            audio_io->write((const char*)data, len);
    });
}

VideoCtrl::~VideoCtrl() {
}

bool VideoCtrl::play(const QString url) {
    if(is_playing) return false;
    is_playing = true;
    // 设置流地址
    videoCapture->setRtmpURL(url.toStdString());
    // 开始拉流
    bool ret = videoCapture->start();
    if(!ret) {
        is_playing = false;
    }
    return ret;
}

void VideoCtrl::stop() {
    if(!is_playing) return;
    videoCapture->stop();
    if(audio) {
        audio->stop();
        delete audio;
        audio = nullptr;
        audio_io = nullptr;
    }
    frame = nullptr;
    is_playing = false;
}

FrameProvider* VideoCtrl::frameProvider() {
    return provider.get();
}

void VideoCtrl::setFrameProvider(FrameProvider* provider) {

}

auto VideoCtrl::convertFormat(AVPixelFormat pix_fmt) -> QVideoFrame::PixelFormat {
    switch (pix_fmt) {
    case AV_PIX_FMT_YUV444P:    return QVideoFrame::PixelFormat::Format_YUV444;
    case AV_PIX_FMT_YUV422P:    return QVideoFrame::PixelFormat::Format_YUV422P;
    case AV_PIX_FMT_YUV420P:    return QVideoFrame::PixelFormat::Format_YUV420P;
    case AV_PIX_FMT_YUYV422:    return QVideoFrame::PixelFormat::Format_YUYV;
    case AV_PIX_FMT_UYVY422:    return QVideoFrame::PixelFormat::Format_UYVY;
    case AV_PIX_FMT_BGR24:      return QVideoFrame::PixelFormat::Format_BGR24;
    case AV_PIX_FMT_BGR32:      return QVideoFrame::PixelFormat::Format_BGR32;
    case AV_PIX_FMT_RGB24:      return QVideoFrame::PixelFormat::Format_RGB24;
    case AV_PIX_FMT_RGB32:      return QVideoFrame::PixelFormat::Format_RGB32;
    case AV_PIX_FMT_BGR555:     return QVideoFrame::PixelFormat::Format_BGR555;
    case AV_PIX_FMT_BGR565:     return QVideoFrame::PixelFormat::Format_BGR565;
    case AV_PIX_FMT_NV12:       return QVideoFrame::PixelFormat::Format_NV12;
    case AV_PIX_FMT_NV21:       return QVideoFrame::PixelFormat::Format_NV21;
    default: break;
    }
    return QVideoFrame::PixelFormat::NPixelFormats;
}
