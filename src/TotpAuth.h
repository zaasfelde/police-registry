#ifndef TOTPAUTH_H
#define TOTPAUTH_H

#include <QByteArray>
#include <QString>

/*
 * Минимальная реализация TOTP (RFC 6238) на HMAC-SHA1 — именно этот
 * алгоритм ожидает Google Authenticator / Aegis / 1Password и другие
 * стандартные приложения-аутентификаторы.
 */
class TotpAuth
{
public:
    static QString generateSecret(int bytes = 20);
    static QString base32Encode(const QByteArray &data);
    static QByteArray base32Decode(const QString &text);

    static QString codeFor(const QByteArray &secret, qint64 unixSeconds, int digits = 6, int period = 30);
    static bool verify(const QString &base32Secret, const QString &code, int window = 1, int period = 30);
    static QString otpauthUri(const QString &base32Secret,
                              const QString &account,
                              const QString &issuer = QStringLiteral("Police Registry"));

    static QString generateRecoveryCode();
    static QString normalizeRecoveryCode(const QString &code);
    static QByteArray hashRecoveryCode(const QString &code);
};

#endif // TOTPAUTH_H
