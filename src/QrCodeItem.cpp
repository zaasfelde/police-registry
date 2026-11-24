#include "QrCodeItem.h"

#include "third_party/qrcodegen.hpp"

#include <QDebug>
#include <QPainter>

QrCodeItem::QrCodeItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(false);
    setSmooth(false);
}

void QrCodeItem::setData(const QString &data)
{
    if (m_data == data)
        return;
    m_data = data;
    regenerate();
    emit dataChanged();
}

void QrCodeItem::setForeground(const QColor &color)
{
    if (m_foreground == color)
        return;
    m_foreground = color;
    regenerate();
    emit foregroundChanged();
}

void QrCodeItem::setBackground(const QColor &color)
{
    if (m_background == color)
        return;
    m_background = color;
    regenerate();
    emit backgroundChanged();
}

void QrCodeItem::regenerate()
{
    m_image = QImage();
    if (m_data.trimmed().isEmpty()) {
        update();
        return;
    }

    try {
        const qrcodegen::QrCode qr = qrcodegen::QrCode::encodeText(
            m_data.toUtf8().constData(), qrcodegen::QrCode::Ecc::MEDIUM);
        const int modules = qr.getSize();
        const int quietZone = 4;
        const int scale = 8;
        const int pixelSize = (modules + quietZone * 2) * scale;

        QImage image(pixelSize, pixelSize, QImage::Format_RGB32);
        image.fill(m_background);

        QPainter painter(&image);
        painter.setPen(Qt::NoPen);
        painter.setBrush(m_foreground);
        for (int y = 0; y < modules; ++y) {
            for (int x = 0; x < modules; ++x) {
                if (!qr.getModule(x, y))
                    continue;
                painter.drawRect((x + quietZone) * scale,
                                 (y + quietZone) * scale,
                                 scale,
                                 scale);
            }
        }
        painter.end();
        m_image = image;
    } catch (const std::exception &exception) {
        qWarning() << "Не удалось построить QR-код:" << exception.what();
        m_image = QImage();
    }

    update();
}

void QrCodeItem::paint(QPainter *painter)
{
    if (m_image.isNull()) {
        painter->fillRect(boundingRect(), m_background);
        return;
    }
    painter->setRenderHint(QPainter::SmoothPixmapTransform, false);
    painter->drawImage(boundingRect(), m_image);
}
