#ifndef FRAMEPROVIDER_H
#define FRAMEPROVIDER_H

#include <QObject>
#include <QVideoSurfaceFormat>
#include <QAbstractVideoSurface>
#include "debug.h"

using namespace ZYP;

class FrameProvider : public QObject {

    Q_OBJECT
    Q_PROPERTY(QAbstractVideoSurface* videoSurface READ videoSurface WRITE setVideoSurface)

public:
    FrameProvider();
    ~FrameProvider();

public:
    QAbstractVideoSurface *videoSurface();
    void setVideoSurface(QAbstractVideoSurface* surface);

public:
    void setFormat(int width, int heigth, QVideoFrame::PixelFormat format);

public slots:
    void onNewFrameReceived(const QVideoFrame & frame);

private:
    QAbstractVideoSurface* _surface;
    QVideoSurfaceFormat _format;

};

#endif // FRAMEPROVIDER_H
