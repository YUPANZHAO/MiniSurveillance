#include "VideoCtrl.h"

VideoCtrl::VideoCtrl()
: videoCapture(make_unique<VideoCapture>())
, decoder(make_unique<H264Decoder>())
, provider(make_unique<FrameProvider>())
, frame(nullptr)
, is_playing(false) {
    // 信号槽绑定
    connect(this, &VideoCtrl::sendOneFrame, provider.get(), &FrameProvider::onNewFrameReceived);
}

VideoCtrl::~VideoCtrl() {
}

bool VideoCtrl::play(const QString url) {
    if(is_playing) return false;
    is_playing = true;
    // 设置流地址
    videoCapture->setRtmpURL(url.toStdString());
    // RTMP拉流，获取Nalu单元
    videoCapture->setNaluCB([this](NALU_TYPE type, BYTE* data, UINT32 len) {
        if(type == NALU_TYPE_IDR) {
            BYTE nalu_header [] = { 0x00, 0x00, 0x01 };
            this->decoder->receiveOneNalu(type, nalu_header, 3);
        }else {
            BYTE nalu_header [] = { 0x00, 0x00, 0x00, 0x01 };
            this->decoder->receiveOneNalu(type, nalu_header, 4);
        }
//        debug("type:", type, "len:", len);
        this->decoder->receiveOneNalu(type, data, len);
    });
    // H264 解码，获取帧原始数据
    decoder->setFrameCallBack([this](BYTE* data, UINT32 len, UINT32 width, UINT32 height, AVPixelFormat pix_fmt) {
        if(!frame) {
            frame = make_unique<QVideoFrame>(len, QSize(width, height), width, convertFormat(pix_fmt));
        }
        if(frame->map(QAbstractVideoBuffer::WriteOnly)) {
            memcpy(frame->bits(), data, len);
            frame->unmap();
            emit this->sendOneFrame(*frame.get());
        }
    });
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
