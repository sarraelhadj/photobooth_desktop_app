import QtQuick

// Icon.qml — small outline icons drawn with Canvas, so the kiosk doesn't
// depend on an icon font being installed. Paths are on a 24x24 grid and
// scale to the item's size.
//
//   Icon { name: "printer"; color: Theme.fg }
//
// Names: printer, back, camera, mail, chat, chevron, sparkle, sparkleFilled,
//        photos, people
Canvas {
    id: icon
    property string name
    property color color: "white"
    property real strokeWidth: 1.8

    width: 20
    height: 20
    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function star(ctx, cx, cy, r) {
        var k = r * 0.28
        ctx.beginPath()
        ctx.moveTo(cx, cy - r)
        ctx.quadraticCurveTo(cx + k, cy - k, cx + r, cy)
        ctx.quadraticCurveTo(cx + k, cy + k, cx, cy + r)
        ctx.quadraticCurveTo(cx - k, cy + k, cx - r, cy)
        ctx.quadraticCurveTo(cx - k, cy - k, cx, cy - r)
        ctx.closePath()
    }

    function roundRect(ctx, x, y, w, h, r) {
        ctx.beginPath()
        ctx.moveTo(x + r, y)
        ctx.lineTo(x + w - r, y); ctx.quadraticCurveTo(x + w, y, x + w, y + r)
        ctx.lineTo(x + w, y + h - r); ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
        ctx.lineTo(x + r, y + h); ctx.quadraticCurveTo(x, y + h, x, y + h - r)
        ctx.lineTo(x, y + r); ctx.quadraticCurveTo(x, y, x + r, y)
        ctx.closePath()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var s = Math.min(width, height) / 24
        ctx.scale(s, s)
        ctx.strokeStyle = color
        ctx.fillStyle = color
        ctx.lineWidth = strokeWidth / s
        ctx.lineCap = "round"
        ctx.lineJoin = "round"

        switch (name) {
        case "printer":
            ctx.strokeRect(7, 3, 10, 6)
            ctx.beginPath()
            ctx.moveTo(7, 17); ctx.lineTo(4, 17)
            ctx.quadraticCurveTo(3, 17, 3, 16)
            ctx.lineTo(3, 10); ctx.quadraticCurveTo(3, 9, 4, 9)
            ctx.lineTo(20, 9); ctx.quadraticCurveTo(21, 9, 21, 10)
            ctx.lineTo(21, 16); ctx.quadraticCurveTo(21, 17, 20, 17)
            ctx.lineTo(17, 17)
            ctx.stroke()
            ctx.strokeRect(7, 14, 10, 7)
            break
        case "back":
            ctx.beginPath()
            ctx.moveTo(20, 12); ctx.lineTo(4, 12)
            ctx.moveTo(10, 6); ctx.lineTo(4, 12); ctx.lineTo(10, 18)
            ctx.stroke()
            break
        case "camera":
            roundRect(ctx, 2.5, 7, 19, 13, 2.5)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(8, 7); ctx.lineTo(9.5, 4.5); ctx.lineTo(14.5, 4.5); ctx.lineTo(16, 7)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 13.5, 3.5, 0, 2 * Math.PI)
            ctx.stroke()
            break
        case "mail":
            roundRect(ctx, 3, 5.5, 18, 13, 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(3.5, 7); ctx.lineTo(12, 13); ctx.lineTo(20.5, 7)
            ctx.stroke()
            break
        case "chat":
            ctx.beginPath()
            ctx.moveTo(7, 19.5)
            ctx.lineTo(3.5, 20.5)
            ctx.lineTo(4.6, 16.8)
            ctx.arc(12, 12, 8.5, Math.PI * 0.85, Math.PI * 0.62 + 2 * Math.PI, false)
            ctx.closePath()
            ctx.stroke()
            break
        case "chevron":
            ctx.beginPath()
            ctx.moveTo(9, 5); ctx.lineTo(16, 12); ctx.lineTo(9, 19)
            ctx.stroke()
            break
        case "sparkle":
            star(ctx, 10, 13, 8); ctx.stroke()
            star(ctx, 19, 4.5, 3); ctx.stroke()
            star(ctx, 4, 21, 2); ctx.stroke()
            break
        case "photos":
            roundRect(ctx, 7, 3, 14, 14, 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(4, 7); ctx.lineTo(4, 18.5)
            ctx.quadraticCurveTo(4, 20, 5.5, 20); ctx.lineTo(17, 20)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(9, 15); ctx.lineTo(13, 10.5); ctx.lineTo(16, 13.5); ctx.lineTo(19, 11)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(11, 7.5, 1.3, 0, 2 * Math.PI)
            ctx.stroke()
            break
        case "people":
            ctx.beginPath()
            ctx.arc(9, 8, 3.5, 0, 2 * Math.PI)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(2.5, 20); ctx.quadraticCurveTo(3, 13.5, 9, 13.5)
            ctx.quadraticCurveTo(15, 13.5, 15.5, 20)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(16.5, 7.5, 2.8, -Math.PI * 0.6, Math.PI * 0.6)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(17.5, 13.3); ctx.quadraticCurveTo(21.3, 14.3, 21.5, 19)
            ctx.stroke()
            break
        case "sparkleFilled":
            star(ctx, 12, 12, 11); ctx.fill()
            break
        }
    }
}
