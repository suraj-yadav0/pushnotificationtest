/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * AuxDatabase implementation
 */

#include "auxdatabase.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QDebug>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(auxdb, "auxdb")

AuxDatabase::AuxDatabase(const QString &databaseDirectory, const QString &assetsDirectory, QObject *parent)
    : QObject(parent)
    , m_databaseDirectory(databaseDirectory)
    , m_assetsDirectory(assetsDirectory)
    , m_avatarMapTable(nullptr)
{
    m_databasePath = m_databaseDirectory + "/auxdb.sqlite";
    
    qDebug(auxdb) << "AuxDatabase initialized";
    qDebug(auxdb) << "Database directory:" << m_databaseDirectory;
    qDebug(auxdb) << "Database path:" << m_databasePath;
    
    if (initDatabase()) {
        m_avatarMapTable = new AvatarMapTable(this, this);
        qDebug(auxdb) << "Database initialization successful";
    } else {
        qWarning(auxdb) << "Database initialization failed";
    }
}

AuxDatabase::~AuxDatabase()
{
    if (m_database.isOpen()) {
        m_database.close();
    }
}

bool AuxDatabase::initDatabase()
{
    // Create database directory if it doesn't exist
    QDir dir;
    if (!dir.exists(m_databaseDirectory)) {
        if (!dir.mkpath(m_databaseDirectory)) {
            qWarning(auxdb) << "Unable to create database directory:" << m_databaseDirectory;
            return false;
        }
    }
    
    // Initialize SQLite database
    m_database = QSqlDatabase::addDatabase("QSQLITE", "auxdb");
    m_database.setDatabaseName(m_databasePath);
    
    if (!m_database.open()) {
        qWarning(auxdb) << "Cannot open database:" << m_database.lastError().text();
        return false;
    }
    
    // Enable foreign keys
    QSqlQuery query(m_database);
    query.exec("PRAGMA foreign_keys = ON");
    
    // Check if migration is needed
    return migrateDatabase();
}

bool AuxDatabase::migrateDatabase()
{
    int currentVersion = getDatabaseVersion();
    qDebug(auxdb) << "Current database version:" << currentVersion;
    
    if (currentVersion < CURRENT_DB_VERSION) {
        qDebug(auxdb) << "Migrating database from version" << currentVersion << "to" << CURRENT_DB_VERSION;
        
        // Apply migrations
        if (currentVersion < 1) {
            // Initial schema
            QSqlQuery query(m_database);
            if (!query.exec("CREATE TABLE IF NOT EXISTS `chatlist_map` ("
                           "`id` INTEGER NOT NULL UNIQUE, "
                           "`path` TEXT NOT NULL, "
                           "PRIMARY KEY(id))")) {
                logSqlError(query);
                return false;
            }
        }
        
        if (currentVersion < 2) {
            // Add unread_messages column
            QSqlQuery query(m_database);
            if (!query.exec("ALTER TABLE `chatlist_map` ADD COLUMN `unread_messages` INTEGER DEFAULT 0")) {
                logSqlError(query);
                return false;
            }
        }
        
        setDatabaseVersion(CURRENT_DB_VERSION);
        qDebug(auxdb) << "Database migration completed";
    }
    
    return true;
}

int AuxDatabase::getDatabaseVersion()
{
    QSqlQuery query(m_database);
    if (query.exec("PRAGMA user_version")) {
        if (query.next()) {
            return query.value(0).toInt();
        }
    }
    return 0;
}

void AuxDatabase::setDatabaseVersion(int version)
{
    QSqlQuery query(m_database);
    query.exec(QString("PRAGMA user_version = %1").arg(version));
}

QSqlDatabase *AuxDatabase::getDB()
{
    if (m_database.isOpen()) {
        return &m_database;
    }
    return nullptr;
}

void AuxDatabase::logSqlError(QSqlQuery &q) const
{
    qDebug(auxdb) << "SQLite error:" << q.lastError().text();
    qDebug(auxdb) << "SQLite query:" << q.lastQuery();
}
