pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.Pam
import Quickshell.Services.UPower

ShellRoot {
    id: root

    property int barHeight: 32
    property int barTextSize: 14
    property color backgroundColor: "#00000000"
    property color foregroundColor: "#ffeeeeee"
    property color foregroundDimColor: "#cc999999"

    property bool isLocked: false
    // The lock object is created lazily on first use and then kept
    // alive: the session lock protocol forbids destroying a locked
    // lock object, so unlocking is done via `locked = false` and the
    // (cheap, surface-less) object is reused for the next lock cycle.
    property bool lockCreated: false

    onIsLockedChanged: {
        if (root.isLocked)
            root.lockCreated = true;
    }

    IpcHandler {
        target: "session"

        function lock(): void {
            root.isLocked = true;
        }

        function isLocked(): bool {
            return root.isLocked;
        }

        // equivalent for `loginctl unlock-session`.
        function unlock(): void {
            root.isLocked = false;
        }
    }

    // --- COMPONENT: THE LOCK SCREEN ---
    component LockScreen: WlSessionLock {
        id: sessionLock

        // `locked` is a read/write property, there is no `onLocked`
        // signal; the "lock is fully up" state is reported by `secure`.
        // The bar is always mapped underneath (it is never destroyed),
        // so the lock can disengage the same frame it is revealed.
        locked: root.isLocked

        surface: Component {
            WlSessionLockSurface {
                color: "#11111b"

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: root.barHeight
                    color: root.backgroundColor

                    BarContent {}
                }

                TextInput {
                    id: passwordInput
                    anchors.centerIn: parent
                    color: "white"
                    font.pixelSize: 24
                    focus: true
                    echoMode: TextInput.Password

                    onAccepted: {
                        pamContext.tryUnlock(text);
                        text = "";
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: passwordInput.bottom
                    anchors.topMargin: 12
                    color: "#f38ba8"
                    font.pixelSize: 14
                    text: pamContext.errorMessage
                    visible: text !== ""
                }
            }
        }

    }

    // --- PAM AUTHENTICATION ---
    // `start()` takes no arguments; the password is passed via
    // `respond()` when PAM asks for it (`pamMessage` signal).
    // `completed` receives a PamResult enum, not a bool.
    // NOTE: kept at ShellRoot level, because `surface` is WlSessionLock's
    // DEFAULT property: any child declared inside WlSessionLock would be
    // silently assigned to `surface` and break the lock screen.
    PamContext {
        id: pamContext

        property string password: ""
        property string errorMessage: ""

        // Use our own service config shipped next to this file: the
        // default "quickshell" service has no config on this system,
        // and reusing /etc/pam.d/swaylock fails (PAM_PERM_DENIED) for
        // an unprivileged session. pam.conf mirrors base-auth.
        configDirectory: Quickshell.shellDir
        config: "pam.conf"

        onPamMessage: {
            if (responseRequired) {
                respond(password);
                password = "";
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                errorMessage = "";
                // Initiate the unlock transition. The lock stays
                // engaged until the bar is visible again.
                root.isLocked = false;
            } else {
                errorMessage = "Authentication failed";
            }
        }

        onError: errorMessage = "PAM error"

        function tryUnlock(pw: string): void {
            if (active)
                return;
            errorMessage = "";
            password = pw;
            if (!start())
                errorMessage = "Failed to start PAM";
        }
    }

    Loader {
        id: lockLoader
        active: root.lockCreated

        sourceComponent: LockScreen {}
    }

    // --- NOTIFICATION SERVER ---
    NotificationServer {
        id: notificationServer

        // Avoid markup issues in Text elements
        bodyMarkupSupported: false

        onNotification: notification => {
            // Keep all notifications alive and tracked in the list
            notification.tracked = true;
        }
    }

    component NotificationCard: Rectangle {
        id: card

        required property var notification

        implicitHeight: cardLayout.implicitHeight + 16
        color: "#2e2e3e"
        radius: 6
        border.color: "#3e3e4e"
        border.width: 1

        GridLayout {
            id: cardLayout
            columns: 2
            anchors.fill: parent
            //spacing: 3
            Text {
                Layout.rowSpan: 2
                text: "✕"
                color: root.foregroundDimColor
                font.pixelSize: 12
                MouseArea {
                    anchors.fill: parent
                    onClicked: notification.dismiss()
                }
            }
            //anchors.margins: 8
            //spacing: 4

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Text {
                    text: notification.appIcon !== "" ? "📦" : "📩"
                    font.pixelSize: 14
                    width: 14
                }

                Text {
                    //Layout.fillWidth: true
                    text: notification.summary
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

            }

            Text {
                Layout.fillWidth: true
                text: notification.body
                color: "#cccccc"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: notification.dismiss()
        }
    }

    // --- NOTIFICATION POPUP (per screen) ---
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors.top: true
            anchors.right: true
            margins.top: root.barHeight

            // Don't claim exclusive zone to avoid pushing the bar away
            exclusionMode: ExclusionMode.Ignore

            visible: notificationServer.trackedNotifications.values.length > 0
            color: "#dd1e1e2e"
            // Height driven by content column
            implicitHeight: notifColumn.implicitHeight + 8

            ColumnLayout {
                id: notifColumn
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Repeater {
                    model: notificationServer.trackedNotifications

                    delegate: NotificationCard {
                        required property var modelData
                        notification: modelData
                    }
                }
            }
        }
    }

    // Actual bar -------------------------------------------------------------

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: wifiPoller

        property bool interfaceSeen: false

        property string ssid: ""
        property int rssi: 0

        readonly property bool connected: ssid !== ""

        Process {
            id: apProcess
            command: ["sh", "-lic", "apinfo"]

            stdout: StdioCollector {}

            onExited: (code, status) => {
                if (code !== 0)
                    return // transient failure: keep last state
                const parts = apProcess.stdout.text
                .split("\n")
                .filter(s => s.length > 0)
                [0]?.split("\t")
                if (parts?.length != 5) {
                    wifiPoller.ssid = ""
                    wifiPoller.rssi = 0
                    return
                }
                wifiPoller.ssid = parts[4]
                wifiPoller.rssi = parseInt(parts[2], 10)
                wifiPoller.interfaceSeen = true
            }
        }

        Timer {
            interval: 3000
            repeat: true
            running: true
            onTriggered: apProcess.running = true
        }

        Component.onCompleted: apProcess.running = true
    }

    component BarContent: Item {
        anchors.fill: parent
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 20

            Text {
                id: label
                color: root.foregroundColor
                font.pixelSize: root.barTextSize
                visible: root.isLocked
                text: "Locked"
            }
            Item {
                Layout.fillWidth: true
            }

            WifiIndicator {}

            BatteryIndicator {}

            Text {
                textFormat: Text.RichText
                text: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
                + '&nbsp;&nbsp;<b>'
                + Qt.formatDateTime(clock.date, "HH:mm")
                + '</b>'
                color: 'white'
                font.pixelSize: root.barTextSize
            }
        }
    }

    component WifiIndicator: RowLayout {
        id: wifiIndicator
        spacing: 5

        // Rendered from the shared root-scope poller (see wifiPoller):
        // the poll itself is not restarted when this instance is
        // respawned.
        readonly property color wifiColor: wifiPoller.connected
        ? root.foregroundColor
        : root.foregroundDimColor

        visible: wifiPoller.interfaceSeen

        Canvas {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 12

            property color paintColor: wifiIndicator.wifiColor

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = paintColor
                ctx.fillStyle = paintColor
                ctx.lineWidth = 2.3
                const cx = width / 2
                const cy = height - 1.5
                for (let r = 0; r <= 1; r += 1) {
                    ctx.beginPath()
                    ctx.arc(
                        cx,
                        cy,
                        r * (ctx.lineWidth * 1.5) + (ctx.lineWidth * 2.5),
                        Math.PI * 1.25,
                        Math.PI * 1.75
                    )
                    ctx.stroke()
                }

                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.arc(cx, cy, ctx.lineWidth * 1.5, Math.PI * 1.25, Math.PI * 1.75)
                ctx.fill()
            }

            // Repaint when the tint (connected state) changes.
            onPaintColorChanged: requestPaint()
        }

        Text {
            text: wifiPoller.ssid
            color: root.foregroundColor
            font.pixelSize: root.barTextSize
        }
    }

    component BatteryIndicator: RowLayout {
        id: batteryIndicator
        spacing: 5

        readonly property var batteryDevice: UPower.displayDevice

        readonly property bool hasBattery: !!batteryDevice
        readonly property real level: hasBattery
        ? batteryDevice.percentage : 0
        readonly property bool charging: hasBattery
        && (batteryDevice.state === UPowerDeviceState.Charging
            || batteryDevice.state === UPowerDeviceState.FullyCharged
            || batteryDevice.state === UPowerDeviceState.PendingCharge)

        // Pink when it's low and draining, otherwise matches the bar text.
        readonly property color tint: hasBattery && !charging && level < 0.2
        ? "red"
        : root.foregroundColor

        visible: hasBattery

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: root.barTextSize * 0.8

            Rectangle {
                anchors.fill: parent
                color: root.backgroundColor
                anchors.rightMargin: 1
                anchors.bottomMargin: 2
                border.color: root.foregroundDimColor
                border.width: 1
                radius: 2

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    anchors.rightMargin: (parent.width - 4) * (1 - batteryIndicator.level) + 2
                    width: (parent.width) * batteryIndicator.level
                    height: parent.height - 4
                    color: batteryIndicator.tint
                    visible: batteryIndicator.level > 0
                }
            }

            Rectangle {
                anchors.left: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.85 / 2
                width: 1
                height: parent.height * 0.3
                color: root.foregroundDimColor
            }
        }

        Text {
            text: batteryIndicator.charging ? "⚡" : ""
            color: root.foregroundColor
            font.pixelSize: root.barTextSize
            visible: text !== ""
        }

        Text {
            text: Math.round(batteryIndicator.level * 100)
            color: batteryIndicator.tint
            font.pixelSize: root.barTextSize
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true
            implicitHeight: root.barHeight
            color: root.backgroundColor

            Loader {
                anchors.fill: parent
                active: !root.isLocked

                sourceComponent: Component {
                    BarContent {}
                }
            }
        }
    }
}
