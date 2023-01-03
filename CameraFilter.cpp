#include "CameraFilter.h"

CameraFilter::CameraFilter(QObject *parent) : _qmlCamera(nullptr)
{
    Q_UNUSED(parent)
}

QObject *CameraFilter::getQmlCamera() const
{
    return _qmlCamera;
}

void CameraFilter::setQmlCamera(QObject *qmlCamera)
{
    this->_qmlCamera = qmlCamera;
    if(_qmlCamera)
    {
        _camera = qvariant_cast<QCamera*>(_qmlCamera->property("mediaObject"));

        QCameraViewfinderSettings cameraSettings = _camera->viewfinderSettings();
        cameraSettings.setPixelFormat(QVideoFrame::Format_YUYV);
        cameraSettings.setMinimumFrameRate(15);
        cameraSettings.setMaximumFrameRate(15);
        cameraSettings.setResolution(QSize(640, 360));
        _camera->setViewfinderSettings(cameraSettings);

        if(_probe.setSource(_camera))
            connect(&_probe, SIGNAL(videoFrameProbed(const QVideoFrame &)), this, SLOT(_onProcssFram(const QVideoFrame &)));
    }
}

void CameraFilter::_onProcssFram(const QVideoFrame &frame)
{
    if(!frame.isValid())
        return;
    QVideoFrame cloneFrame(frame);
//    qDebug() << "current pix fmt:" << cloneFrame.pixelFormat();
//    qDebug() << "width:" << cloneFrame.width() << "height:" << cloneFrame.height();
    if(cloneFrame.map(QAbstractVideoBuffer::WriteOnly)) {
//        qDebug() << "提交一帧 len:", cloneFrame.bytesPerLine();
        emit getOneFrame(cloneFrame);
        cloneFrame.unmap();
    }
}
