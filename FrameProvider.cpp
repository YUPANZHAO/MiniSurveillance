#include "FrameProvider.h"
#include <QDebug>

FrameProvider::FrameProvider()
    : _surface(nullptr) {

}

FrameProvider::~FrameProvider() {

}

QAbstractVideoSurface* FrameProvider::videoSurface() {
    return _surface;
}

void FrameProvider::setVideoSurface(QAbstractVideoSurface* surface) {
    if(_surface && _surface != surface && _surface->isActive()) {
        _surface->stop();
    }

    _surface = surface;

    if(_surface && _format.isValid()) {
        _format = _surface->nearestFormat(_format);
        _surface->start(_format);
    }
}

void FrameProvider::setFormat(int width, int heigth, QVideoFrame::PixelFormat format) {
    QSize size(width, heigth);
    QVideoSurfaceFormat formats(size, format);
    _format = formats;

    if (_surface) {
        if (_surface->isActive()) {
            _surface->stop();
        }
        _format = _surface->nearestFormat(_format);
        _surface->start(_format);
    }
}

void FrameProvider::onNewFrameReceived(const QVideoFrame & frame) {
//    debug("��ȡ��һ֡����");
    setFormat(frame.width(), frame.height(), frame.pixelFormat());
    if(_surface) {
//        debug("present һ֡����");
        bool res = _surface->present(frame);
//        debug("���ͽ����", res);
    }
}
