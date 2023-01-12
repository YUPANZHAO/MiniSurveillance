#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "librtmp/rtmp.h"
#include "debug.h"
#include "VideoCtrl.h"
#include "CameraFilter.h"
#include "VideoSender.h"
#include "grpcpp/grpcpp.h"

int main(int argc, char *argv[])
{
    // 初始化网络环境
    WORD version;
    WSADATA wsaData;
    version = MAKEWORD(1, 1);
    WSAStartup(version, &wsaData);

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    qmlRegisterType<VideoCtrl>("VideoCtrl", 1, 0, "VideoCtrl");
    qmlRegisterType<CameraFilter>("CameraFilter", 1, 0, "CameraFilter");
    qmlRegisterType<VideoSender>("VideoSender", 1, 0, "VideoSender");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    debug("grpc version:", grpc_version_string());

    int ret = app.exec();

    // 清理网络环境
    WSACleanup();

    return ret;
}
