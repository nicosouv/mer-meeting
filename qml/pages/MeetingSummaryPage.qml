import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mer.meeting 1.0

Page {
    id: page

    property var meeting
    property string htmlContent: ""

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        meetingManager.fetchHtmlContent(meeting.url)
    }

    Connections {
        target: meetingManager
        onHtmlContentLoaded: {
            htmlContent = content
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("View full IRC log")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("MeetingLogPage.qml"), {
                        meeting: meeting
                    })
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: meetingManager.fetchHtmlContent(meeting.url)
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: meeting.title
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: meeting.date + " - " + meeting.time
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
            }

            Item { width: 1; height: Theme.paddingLarge }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: htmlContent === ""
                size: BusyIndicatorSize.Large
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: htmlContent !== ""
                text: formatHtmlContent(htmlContent)
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                linkColor: Theme.highlightColor
                onLinkActivated: Qt.openUrlExternally(link)
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }

    function formatHtmlContent(html) {
        if (html === "") return ""

        // Extract content between body tags
        var bodyStart = html.indexOf("<body>")
        var bodyEnd = html.indexOf("</body>")
        if (bodyStart === -1 || bodyEnd === -1) return html

        var content = html.substring(bodyStart + 6, bodyEnd)

        // Clean up some HTML tags for better QML Label rendering
        content = content.replace(/<h1>/g, "<h1><font size='5'><b>")
        content = content.replace(/<\/h1>/g, "</b></font></h1>")
        content = content.replace(/<h2>/g, "<h2><font size='4'><b>")
        content = content.replace(/<\/h2>/g, "</b></font></h2>")
        content = content.replace(/<h3>/g, "<h3><font size='3'><b>")
        content = content.replace(/<\/h3>/g, "</b></font></h3>")

        // Add some spacing
        content = content.replace(/<\/li>/g, "</li><br/>")
        content = content.replace(/<\/p>/g, "</p><br/>")

        return content
    }
}
