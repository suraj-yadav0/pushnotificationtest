/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Push Notification Helper for Ubuntu Touch
 * Based on TELEports notification mechanism
 */

#include <QCoreApplication>
#include <QTimer>
#include <QLoggingCategory>
#include <QStringList>
#include <QDebug>

#include "pushhelper.h"

Q_DECLARE_LOGGING_CATEGORY(pushHelper)

int main(int argc, char *argv[])
{
    if (argc != 3) {
        qFatal("Usage: %s infile outfile", argv[0]);
    }
    
    QCoreApplication app(argc, argv);
    QStringList args = app.arguments();
    
    // Application identity setup
    QCoreApplication::setApplicationName(QStringLiteral("pushnotification.surajyadav"));
    QCoreApplication::setOrganizationName(QStringLiteral("pushnotification.surajyadav"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("pushnotification.surajyadav"));
    
    // Disable auxdb logging for performance
    QLoggingCategory::setFilterRules("auxdb=false");
    
    qDebug(pushHelper) << "Push helper started with args:" << args;
    
    // Create and process push notification
    PushHelper pushHelper("pushnotification.surajyadav_pushnotification",
                          QString(args.at(1)), QString(args.at(2)), &app);
    
    QObject::connect(&pushHelper, SIGNAL(done()), &app, SLOT(quit()));
    pushHelper.process();
    
    // Fallback timeout to ensure app exits
    QTimer::singleShot(1000, &app, SLOT(quit()));
    
    return app.exec();
}
