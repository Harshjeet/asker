 
/*
    Forked By :- Harshjeet Kumar
*/

import QtQuick 2.1
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.19 as Kirigami
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

Item {
    id: root
    focus: true

    property string parentMessageId: ''
    property var listModelController;
    property string introText: ""
    property var xhr; // The XMLHttpRequest object
    property bool xhrFinished: true; // Flag to indicate if the request is finished or not


    // Signals to handle the XMLHttpRequest state changes
    signal onRequestStarted();
    signal onRequestFinished();


    function request(messageField, listModel, scrollView, prompt) {
        messageField.text = '';

        listModel.append({
            "name": "User",
            "number": prompt
        });

        if (scrollView.ScrollBar) {
            scrollView.ScrollBar.vertical.position = 1;
        }

        const oldLength = listModel.count;
        const url = 'https://chatbot.theb.ai/api/chat-process';
        const data = JSON.stringify({
            "prompt": prompt,
            "options": {
                "parentMessageId": parentMessageId
            }
        });
        
        xhr = new XMLHttpRequest();
        xhrFinished = false;

        xhr.open('POST', url, true);
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.onreadystatechange = function() {
            const objects = xhr.responseText.split('\n');
            const lastObject = objects[objects.length - 1];
            const parsedObject = JSON.parse(lastObject);
            const text = parsedObject.text;

            parentMessageId = parsedObject.id;

            if (scrollView.ScrollBar) {
                scrollView.ScrollBar.vertical.position = 1 - scrollView.ScrollBar.vertical.size;
            }

            if (listModel.count === oldLength) {
                listModel.append({
                    "name": "ChatGTP",
                    "number": text
                });
            } else {
                const lastValue = listModel.get(oldLength);

                lastValue.number = text;
            }

            if (xhr.readyState === XMLHttpRequest.DONE) {
                xhrFinished = true; // Set the flag to indicate that the request is finished
                onRequestFinished(); // Emit the signal that the request has finished
            }   
            
        }

        xhr.send(data);
        OnRequestStarted();
    }

    function action_clearChat() {
        listModelController.clear();
    }

    Component.onCompleted: {
        Plasmoid.setAction("clearChat", i18n("Clear chat"), "edit-clear");
        welcomeText();

        onRequestStarted.connect(function() {
            // When the request starts, hide the "Stop" button and show the "Send" button
            stopButton.visible = true;
            sendButton.visible = false;
        });

        onRequestFinished.connect(function() {
            // When the request finishes, hide the "Stop" button and show the "Send" button
            stopButton.visible = false;
            sendButton.visible = true;
        });


    }

    function welcomeText(){
        var currentTime = new Date().getHours()
        if (currentTime >= 4 && currentTime < 12) {
            introText = i18n("Hi ...Good Morning.")
        }
        else if (currentTime >= 12 && currentTime < 17) {
            introText = i18n("Hi ...Good afternoon.")
        } 
        else if (currentTime >= 17 && currentTime < 22){
            introText = i18n("Hi ...Good evening.")
        }
        else {
            introText = i18n("Hi ... Good Night.          Sleep well")
        }
    }

        //Timer to update introtext every minute
    Timer {
        interval: 60000
        repeat: true
        onTriggered: {
            welcomeText();    
        }
    }

    Plasmoid.fullRepresentation: ColumnLayout {
        Layout.preferredHeight: 400
        Layout.preferredWidth: 350
        Layout.fillWidth: true
        Layout.fillHeight: true

        ScrollView {
            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
            clip: true

            ListView {
                id: listView

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - (Kirigami.Units.largeSpacing * 4)
                    visible: listView.count === 0
                    text: root.introText
                }

                model: ListModel {
                    id: listModel

                    Component.onCompleted: {
                        listModelController = listModel;
                    }
                }

                delegate: Kirigami.AbstractCard {
                    Layout.fillWidth: true

                    contentItem: TextEdit {
                        readOnly: true
                        wrapMode: Text.WordWrap
                        text: number
                        color: name === "User" ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
                        selectByMouse: true
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            clip: true
            rightPadding: 0

            TextArea {
                id: messageField

                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: i18n("what do you want to know?...")
                Keys.onReturnPressed: {
                    if (event.modifiers & Qt.ControlModifier) {
                        request(messageField, listModel, scrollView, messageField.text);
                    } else {
                        event.accepted = false;
                    }
                }
            }
        }
        
        //layout position
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottomRight
            spacing: Kirigami.Units.smallSpacing

            //send button
            Button {
                text: "Send"
                hoverEnabled: true
                ToolTip.delay: 1000
                ToolTip.visible: hovered
                ToolTip.text: "CTRL+Enter"
                onClicked: {
                    request(messageField, listModel, scrollView, messageField.text);
                }
            }

            Item {
                Layout.fillWidth: true
            }


            // Stop button
            Button {
                id: stopButton
                text: "Stop"
                visible: !xhrFinished
                onClicked: {
                    xhr.abort();
                }
            }

            //clear button
            Button {
                text: i18n("Clear")
                ToolTip.visible: hovered
                ToolTip.text: "Clear"
                Keys.onPressed: {
                    if (event.key === Qt.Key_C && event.modifiers & Qt.ControlModifier && event.modifiers & Qt.ShiftModifier) {
                        action_clearChat();
                    }
                }
                onClicked: {
                    action_clearChat();
                }   
            }


        }   
    }

}
