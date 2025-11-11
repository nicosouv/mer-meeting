#include "meeting.h"
#include <QRegularExpression>
#include <QDebug>

Meeting::Meeting(const QString &filename, QObject *parent)
    : QObject(parent)
    , m_filename(filename)
    , m_baseUrl("https://irclogs.sailfishos.org/meetings/sailfishos-meeting")
{
    parseFilename();
}

void Meeting::parseFilename()
{
    // Parse pattern: sailfishos-meeting.2024-12-12-08.01.html
    QRegularExpression re("sailfishos-meeting\\.(\\d{4})-(\\d{2})-(\\d{2})-(\\d{2})\\.(\\d{2})");
    QRegularExpressionMatch match = re.match(m_filename);

    if (match.hasMatch()) {
        int year = match.captured(1).toInt();
        int month = match.captured(2).toInt();
        int day = match.captured(3).toInt();
        int hour = match.captured(4).toInt();
        int minute = match.captured(5).toInt();

        m_dateTime = QDateTime(QDate(year, month, day), QTime(hour, minute), Qt::UTC);
    } else {
        qWarning() << "Failed to parse meeting filename:" << m_filename;
    }
}

QString Meeting::date() const
{
    return m_dateTime.date().toString("dd MMMM yyyy");
}

QString Meeting::time() const
{
    return m_dateTime.time().toString("HH:mm") + " UTC";
}

QString Meeting::title() const
{
    return QString("Sailfish OS Meeting");
}

QString Meeting::url() const
{
    int year = m_dateTime.date().year();
    QString baseFilename = m_filename;
    baseFilename.replace(".log.html", ".html");
    return QString("%1/%2/%3").arg(m_baseUrl).arg(year).arg(baseFilename);
}

QString Meeting::logUrl() const
{
    int year = m_dateTime.date().year();
    QString logFilename = m_filename;
    if (!logFilename.contains(".log.html")) {
        logFilename.replace(".html", ".log.html");
    }
    return QString("%1/%2/%3").arg(m_baseUrl).arg(year).arg(logFilename);
}

QString Meeting::filename() const
{
    return m_filename;
}
