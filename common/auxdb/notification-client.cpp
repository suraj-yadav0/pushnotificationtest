/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * NotificationClient implementation
 */

#include "notification-client.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingReply>
#include <QDBusPendingCallWatcher>
#include <QDebug>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(notificationClient, "notificationClient")

NotificationClient::NotificationClient(QString appId, QObject *parent)
    : QObject(parent), m_appId(appId), m_lastNotificationId(0)
{
    qDebug(notificationClient) << "NotificationClient initialized for app:" << m_appId;
}

void NotificationClient::notify(const QString &summary, const QString &body,
                               const QString &icon, const QStringList &actions,
                               const QVariantMap &hints, int timeout)
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected())
    {
        qWarning(notificationClient) << "D-Bus session bus not connected";
        return;
    }

    qDebug(notificationClient) << "Sending notification:";
    qDebug(notificationClient) << "  Summary:" << summary;
    qDebug(notificationClient) << "  Body:" << body;
    qDebug(notificationClient) << "  Icon:" << icon;

    // Create the D-Bus method call
    QDBusMessage message = QDBusMessage::createMethodCall(
        NOTIFICATION_SERVICE,
        NOTIFICATION_PATH,
        NOTIFICATION_IFACE,
        "Notify");

    // Arguments for org.freedesktop.Notifications.Notify:
    // string app_name
    // uint32 replaces_id (0 for new notification)
    // string app_icon
    // string summary
    // string body
    // array of string actions
    // dict hints
    // int32 expire_timeout
    
    QList<QVariant> args;
    args << m_appId;              // app_name
    args << (uint)0;              // replaces_id (0 = new notification)
    args << icon;                 // app_icon
    args << summary;              // summary
    args << body;                 // body
    args << actions;              // actions
    args << hints;                // hints
    args << timeout;              // expire_timeout (-1 = use default)

    message.setArguments(args);

    QDBusPendingCall pcall = bus.asyncCall(message);
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(pcall, this);
    connect(watcher, &QDBusPendingCallWatcher::finished,
            this, &NotificationClient::notifyFinished);
}

void NotificationClient::notifyFinished(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<uint> reply = *watcher;
    if (reply.isError())
    {
        qWarning(notificationClient) << "Notify D-Bus call failed:" << reply.error().message();
    }
    else
    {
        m_lastNotificationId = reply.value();
        qDebug(notificationClient) << "Notification sent successfully, ID:" << m_lastNotificationId;
    }
    watcher->deleteLater();
}
