/* Electron Linux installer slideshow (Calamares slideshow API 2) */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 7000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    function onActivate() { presentation.currentSlide = 0 }
    function onLeave() { }

    component Card: Slide {
        property string heading: ""
        property string body: ""
        Rectangle { anchors.fill: parent; color: "#0b1020" }
        Image {
            id: logo
            source: "logo.png"
            width: 120; height: 120
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 40
        }
        Text {
            id: title
            text: heading
            color: "#ffffff"
            font.pixelSize: 28; font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom; anchors.topMargin: 24
        }
        Text {
            text: body
            color: "#b8c7e0"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.75
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title.bottom; anchors.topMargin: 16
        }
    }

    Card { heading: "Welcome to Electron Linux"; body: "A clean, minimal Arch-based system. Nothing you didn't ask for, and no telemetry." }
    Card { heading: "Hyprland desktop"; body: "Super+Enter opens a terminal, Super+D the app launcher, Super+1-5 switches workspaces." }
    Card { heading: "Always up to date"; body: "Rolling releases straight from the official Arch repositories. Update anytime with: sudo pacman -Syu" }
    Card { heading: "Make it yours"; body: "Configs live in ~/.config: hypr, waybar, kitty and wofi. Thousands of packages are a pacman -S away." }
    Card { heading: "Almost there"; body: "Copying files and setting up your system. You can restart when the installer finishes." }
}
