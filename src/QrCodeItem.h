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
    Q_PROPERTY(QString data READ data WRITE setData NOTIFY dataChanged)
    Q_PROPERTY(QColor foreground READ foreground WRITE setForeground NOTIFY foregroundChanged)
    Q_PROPERTY(QColor background READ background WRITE setBackground NOTIFY backgroundChanged)

public:
    explicit QrCodeItem(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    QString data() const { return m_data; }
    void setData(const QString &data);

    QColor foreground() const { return m_foreground; }
    void setForeground(const QColor &color);

    QColor background() const { return m_background; }
    void setBackground(const QColor &color);

signals:
    void dataChanged();
    void foregroundChanged();
    void backgroundChanged();

private:
    void regenerate();

    QString m_data;
    QImage m_image;
    QColor m_foreground = QColor(QStringLiteral("#0B1F35"));
    QColor m_background = Qt::white;
};

#endif // QRCODEITEM_H
