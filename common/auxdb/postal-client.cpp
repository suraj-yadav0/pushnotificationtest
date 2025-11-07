/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * PostalClient implementation
 */

#include "postal-client.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingReply>
#include <QDBusPendingCallWatcher>
#include <QDebug>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(postalClient, "postalClient")

PostalClient::PostalClient(QString appId, QObject *parent)
    : QObject(parent)
    , m_appId(appId)
{
    // Extract package name from app ID
    this->m_pkgName = appId.split("_").at(0);
    
    // Escape special characters for D-Bus path
    this->m_pkgName = m_pkgName.replace(".", "_2e").replace("-", "_2d");
    
    qDebug(postalClient) << "PostalClient initialized for app:" << m_appId;
    qDebug(postalClient) << "Package name:" << m_pkgName;
}

void PostalClient::setCount(int count)
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        qWarning(postalClient) << "D-Bus session bus not connected";
        return;
    }
    
    QString path(POSTAL_PATH);
    bool visible = count != 0;
    path += "/" + m_pkgName;
    
    qDebug(postalClient) << "Setting badge count:" << count << "visible:" << visible;
    qDebug(postalClient) << "D-Bus path:" << path;
    
    QDBusMessage message = QDBusMessage::createMethodCall(
        POSTAL_SERVICE, path, POSTAL_IFACE, "SetCounter");
    message << m_appId << count << visible;
    
    QDBusPendingCall pcall = bus.asyncCall(message);
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(pcall, this);
    connect(watcher, SIGNAL(finished(QDBusPendingCallWatcher *)),
            this, SLOT(setCountFinished(QDBusPendingCallWatcher *)));
}

void PostalClient::setCountFinished(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<void> reply = *watcher;
    if (reply.isError()) {
        qWarning(postalClient) << "SetCounter D-Bus call failed:" << reply.error().message();
    } else {
        qDebug(postalClient) << "Badge count updated successfully";
    }
    watcher->deleteLater();
}

void PostalClient::clearPersistent(const QStringList &tags)
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        qWarning(postalClient) << "D-Bus session bus not connected";
        return;
    }
    
    QString path(POSTAL_PATH);
    path += "/" + m_pkgName;
    
    qDebug(postalClient) << "Clearing persistent notifications for tags:" << tags;
    qDebug(postalClient) << "D-Bus path:" << path;
    
    QDBusMessage message = QDBusMessage::createMethodCall(
        POSTAL_SERVICE, path, POSTAL_IFACE, "ClearPersistent");
    message << m_appId;
    for (const QString &tag : tags) {
        message << tag;
    }
    
    QDBusPendingCall pcall = bus.asyncCall(message);
    // Fire and forget - don't wait for response
}

void PostalClient::post(const QString &message)
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        qWarning(postalClient) << "D-Bus session bus not connected";
        return;
    }
    
    QString path(POSTAL_PATH);
    path += "/" + m_pkgName;
    
    qDebug(postalClient) << "Posting notification to Postal service";
    qDebug(postalClient) << "D-Bus path:" << path;
    qDebug(postalClient) << "Message:" << message;
    
    QDBusMessage dbusMessage = QDBusMessage::createMethodCall(
        POSTAL_SERVICE, path, POSTAL_IFACE, "Post");
    dbusMessage << m_appId << message;
    
    QDBusPendingCall pcall = bus.asyncCall(dbusMessage);
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(pcall, this);
    connect(watcher, SIGNAL(finished(QDBusPendingCallWatcher *)),
            this, SLOT(postFinished(QDBusPendingCallWatcher *)));
}

void PostalClient::postFinished(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<void> reply = *watcher;
    if (reply.isError()) {
        qWarning(postalClient) << "Post D-Bus call failed:" << reply.error().message();
    } else {
        qDebug(postalClient) << "Notification posted successfully to Postal service";
    }
    watcher->deleteLater();
}
