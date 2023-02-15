#ifndef VIDEOCTRL_H
#define VIDEOCTRL_H

#include <QObject>
#include "VideoCapture.h"
#include <memory>
#include "debug.h"
#include "H264Decoder.h"
#include <QVideoFrame>
#include "FrameProvider.h"
#include "AACDecoder.h"
#include <QAudioFormat>
#include <QAudioOutput>
#include "Crypto.hpp"

using namespace ZYP;
using namespace std;

class VideoCtrl : public QObject {

    Q_OBJECT
    Q_PROPERTY(FrameProvider* frameProvider READ frameProvider WRITE setFrameProvider)

public:
    VideoCtrl();
    ~VideoCtrl();

public:
    Q_INVOKABLE bool play(const QString url, const QString encryption);
    Q_INVOKABLE void stop();
    Q_INVOKABLE void playAudio();
    Q_INVOKABLE void stopAudio();

    FrameProvider* frameProvider();
    void setFrameProvider(FrameProvider* provider);

signals:
    void sendOneFrame(const QVideoFrame & frame);

private:
    unique_ptr<VideoCapture> videoCapture;
    unique_ptr<H264Decoder> video_decoder;
    unique_ptr<FrameProvider> provider;
    unique_ptr<QVideoFrame> frame;
    unique_ptr<AACDecoder> audio_decoder;

    bool is_playing;
    bool is_playing_audio;

    BYTE adts_header[7];
    QAudioFormat audioFormat;
    QAudioOutput* audio;
    QIODevice* audio_io;

    string encryption;

private:
    auto convertFormat(AVPixelFormat pix_fmt) -> QVideoFrame::PixelFormat;

};

#endif // VIDEOCTRL_H
