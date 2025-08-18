/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * AvatarMapTable implementation
 */

#include "avatarmaptable.h"
#include "auxdatabase.h"

#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(avatarMapTable, "avatarMapTable")

AvatarMapTable::AvatarMapTable(AuxDatabase *auxdb, QObject *parent)
    : QObject(parent)
    , m_db(auxdb)
{
    qDebug(avatarMapTable) << "AvatarMapTable initialized";
}

QString AvatarMapTable::getAvatarPathbyId(qint64 id)
{
    QString path = "";
    if (!m_db->getDB()) {
        return path;
    }
    
    QSqlQuery query(*m_db->getDB());
    query.prepare("SELECT path FROM chatlist_map WHERE id = :id");
    query.bindValue(":id", id);
    
    if (!query.exec()) {
        m_db->logSqlError(query);
        return path;
    }
    
    if (query.next()) {
        path = query.value(0).toString();
    }
    
    qDebug(avatarMapTable) << "Avatar path for chat" << id << ":" << path;
    return path;
}

void AvatarMapTable::setAvatarMapEntry(const qint64 id, const QString &path)
{
    if (!m_db->getDB()) {
        return;
    }
    
    QSqlQuery query(*m_db->getDB());
    query.prepare("INSERT OR REPLACE INTO chatlist_map(id, path, unread_messages) "
                 "VALUES(:id, :path, COALESCE((SELECT unread_messages FROM chatlist_map WHERE id = :id), 0))");
    query.bindValue(":id", id);
    query.bindValue(":path", path);
    
    if (!query.exec()) {
        m_db->logSqlError(query);
    } else {
        qDebug(avatarMapTable) << "Set avatar for chat" << id << "to" << path;
    }
}

void AvatarMapTable::setUnreadMapEntry(const qint64 id, const qint32 unread_messages)
{
    if (!m_db->getDB()) {
        return;
    }
    
    QSqlQuery query(*m_db->getDB());
    query.prepare("INSERT OR REPLACE INTO chatlist_map(id, path, unread_messages) "
                 "VALUES(:id, COALESCE((SELECT path FROM chatlist_map WHERE id = :id), \"\"), :unread_messages)");
    query.bindValue(":id", id);
    query.bindValue(":unread_messages", unread_messages);
    
    if (!query.exec()) {
        m_db->logSqlError(query);
    } else {
        qDebug(avatarMapTable) << "Set unread count for chat" << id << "to" << unread_messages;
    }
}

qint32 AvatarMapTable::getUnreadCount(qint64 id)
{
    qint32 count = 0;
    if (!m_db->getDB()) {
        return count;
    }
    
    QSqlQuery query(*m_db->getDB());
    query.prepare("SELECT unread_messages FROM chatlist_map WHERE id = :id");
    query.bindValue(":id", id);
    
    if (!query.exec()) {
        m_db->logSqlError(query);
        return count;
    }
    
    if (query.next()) {
        count = query.value(0).toInt();
    }
    
    return count;
}

qint32 AvatarMapTable::getTotalUnread()
{
    qint32 totalCount = 0;
    if (!m_db->getDB()) {
        return totalCount;
    }
    
    QSqlQuery query(*m_db->getDB());
    query.prepare("SELECT COALESCE(SUM(unread_messages), 0) FROM chatlist_map");
    
    if (!query.exec()) {
        m_db->logSqlError(query);
        return totalCount;
    }
    
    if (query.next()) {
        totalCount = query.value(0).toInt();
    }
    
    qDebug(avatarMapTable) << "Total unread count:" << totalCount;
    return totalCount;
}

void AvatarMapTable::resetUnreadMap()
{
    if (!m_db->getDB()) {
        return;
    }
    
    QSqlQuery query(*m_db->getDB());
    query.prepare("UPDATE chatlist_map SET unread_messages = 0");
    
    if (!query.exec()) {
        m_db->logSqlError(query);
    } else {
        qDebug(avatarMapTable) << "Reset all unread counts";
    }
}
