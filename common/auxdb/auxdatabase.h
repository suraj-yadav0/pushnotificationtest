/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * AuxDatabase - SQLite database for notification state management
 */

#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QString>
#include <QDir>

#include "avatarmaptable.h"

class AuxDatabase : public QObject
{
    Q_OBJECT

public:
    explicit AuxDatabase(const QString &databaseDirectory, const QString &assetsDirectory, QObject *parent = nullptr);
    ~AuxDatabase();
    
    QSqlDatabase *getDB();
    void logSqlError(QSqlQuery &q) const;
    
    AvatarMapTable *getAvatarMapTable() { return m_avatarMapTable; }

private:
    bool initDatabase();
    bool migrateDatabase();
    int getDatabaseVersion();
    void setDatabaseVersion(int version);
    
    QString m_databaseDirectory;
    QString m_assetsDirectory;
    QString m_databasePath;
    QSqlDatabase m_database;
    
    AvatarMapTable *m_avatarMapTable;
    
    static const int CURRENT_DB_VERSION = 2;
};
