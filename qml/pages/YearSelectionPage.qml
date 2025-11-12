import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Nemo.Notifications 1.0

Page {
    id: page

    allowedOrientations: Orientation.All

    property string nextMeetingDate: ""
    property string nextMeetingDateRaw: ""

    Component.onCompleted: {
        // Load saved date first
        nextMeetingDate = meetingManager.getNextMeetingDate()
        console.log("Loaded saved next meeting date:", nextMeetingDate)

        // Always fetch fresh data to check for new meetings
        // This ensures we always have the most recent meeting's next date
        console.log("Fetching fresh next meeting date...")
        meetingManager.fetchNextMeetingDate()
    }

    Connections {
        target: meetingManager
        onNextMeetingDateChanged: {
            nextMeetingDate = date
            nextMeetingDateRaw = rawDate
        }
    }

    function addToCalendar() {
        if (nextMeetingDateRaw === "") {
            console.log("No raw date available")
            return
        }

        console.log("Adding to calendar with date:", nextMeetingDateRaw)

        // Parse the ISO date format: 2024-11-28T0800Z
        // Need to insert colon in time: 2024-11-28T08:00Z
        var formattedDate = nextMeetingDateRaw.replace(/T(\d{2})(\d{2})Z/, "T$1:$2Z")
        console.log("Formatted date for parsing:", formattedDate)

        var dateTime = new Date(formattedDate)
        console.log("Parsed datetime:", dateTime)

        // Meeting usually lasts 1 hour
        var endTime = new Date(dateTime.getTime() + 60 * 60 * 1000)

        // Get the default notebook UID
        var notebooks = Calendar.notebooks
        var defaultNotebookUid = ""

        console.log("Found", notebooks.length, "notebooks")

        for (var i = 0; i < notebooks.length; i++) {
            console.log("Notebook:", notebooks[i].uid, notebooks[i].name, "default:", notebooks[i].isDefault)
            if (notebooks[i].isDefault) {
                defaultNotebookUid = notebooks[i].uid
                break
            }
        }

        // If no default, use the first one
        if (defaultNotebookUid === "" && notebooks.length > 0) {
            defaultNotebookUid = notebooks[0].uid
        }

        console.log("Using notebook UID:", defaultNotebookUid)

        // Create event with all properties at once
        var event = Calendar.createNewEvent(
            defaultNotebookUid,
            "Sailfish OS Community Meeting",
            "Monthly community meeting to discuss Sailfish OS development and topics",
            dateTime,
            endTime,
            false  // allDay
        )

        if (event) {
            event.location = "IRC: #sailfishos-meeting on libera.chat"
            event.save()
            console.log("Event saved successfully")

            // Show confirmation
            calendarNotification.publish()
        } else {
            console.log("Failed to create event")
        }
    }

    Notification {
        id: calendarNotification
        appName: "SFOS Meetings"
        summary: qsTr("Added to calendar")
        body: qsTr("The next meeting has been added to your calendar")
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }

        header: Column {
            width: parent.width

            PageHeader {
                title: qsTr("Sailfish OS Meetings")
            }

            Item {
                width: parent.width
                height: nextMeetingDate !== "" ? nextMeetingBanner.height : 0
                visible: nextMeetingDate !== ""

                Rectangle {
                    id: nextMeetingBanner
                    width: parent.width
                    height: nextMeetingColumn.height + Theme.paddingLarge * 2
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.2)

                    Column {
                        id: nextMeetingColumn
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingLarge
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        spacing: Theme.paddingSmall

                        Row {
                            width: parent.width
                            spacing: Theme.paddingMedium

                            Label {
                                text: qsTr("Next Meeting")
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.highlightColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Button {
                                text: qsTr("Add to Calendar")
                                preferredWidth: Theme.buttonWidthSmall
                                onClicked: addToCalendar()
                            }
                        }

                        Label {
                            text: nextMeetingDate
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primaryColor
                            wrapMode: Text.Wrap
                            width: parent.width
                        }
                    }
                }
            }
        }

        model: meetingManager.getAvailableYears()

        delegate: BackgroundItem {
            id: delegate
            width: listView.width
            height: Theme.itemSizeLarge

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    text: modelData
                    font.pixelSize: Theme.fontSizeExtraLarge
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Label {
                    text: qsTr("View meetings from %1").arg(modelData)
                    font.pixelSize: Theme.fontSizeSmall
                    color: delegate.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            onClicked: {
                pageStack.push(Qt.resolvedUrl("MeetingListPage.qml"), { year: modelData })
            }
        }

        VerticalScrollDecorator {}
    }
}
