// SwitchOS

import QtQuick 2.0
import SortFilterProxyModel 0.2
import QtMultimedia 5.9
import "qrc:/qmlutils" as PegasusUtils
import "utils.js" as Utils
import "layer_platform"
import "layer_grid"
import "layer_help"

FocusScope
{
    id: root
    property int collectionIndex: 0
    property int currentGameIndex: 0
    property int screenmargin: vpx(30)
    property real screenwidth: width
    property real screenheight: height
    property bool widescreen: ((height/width) < 0.7)
    property real helpbarheight: Math.round(screenheight * 0.1041) // Calculated manually based on mockup
    property bool darkThemeActive

    function modulo(a,n) {
        return (a % n + n) % n;
    }

    function nextCollection () {
        jumpToCollection(collectionIndex + 1);
    }

    function prevCollection() {
        jumpToCollection(collectionIndex - 1);
    }

    function jumpToCollection(idx) {
        api.memory.set('gameCollIndex' + collectionIndex, currentGameIndex); // save game index of current collection
        collectionIndex = modulo(idx, api.collections.count); // new collection index
        currentGameIndex = 0; // Jump to the top of the list each time collection is changed
    }

    function showSoftwareScreen()
    {
        /*platformScreen.visible = false;
        softwareScreen.visible = true;*/
        softwareScreen.focus = true;
        toSoftware.play();
    }

    function showHomeScreen()
    {
        platformScreen.focus = true;
        backSfx.play();
        /*platformScreen.visible = true;
        softwareScreen.visible = false;*/
        //platformScreen.focus = true;
    }

    function playGame()
    {
        root.state = "playgame"

        launchSfx.play()
    }

    function launchGame()
    {
        api.collections.get(collectionIndex).games.get(currentGameIndex).launch();
    }

    // Theme settings
    FontLoader { id: titleFont; source: "fonts/Nintendo_Switch_UI_Font.ttf" }

    property var themeLight: {
        return {
            main: "#EBEBEB",
            secondary: "#2D2D2D",
            accent: "#10AEBE",
            highlight: "white",
            text: "#2C2C2C",
            button: "white"
        }
    }

    property var themeDark: {
        return {
            main: "#272727",
            secondary: "#CCCCCC",
            accent: "#28CDC8",
            highlight: "white",
            text: "#CCCCCC",
            button: "#303030"
        }
    }

    // Do this properly later
    property var theme: {
        return {
            main: api.memory.get('themeBG') || themeDark.main,
            secondary: api.memory.get('themeSecondary') || themeDark.secondary,
            accent: api.memory.get('themeAccent') || themeDark.accent,
            highlight: api.memory.get('themeHighlight') || themeDark.highlight,
            text: api.memory.get('themeText') || themeDark.text,
            button: api.memory.get('themeButton') || themeDark.button
        }
    }

    function swapTheme() {
        if (darkThemeActive) {
            darkThemeActive = false;
            theme.main = themeLight.main;
        } else {
            darkThemeActive = true;
            theme.main = themeDark.main;
        }
    }

    // State settings
    states: [
        State {
            name: "platformscreen"; when: platformScreen.focus == true
        },
        State {
            name: "softwarescreen"; when: softwareScreen.focus == true
        },
        State {
            name: "playgame";
        }
    ]

    transitions: [
        Transition {
            from: "platformscreen"; to: "softwarescreen"
            SequentialAnimation {
                PropertyAnimation { target: platformScreen; property: "opacity"; to: 0; duration: 200}
                PropertyAction { target: platformScreen; property: "visible"; value: false }
                PropertyAction { target: softwareScreen; property: "visible"; value: true }
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 1; duration: 200}
            }
        },
        Transition {
            from: "softwarescreen"; to: "platformscreen"
            SequentialAnimation {
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 200}
                PropertyAction { target: softwareScreen; property: "visible"; value: false }
                PropertyAction { target: platformScreen; property: "visible"; value: true }
                PropertyAnimation { target: platformScreen; property: "opacity"; to: 1; duration: 200}
            }
        },
        Transition {
            to: "playgame"
            SequentialAnimation {
                PropertyAnimation { target: softwareScreen; property: "opacity"; to: 0; duration: 200}
                PauseAnimation { duration: 200 }
                ScriptAction { script: launchGame() }
            }
        },
        Transition {
            from: ""; to: "platformscreen"
            ParallelAnimation {
                NumberAnimation { target: platformScreen; property: "scale"; from: 1.2; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                NumberAnimation { target: platformScreen; property: "opacity"; from: 0; to: 1; duration: 200 }
            }
        }
    ]


    // Background
    Rectangle {
        id: background
        anchors
        {
            left: parent.left; right: parent.right
            top: parent.top; bottom: parent.bottom
        }
        color: theme.main
    }

    Component.onCompleted: {
        state: "platformscreen"
        homeSfx.play()
    }


    // Platform screen
    PlatformScreen
    {
        id: platformScreen
        focus: true
        anchors
        {
            left: parent.left; right: parent.right
            top: parent.top; bottom: helpBar.top
        }
    }

    // All Software screen
    SoftwareScreen {
        id: softwareScreen
        opacity: 0
        visible: false
        anchors
        {
            left: parent.left;// leftMargin: screenmargin
            right: parent.right;// rightMargin: screenmargin
            top: parent.top; bottom: helpBar.top
        }
    }


    // Help bar
    Item
    {
        id: helpBar
        anchors
        {
            left: parent.left; leftMargin: screenmargin
            right: parent.right; rightMargin: screenmargin
            bottom: parent.bottom
        }
        height: helpbarheight

        Rectangle {

            anchors.fill: parent
            color: theme.main
        }

        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right
            height: 1
            color: theme.secondary
        }

        ControllerHelp {
            id: controllerHelp
            width: parent.width
            height: parent.height
            anchors {
                bottom: parent.bottom;
            }
            showBack: !platformScreen.focus
        }

    }

    SoundEffect {
      id: navSound
      source: "assets/audio/Klick.wav"
      volume: 1.0
    }

    SoundEffect {
      id: toSoftware
      source: "assets/audio/EnterBack.wav"
      volume: 1.0
    }

    SoundEffect {
      id: fillList
      source: "assets/audio/Icons.wav"
      volume: 1.0
    }

    SoundEffect {
      id: backSfx
      source: "assets/audio/Nock.wav"
      volume: 1.0
    }

    SoundEffect {
        id: launchSfx
        source: "assets/audio/PopupRunTitle.wav"
        volume: 1.0
    }

    SoundEffect {
        id: homeSfx
        source: "assets/audio/Home.wav"
        volume: 1.0
    }

}
