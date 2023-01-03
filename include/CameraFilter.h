#ifndef CAMERAFILTER_H
#define CAMERAFILTER_H

#include <QObject>
#include <QVideoProbe>
#include <QCamera>
#include <thread>
#include <windows.h>

class CameraFilter : public QObject {

    Q_OBJECT
    Q_PROPERTY(QObject* qmlCamera READ getQmlCamera WRITE setQmlCamera)

public:
    explicit CameraFilter(QObject *parent = nullptr);

    QObject *getQmlCamera() const;
    void setQmlCamera(QObject *qmlCamera);

signals:
    void getOneFrame(const QVideoFrame &);

private slots:
    void _onProcssFram(const QVideoFrame &);

private:
    QObject *_qmlCamera = nullptr;
    QCamera *_camera = nullptr;
    QVideoProbe _probe;

};

#endif // CAMERAFILTER_H
