#ifndef QRCODEITEM_H
#define QRCODEITEM_H

#include <QColor>
#include <QImage>
#include <QQuickPaintedItem>
#include <QtQml/qqmlregistration.h>

/*
 * Небольшой QML-элемент, рисующий QR-код для otpauth-ссылки.
 * Используется на экране настройки двухфакторной аутентификации.
 */
class QrCodeItem : public QQuickPaintedItem
{
    Q_OBJECT
    QML_NAMED_ELEMENT(QrCode)
    Q_PROPERTY(QString qrData READ qrData WRITE setQrData NOTIFY qrDataChanged)
    Q_PROPERTY(QColor foreground READ foreground WRITE setForeground NOTIFY foregroundChanged)
    Q_PROPERTY(QColor background READ background WRITE setBackground NOTIFY backgroundChanged)

public:
    explicit QrCodeItem(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    QString qrData() const { return m_qrData; }
    void setQrData(const QString &data);

    QColor foreground() const { return m_foreground; }
    void setForeground(const QColor &color);

    QColor background() const { return m_background; }
    void setBackground(const QColor &color);

signals:
    void qrDataChanged();
    void foregroundChanged();
    void backgroundChanged();

private:
    void regenerate();

    QString m_qrData;
    QImage m_image;
    QColor m_foreground = QColor(QStringLiteral("#0B1F35"));
    QColor m_background = Qt::white;
};

#endif // QRCODEITEM_H
