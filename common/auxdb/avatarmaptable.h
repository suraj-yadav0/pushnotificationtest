/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * AvatarMapTable - Manages chat avatars and unread message counts
 */

#pragma once

#include <QObject>
#include <QSqlQuery>
#include <QString>

class AuxDatabase;

class AvatarMapTable : public QObject
{
    Q_OBJECT

public:
    explicit AvatarMapTable(AuxDatabase *auxdb, QObject *parent = nullptr);
    
    // Avatar management
    QString getAvatarPathbyId(qint64 id);
    void setAvatarMapEntry(const qint64 id, const QString &path);
    
    // Unread count management
    void setUnreadMapEntry(const qint64 id, const qint32 unread_messages);
    qint32 getUnreadCount(qint64 id);
    qint32 getTotalUnread();
    void resetUnreadMap();

private:
    AuxDatabase *m_db;
};
