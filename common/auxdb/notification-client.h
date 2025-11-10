/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * NotificationClient - D-Bus interface to org.freedesktop.Notifications
 */

#pragma once

#include <QObject>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QString>
#include <QStringList>
#include <QVariantMap>

#define NOTIFICATION_SERVICE "org.freedesktop.Notifications"
#define NOTIFICATION_PATH "/org/freedesktop/Notifications"
#define NOTIFICATION_IFACE "org.freedesktop.Notifications"

class NotificationClient : public QObject
{
    Q_OBJECT

public:
    explicit NotificationClient(QString appId, QObject *parent = nullptr);

    // Send a notification to the notification panel
    void notify(const QString &summary, const QString &body, 
                const QString &icon = "notification", 
                const QStringList &actions = QStringList(),
                const QVariantMap &hints = QVariantMap(),
                int timeout = 5000);

private Q_SLOTS:
    void notifyFinished(QDBusPendingCallWatcher *watcher);

private:
    QString m_appId;
    uint m_lastNotificationId;
};
