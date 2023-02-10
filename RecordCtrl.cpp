#include "RecordCtrl.h"

RecordCtrl::RecordCtrl(QObject *parent)
: QObject{parent}
, frame(nullptr)
, is_playing_audio(false)
, audio(nullptr) {
    // 信号槽绑定
    provider = make_unique<FrameProvider>();
    connect(this, &RecordCtrl::sendOneFrame, provider.get(), &FrameProvider::onNewFrameReceived);
    // 设置录像解码流程
    flv_player = make_unique<FlvPlayer>();
    h264_decoder = make_unique<H264Decoder>();
    aac_decoder = make_unique<AACDecoder>();
    flv_player->set_video_callback([this](NALU_TYPE type, BYTE* buf, UINT32 len, bool play) {
        this->is_play_able = play;
        if(type == NALU_TYPE_IDR) {
            BYTE nalu_header [] = { 0x00, 0x00, 0x01 };
            this->h264_decoder->receiveData(nalu_header, 3);
        }else {
            BYTE nalu_header [] = { 0x00, 0x00, 0x00, 0x01 };
            this->h264_decoder->receiveData(nalu_header, 4);
        }
        this->h264_decoder->receiveData(buf , len);
    });
    flv_player->set_audio_callback([this](AUDIO_TYPE type, AUDIO_CHANNEL_TYPE channelCfg, BYTE* data, UINT32 len, bool play) {
        this->is_play_able = play;
        if(type == AUDIO_INFO) {
            if(this->audio) return;
            UINT32 num0 = data[0] & 0x7;
            UINT32 num1 = data[1] & 0x80;
            UINT32 sampleIdx = ((num0 << 1) | (num1 >> 7));
            UINT32 channelsIdx = ((data[1] & 0x78) >> 3);
            BYTE temp [] = { 0xFF, 0xF1, 0x40, 0x00, 0x00, 0x1F, 0xFC };
            temp[2] |= (sampleIdx << 2) & 0x3C;
            temp[2] |= ((channelsIdx & 0x4) >> 2) & 0x1;
            temp[3] |= ((channelsIdx & 0x3) << 6) & 0xC0;
            memcpy(this->adts_header, temp, 7);
            // 初始化播放器
            this->audioFormat.setSampleRate(sampleIdx == 4 ? 44100 : 8000);
            this->audioFormat.setSampleSize(32);
            this->audioFormat.setChannelCount(channelsIdx == 1 ? 1 : 2);
            this->audioFormat.setCodec("audio/pcm");
            this->audioFormat.setByteOrder(QAudioFormat::LittleEndian);
            this->audioFormat.setSampleType(QAudioFormat::SampleType::Float);
            this->audio = new QAudioOutput(audioFormat);
            this->audio_io = this->audio->start();
        }else {
            if(!this->is_playing_audio || !this->audio) return;
            UINT32 all_len = 7 + len;
            BYTE num0 = ((all_len & 0x1800) >> 11) & 0x3;
            BYTE num1 = ((all_len & 0x7F8) >> 3) & 0xFF;
            BYTE num2 = ((all_len & 0x7) << 5) & 0xE0;
            this->adts_header[3] &= 0xFC;
            this->adts_header[4] &= 0x00;
            this->adts_header[5] &= 0x1F;
            this->adts_header[3] |= num0;
            this->adts_header[4] |= num1;
            this->adts_header[5] |= num2;
            this->aac_decoder->receiveData(this->adts_header, 7);
            this->aac_decoder->receiveData(data, len);
        }
    });
    h264_decoder->setFrameCallBack([this](BYTE* data, UINT32 len, UINT32 width, UINT32 height, UINT32 fps, AVPixelFormat pix_fmt) {
        if(!this->frame) {
            this->frame = make_unique<QVideoFrame>(len, QSize(width, height), width, convertFormat(pix_fmt));
        }
        if(this->is_play_able && this->frame->map(QAbstractVideoBuffer::WriteOnly)) {
            memcpy(this->frame->bits(), data, len);
            this->frame->unmap();
            emit this->sendOneFrame(*(this->frame.get()));
            this->flv_player->sleep_once(fps);
        }
    });
    aac_decoder->setPCMCallBack([this](BYTE* data, UINT32 len) {
        if(this->is_play_able && this->audio)
            this->audio_io->write((const char*)data, len);
    });
}

FrameProvider* RecordCtrl::frameProvider() {
    return provider.get();
}

void RecordCtrl::setFrameProvider(FrameProvider* provider) {

}

void RecordCtrl::play(const QString file_path) {
    debug("play btn clicked", file_path.toStdString());
    flv_player->set_file_path(file_path.toStdString());
    is_playing_audio = true;
    flv_player->start();
}

void RecordCtrl::stop() {
    flv_player->stop();
    provider->flush();
}

void RecordCtrl::pause() {
    flv_player->pause();
}

void RecordCtrl::step_by_second(int sec) {
    flv_player->step_by_seconds(sec);
}

void RecordCtrl::step_one_frame_forward() {
    flv_player->step_one_frame_forward();
}

void RecordCtrl::step_one_frame_backward() {
    flv_player->step_one_frame_backward();
}

auto RecordCtrl::convertFormat(AVPixelFormat pix_fmt) -> QVideoFrame::PixelFormat {
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
