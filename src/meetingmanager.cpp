#include "meetingmanager.h"
#include <QRegularExpression>
#include <QDebug>
#include <QDateTime>

MeetingManager::MeetingManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_loading(false)
{
}

void MeetingManager::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void MeetingManager::setError(const QString &error)
{
    if (m_error != error) {
        m_error = error;
        emit errorChanged();
    }
}

QVariantList MeetingManager::getAvailableYears()
{
    QVariantList years;
    int currentYear = QDateTime::currentDateTime().date().year();

    // From 2024 to current year
    for (int year = currentYear; year >= 2024; --year) {
        years.append(year);
    }

    return years;
}

void MeetingManager::fetchMeetingsForYear(int year)
{
    setLoading(true);
    setError("");

    QString url = QString("https://irclogs.sailfishos.org/meetings/sailfishos-meeting/%1/").arg(year);

    QNetworkRequest request(url);
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &MeetingManager::onMeetingListReplyFinished);
}

void MeetingManager::onMeetingListReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    setLoading(false);

    if (reply->error() != QNetworkReply::NoError) {
        setError(reply->errorString());
        reply->deleteLater();
        return;
    }

    QString html = QString::fromUtf8(reply->readAll());
    reply->deleteLater();

    QList<Meeting*> meetings = parseMeetingList(html);

    QVariantList meetingVariants;
    for (Meeting *meeting : meetings) {
        meetingVariants.append(QVariant::fromValue(meeting));
    }

    emit meetingsLoaded(meetingVariants);
}

QList<Meeting*> MeetingManager::parseMeetingList(const QString &html)
{
    QList<Meeting*> meetings;

    // Match pattern: href="sailfishos-meeting.2024-12-12-08.01.html"
    QRegularExpression re("href=\"(sailfishos-meeting\\.\\d{4}-\\d{2}-\\d{2}-\\d{2}\\.\\d{2}\\.html)\"");
    QRegularExpressionMatchIterator i = re.globalMatch(html);

    while (i.hasNext()) {
        QRegularExpressionMatch match = i.next();
        QString filename = match.captured(1);

        // Avoid duplicates (.log.html versions)
        if (!filename.contains(".log.html")) {
            Meeting *meeting = new Meeting(filename, this);
            meetings.append(meeting);
        }
    }

    // Sort by date descending (newest first)
    std::sort(meetings.begin(), meetings.end(),
              [](const Meeting *a, const Meeting *b) {
                  return a->dateTime() > b->dateTime();
              });

    return meetings;
}

QString MeetingManager::fetchHtmlContent(const QString &url)
{
    QNetworkRequest request(url);
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &MeetingManager::onHtmlContentReplyFinished);

    return QString(); // Will emit signal when loaded
}

void MeetingManager::onHtmlContentReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() != QNetworkReply::NoError) {
        setError(reply->errorString());
        reply->deleteLater();
        return;
    }

    QString content = QString::fromUtf8(reply->readAll());
    reply->deleteLater();

    emit htmlContentLoaded(content);
}
