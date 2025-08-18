/*
 * Copyright (C) 2025 Suraj Yadav
 *
 * Internationalization support for push notifications
 */

#pragma once

#include <libintl.h>
#include <QString>

const QString GETTEXT_DOMAIN = "pushnotification.surajyadav";

#define _(value) gettext(value)
#define N_(value) gettext(value)
