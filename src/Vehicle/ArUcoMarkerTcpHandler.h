#ifndef ARUCOMARKERTCPHANDLER_H
#define ARUCOMARKERTCPHANDLER_H

#include <QObject>
#include <QTcpSocket>
#include <QByteArray>
#include <QJsonObject>

class ArUcoMarkerTcpHandler : public QObject
{
    Q_OBJECT
public:
    explicit ArUcoMarkerTcpHandler(QObject *parent = nullptr);

    void sendMessage(bool enabled);
    void enableArUcoDetection(bool enabled);

    ~ArUcoMarkerTcpHandler(){
        socket->close();
        qDebug()<<"Destructor called";
        delete socket;
    }
    bool lockingEnabled = false;
signals:
    void detectionFound(bool);
public slots:
    void onReadyRead();
private:
    QTcpSocket *socket = nullptr;
    QByteArray buffer;
    void handleMessage(const QJsonObject &obj);
signals:
};

#endif // ARUCOMARKERTCPHANDLER_H
