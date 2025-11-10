/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * Push notification helper for Ubuntu Touch
 * Converts incoming push messages to Ubuntu Touch Postal format
 */

#pragma once

#include <QObject>
#include <QJsonObject>
#include <QJsonDocument>
#include <QFile>
#include <QStandardPaths>
#include <QGuiApplication>
#include <QDebug>

#include "../common/auxdb/postal-client.h"
#include "../common/auxdb/notification-client.h"
#include "../common/auxdb/auxdatabase.h"

class PushHelper : public QObject
{
    Q_OBJECT

public:
    explicit PushHelper(const QString appId, const QString infile, const QString outfile, QObject *parent = nullptr);
    
    void process();

Q_SIGNALS:
    void done();

private:
    QJsonObject readPushMessage(const QString &filename);
    QJsonObject pushToPostalMessage(const QJsonObject &pushMessage);
    void writePostalMessage(const QJsonObject &postalMessage, const QString &filename);
    void writeOutputFile(const QString &summary, const QString &body, const QString &icon, const QString &tag, int count);
    
    QString formatNotificationMessage(const QString &messageType, const QJsonArray &args);
    qint64 extractChatId(const QJsonObject &custom);
    
    QString mInfile;
    QString mOutfile;
    QJsonObject mPostalMessage;
    
    PostalClient *m_postalClient;
    NotificationClient *m_notificationClient;
    AuxDatabase m_auxdb;
};
