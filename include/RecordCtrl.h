#ifndef RECORDCTRL_H
#define RECORDCTRL_H

#include <QObject>
#include <memory>
#include "FrameProvider.h"
#include "FlvPlayer.h"
#include "H264Decoder.h"
#include "AACDecoder.h"
#include <QAudioFormat>
#include <QAudioOutput>
#include "Crypto.hpp"

using namespace  std;

class RecordCtrl : public QObject {
    Q_OBJECT

    Q_PROPERTY(FrameProvider* frameProvider READ frameProvider WRITE setFrameProvider)

public:
    explicit RecordCtrl(QObject *parent = nullptr);

    FrameProvider* frameProvider();
    void setFrameProvider(FrameProvider* provider);

    Q_INVOKABLE void play(const QString file_path, const QString encryption);
    Q_INVOKABLE void stop();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void step_by_second(int sec);
    Q_INVOKABLE void step_one_frame_forward();
    Q_INVOKABLE void step_one_frame_backward();

signals:
    void sendOneFrame(const QVideoFrame & frame);

private:
    unique_ptr<FrameProvider> provider;
    unique_ptr<FlvPlayer> flv_player;
    unique_ptr<H264Decoder> h264_decoder;
    unique_ptr<AACDecoder> aac_decoder;
    unique_ptr<QVideoFrame> frame;

    bool is_playing_audio;
    bool is_play_able;

    string encryption;

    BYTE adts_header[7];
    QAudioFormat audioFormat;
    QAudioOutput* audio;
    QIODevice* audio_io;

    auto convertFormat(AVPixelFormat pix_fmt) -> QVideoFrame::PixelFormat;

};

#endif // RECORDCTRL_H
