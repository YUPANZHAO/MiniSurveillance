#ifndef VIDEOCTRL_H
#define VIDEOCTRL_H

#include <QObject>
#include "VideoCapture.h"
#include <memory>
#include "debug.h"
#include "H264Decoder.h"
#include <QVideoFrame>
#include "FrameProvider.h"

using namespace ZYP;
using namespace std;

class VideoCtrl : public QObject {

    Q_OBJECT
    Q_PROPERTY(FrameProvider* frameProvider READ frameProvider WRITE setFrameProvider)

public:
    VideoCtrl();
    ~VideoCtrl();

public:
    Q_INVOKABLE bool play(const QString url);
    Q_INVOKABLE void stop();

    FrameProvider* frameProvider();
    void setFrameProvider(FrameProvider* provider);

signals:
    void sendOneFrame(const QVideoFrame & frame);

private:
    unique_ptr<VideoCapture> videoCapture;
    unique_ptr<H264Decoder> decoder;
    unique_ptr<FrameProvider> provider;
    unique_ptr<QVideoFrame> frame;

    bool is_playing;

private:
    auto convertFormat(AVPixelFormat pix_fmt) -> QVideoFrame::PixelFormat;

};

#endif // VIDEOCTRL_H
