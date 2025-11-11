import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mer.meeting 1.0

Page {
    id: page

    property var meeting
    property string logContent: ""

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        meetingManager.fetchHtmlContent(meeting.logUrl)
    }

    Connections {
        target: meetingManager
        onHtmlContentLoaded: {
            logContent = content
            parseAndDisplayLog()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    logContent = ""
                    logRepeater.model = []
                    meetingManager.fetchHtmlContent(meeting.logUrl)
                }
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("IRC Log")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: meeting.date + " - " + meeting.time
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
            }

            Item { width: 1; height: Theme.paddingMedium }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: logContent === "" && logRepeater.model.length === 0
                size: BusyIndicatorSize.Large
            }

            Repeater {
                id: logRepeater

                delegate: Item {
                    width: column.width
                    height: logLine.height + Theme.paddingSmall

                    Label {
                        id: logLine
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        text: modelData.text
                        textFormat: Text.RichText
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeTiny
                        font.family: "Monospace"
                        color: modelData.color
                        linkColor: Theme.highlightColor
                        onLinkActivated: Qt.openUrlExternally(link)
                    }
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }

    function parseAndDisplayLog() {
        if (logContent === "") return

        var lines = []
        var plainText = extractPlainText(logContent)
        var logLines = plainText.split('\n')

        for (var i = 0; i < logLines.length; i++) {
            var line = logLines[i].trim()
            if (line === "") continue

            var lineData = parseLogLine(line)
            if (lineData) {
                lines.push(lineData)
            }
        }

        logRepeater.model = lines
    }

    function extractPlainText(html) {
        // Extract text from pre tags (IRC logs are usually in pre)
        var preStart = html.indexOf("<pre>")
        var preEnd = html.indexOf("</pre>")

        if (preStart !== -1 && preEnd !== -1) {
            var content = html.substring(preStart + 5, preEnd)
            // Decode HTML entities
            content = content.replace(/&lt;/g, "<")
            content = content.replace(/&gt;/g, ">")
            content = content.replace(/&amp;/g, "&")
            content = content.replace(/&quot;/g, '"')
            return content
        }

        return ""
    }

    function parseLogLine(line) {
        // Format: HH:MM:SS <username> message
        // or: HH:MM:SS * username action
        var timestampRegex = /^(\d{2}:\d{2}:\d{2})\s+(.+)$/
        var match = line.match(timestampRegex)

        if (!match) return null

        var timestamp = match[1]
        var rest = match[2]

        var color = Theme.primaryColor
        var formattedText = ""

        // Check for username in angle brackets
        var userRegex = /^<([^>]+)>\s+(.+)$/
        var userMatch = rest.match(userRegex)

        if (userMatch) {
            var username = userMatch[1]
            var message = userMatch[2]

            formattedText = "<font color='" + Theme.secondaryColor + "'>" + timestamp + "</font> " +
                           "<font color='" + Theme.highlightColor + "'><b>&lt;" + username + "&gt;</b></font> " +
                           message
        }
        // Check for action (* username does something)
        else if (rest.indexOf("* ") === 0) {
            formattedText = "<font color='" + Theme.secondaryColor + "'>" + timestamp + "</font> " +
                           "<font color='" + Theme.secondaryHighlightColor + "'><i>" + rest + "</i></font>"
        }
        // MeetBot commands or other lines
        else {
            formattedText = "<font color='" + Theme.secondaryColor + "'>" + timestamp + "</font> " +
                           "<font color='" + Theme.primaryColor + "'>" + rest + "</font>"
        }

        return {
            text: formattedText,
            color: color
        }
    }
}
