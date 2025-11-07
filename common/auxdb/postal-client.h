/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * PostalClient - D-Bus interface to Ubuntu Touch Postal service
 */

#pragma once

#include <QObject>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QString>
#include <QStringList>

#define POSTAL_SERVICE "com.lomiri.Postal"
#define POSTAL_PATH "/com/lomiri/Postal"
#define POSTAL_IFACE "com.lomiri.Postal"

class PostalClient : public QObject
{
    Q_OBJECT

public:
    explicit PostalClient(QString appId, QObject *parent = nullptr);
    
    void setCount(int count);
    void clearPersistent(const QStringList &tags);
    void post(const QString &message);

private Q_SLOTS:
    void setCountFinished(QDBusPendingCallWatcher *watcher);
    void postFinished(QDBusPendingCallWatcher *watcher);

private:
    QString m_appId;
    QString m_pkgName;
};
