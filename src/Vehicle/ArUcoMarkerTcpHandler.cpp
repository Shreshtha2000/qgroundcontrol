#include "ArUcoMarkerTcpHandler.h"
//This class handles the communication with python script
ArUcoMarkerTcpHandler::ArUcoMarkerTcpHandler(QObject *parent)
    : QObject{parent}
{
    qDebug()<<"Starting connection";
    socket = new QTcpSocket(this);

    socket->connectToHost("172.26.84.217",5000);

    connect(socket, &QTcpSocket::connected, this, [](){
        qDebug() << "[TCP] Connected to server";
    });

    connect(socket, &QTcpSocket::disconnected, this, [](){
        qDebug() << "[TCP] Disconnected from server";
    });

    connect(socket, &QTcpSocket::errorOccurred, this, [](QAbstractSocket::SocketError err){
        qDebug() << "[TCP] Error:" << err;
    });

    connect(socket, &QTcpSocket::stateChanged, this, [](QAbstractSocket::SocketState state){
        qDebug() << "[TCP] State changed:" << state;
    });

    connect(socket, &QTcpSocket::readyRead,this, &ArUcoMarkerTcpHandler::onReadyRead);

}
void ArUcoMarkerTcpHandler::enableArUcoDetection(bool enabled){
    QJsonObject obj;
    obj["type"] = "cmd";
    obj["cmd"] = "enable_disable_locking";
    QJsonObject params;
    params["enabled"] = enabled;
    obj["params"] = params;
    lockingEnabled = enabled;
    QJsonDocument doc(obj);

    QByteArray payload = doc.toJson(QJsonDocument::Compact);
    QByteArray message;

    quint32 len = payload.size();

    message.append(char((len >> 24) & 0xFF ));
    message.append(char((len >> 16) & 0xFF));
    message.append(char((len >> 8) & 0xFF));
    message.append(char(len & 0XFF));

    message.append(payload);
    socket->write(message);

}
void ArUcoMarkerTcpHandler::onReadyRead(){
    buffer.append(socket->readAll());

    while (true)
    {
        if (buffer.size() < 4)
            return;

        quint32 msgLen =
            (quint8(buffer[0]) << 24) |
            (quint8(buffer[1]) << 16) |
            (quint8(buffer[2]) << 8)  |
            (quint8(buffer[3]));

        if ((uint)buffer.size() < (4 + msgLen))
            return;

        QByteArray payload = buffer.mid(4, msgLen);
        buffer.remove(0, 4 + msgLen);

        QJsonDocument doc = QJsonDocument::fromJson(payload);
        QJsonObject obj = doc.object();

        handleMessage(obj);
    }
}


void ArUcoMarkerTcpHandler::handleMessage(const QJsonObject &obj)
{
    qDebug()<<obj;
    QString type = obj["type"].toString();

    if (type == "status")
    {
        QString status = obj["status"].toString();
        QJsonObject params = obj["params"].toObject();

        if (status == "detection_result")
        {
            bool enabled = params["found"].toBool();
            qDebug() << "detection:" << enabled;
            emit detectionFound(enabled);
        }
    }
}


void ArUcoMarkerTcpHandler::sendMessage(bool enabled)
{
    QJsonObject obj;
    obj["type"] = "cmd";
    obj["cmd"] = "run_detection";

    QJsonObject params;
    params["enabled"] = enabled;

    obj["params"] = params;

    QJsonDocument doc(obj);
    QByteArray payload = doc.toJson(QJsonDocument::Compact);

    QByteArray message;

    quint32 len = payload.size();

    message.append(char((len >> 24) & 0xFF));
    message.append(char((len >> 16) & 0xFF));
    message.append(char((len >> 8) & 0xFF));
    message.append(char(len & 0xFF));

    message.append(payload);

    socket->write(message);
}
