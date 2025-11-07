/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * Push notification helper implementation
 */

#include "pushhelper.h"
#include "i18n.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QDebug>
#include <QLoggingCategory>
#include <QDir>

#include <locale.h>

Q_LOGGING_CATEGORY(pushHelper, "pushHelper")

PushHelper::PushHelper(const QString appId, const QString infile, const QString outfile, QObject *parent)
    : QObject(parent)
    , mInfile(infile)
    , mOutfile(outfile)
    , m_postalClient(new PostalClient(appId))
    , m_auxdb(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation).append("/auxdb"),
              QGuiApplication::applicationDirPath().append("/assets"), this)
{
    qDebug(pushHelper) << "PushHelper initialized";
    qDebug(pushHelper) << "Input file:" << mInfile;
    qDebug(pushHelper) << "Output file:" << mOutfile;
    
    // Set up internationalization
    setlocale(LC_ALL, "");
    textdomain(GETTEXT_DOMAIN.toStdString().c_str());
}

void PushHelper::process()
{
    qDebug(pushHelper) << "Starting push message processing";
    
    QJsonObject pushMessage = readPushMessage(mInfile);
    if (pushMessage.isEmpty()) {
        qWarning(pushHelper) << "Failed to read push message from" << mInfile;
        Q_EMIT done();
        return;
    }
    
    mPostalMessage = pushToPostalMessage(pushMessage);
    if (mPostalMessage.isEmpty()) {
        qDebug(pushHelper) << "No postal message to send";
        Q_EMIT done();
        return;
    }
    
    // Post the notification to the Postal service (this creates system notification)
    QJsonDocument doc(mPostalMessage);
    QString messageJson = doc.toJson(QJsonDocument::Compact);
    m_postalClient->post(messageJson);
    
    qDebug(pushHelper) << "Push message processing completed - notification posted to system";
    
    Q_EMIT done();
}

QJsonObject PushHelper::readPushMessage(const QString &filename)
{
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning(pushHelper) << "Cannot open input file:" << filename;
        return QJsonObject();
    }
    
    QString val = file.readAll();
    file.close();
    
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(val.toUtf8(), &parseError);
    
    if (parseError.error != QJsonParseError::NoError) {
        qWarning(pushHelper) << "JSON parse error:" << parseError.errorString();
        return QJsonObject();
    }
    
    qDebug(pushHelper) << "Successfully read push message:" << doc.object();
    return doc.object();
}

QJsonObject PushHelper::pushToPostalMessage(const QJsonObject &pushMessage)
{
    // Extract message data
    QJsonObject message = pushMessage["message"].toObject();
    if (message.isEmpty()) {
        qDebug(pushHelper) << "No message object found";
        return QJsonObject();
    }
    
    QString locKey = message["loc_key"].toString();
    QJsonArray locArgs = message["loc_args"].toArray();
    QJsonObject custom = message["custom"].toObject();
    int badge = message["badge"].toInt();
    
    qDebug(pushHelper) << "Message type:" << locKey;
    qDebug(pushHelper) << "Message args:" << locArgs;
    qDebug(pushHelper) << "Badge count:" << badge;
    
    // Handle special cases
    if (locKey.isEmpty() || locKey == "READ_HISTORY") {
        qDebug(pushHelper) << "Skipping notification for type:" << locKey;
        return QJsonObject();
    }
    
    // Extract chat ID
    qint64 chatId = extractChatId(custom);
    if (chatId == 0) {
        qWarning(pushHelper) << "Could not determine chat ID";
        return QJsonObject();
    }
    
    // Update unread count in database
    if (badge > 0) {
        m_auxdb.getAvatarMapTable()->setUnreadMapEntry(chatId, badge);
        qint32 totalCount = m_auxdb.getAvatarMapTable()->getTotalUnread();
        
        // Update badge counter
        m_postalClient->setCount(totalCount);
        qDebug(pushHelper) << "Updated badge count to:" << totalCount;
    }
    
    // Clear old notifications for this chat
    m_postalClient->clearPersistent(QStringList(QString::number(chatId)));
    
    // Format notification message
    QString summary, body;
    if (locArgs.size() > 0) {
        summary = locArgs[0].toString(); // Usually sender name
    } else {
        summary = "Push Notification";
    }
    
    body = formatNotificationMessage(locKey, locArgs);
    if (body.isEmpty()) {
        qDebug(pushHelper) << "No body text for message type:" << locKey;
        return QJsonObject();
    }
    
    // Get avatar (if available)
    QString avatar = m_auxdb.getAvatarMapTable()->getAvatarPathbyId(chatId);
    if (avatar.isEmpty()) {
        avatar = "notification-symbolic"; // Default Ubuntu Touch icon
    }
    
    // Create action URL for deep linking
    QString actionUrl = QString("pushnotification://chat/%1").arg(chatId);
    
    // Build postal notification
    QJsonObject card;
    card["summary"] = summary;
    card["body"] = body;
    card["popup"] = true;
    card["persist"] = true;
    card["icon"] = avatar;
    
    QJsonArray actions;
    actions.append(actionUrl);
    card["actions"] = actions;
    
    QJsonObject notification;
    notification["card"] = card;
    notification["sound"] = true;
    notification["tag"] = QString::number(chatId);
    notification["vibrate"] = true;
    
    QJsonObject result;
    result["notification"] = notification;
    
    qDebug(pushHelper) << "Created postal message:" << result;
    return result;
}

void PushHelper::writePostalMessage(const QJsonObject &postalMessage, const QString &filename)
{
    QFile file(filename);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning(pushHelper) << "Cannot open output file:" << filename;
        return;
    }
    
    QJsonDocument doc(postalMessage);
    file.write(doc.toJson());
    file.close();
    
    qDebug(pushHelper) << "Wrote postal message to:" << filename;
}

QString PushHelper::formatNotificationMessage(const QString &messageType, const QJsonArray &args)
{
    // Handle different message types
    if (messageType == "MESSAGE_TEXT" && args.size() >= 2) {
        return args[1].toString(); // Direct message text
    } else if (messageType == "MESSAGE_PHOTO") {
        return N_("sent you a photo");
    } else if (messageType == "MESSAGE_VIDEO") {
        return N_("sent you a video");
    } else if (messageType == "MESSAGE_AUDIO") {
        return N_("sent you an audio message");
    } else if (messageType == "MESSAGE_VOICE_NOTE") {
        return N_("sent you a voice message");
    } else if (messageType == "MESSAGE_STICKER") {
        return N_("sent you a sticker");
    } else if (messageType == "MESSAGE_DOC") {
        return N_("sent you a document");
    } else if (messageType == "MESSAGE_CONTACT") {
        return N_("shared a contact with you");
    } else if (messageType == "MESSAGE_GEO") {
        return N_("sent you a location");
    } else if (messageType == "MESSAGE_NOTEXT") {
        return N_("sent you a message");
    } else if (messageType == "CHAT_MESSAGE_TEXT" && args.size() >= 3) {
        // Group message: sender: message
        return QString("%1: %2").arg(args[0].toString()).arg(args[2].toString());
    } else if (messageType == "CHAT_MESSAGE_PHOTO") {
        return QString(N_("%1 sent a photo to the group")).arg(args[0].toString());
    } else if (messageType == "CHAT_MESSAGE_VIDEO") {
        return QString(N_("%1 sent a video to the group")).arg(args[0].toString());
    } else if (messageType == "CHAT_CREATED") {
        return QString(N_("%1 invited you to the group")).arg(args[0].toString());
    } else if (messageType == "CHAT_ADD_YOU") {
        return QString(N_("%1 invited you to the group")).arg(args[0].toString());
    } else if (messageType == "NEW_MESSAGE") {
        return N_("You have a new message");
    } else {
        qDebug(pushHelper) << "Unhandled message type:" << messageType;
        return N_("You have a new message");
    }
}

qint64 PushHelper::extractChatId(const QJsonObject &custom)
{
    qint64 chatId = 0;
    
    // Try different chat ID fields
    if (custom.contains("from_id")) {
        // Private chat: Use user ID directly
        chatId = custom["from_id"].toString().toLongLong();
    } else if (custom.contains("chat_id")) {
        // Basic group: Negate the group ID
        chatId = custom["chat_id"].toString().toLongLong() * -1;
    } else if (custom.contains("channel_id")) {
        // Supergroup/Channel: Apply transformation
        qint64 channelId = custom["channel_id"].toString().toLongLong();
        chatId = (channelId + 1000000000000LL) * -1;
    } else if (custom.contains("id")) {
        // Generic ID field
        chatId = custom["id"].toString().toLongLong();
    }
    
    qDebug(pushHelper) << "Extracted chat ID:" << chatId;
    return chatId;
}
