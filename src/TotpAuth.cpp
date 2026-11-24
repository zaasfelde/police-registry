#include "TotpAuth.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QRandomGenerator>
#include <QUrl>
#include <QUrlQuery>
#include <cstring>

namespace {

QByteArray hmacSha1(QByteArray key, const QByteArray &message)
{
    constexpr int blockSize = 64;
    if (key.size() > blockSize)
        key = QCryptographicHash::hash(key, QCryptographicHash::Sha1);
    key = key.leftJustified(blockSize, '\0');

    QByteArray innerPad(blockSize, '\0');
    QByteArray outerPad(blockSize, '\0');
    for (int i = 0; i < blockSize; ++i) {
        innerPad[i] = static_cast<char>(key.at(i) ^ 0x36);
        outerPad[i] = static_cast<char>(key.at(i) ^ 0x5c);
    }

    const QByteArray inner = QCryptographicHash::hash(innerPad + message, QCryptographicHash::Sha1);
    return QCryptographicHash::hash(outerPad + inner, QCryptographicHash::Sha1);
}

QByteArray randomBytes(int count)
{
    QByteArray result(count, Qt::Uninitialized);
    auto *generator = QRandomGenerator::system();
    for (int i = 0; i < count; i += 4) {
        const quint32 value = generator->generate();
        const int chunk = qMin(4, count - i);
        std::memcpy(result.data() + i, &value, static_cast<size_t>(chunk));
    }
    return result;
}

const char kBase32Alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
const char kRecoveryAlphabet[] = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

} // namespace

QString TotpAuth::generateSecret(int bytes)
{
    return base32Encode(randomBytes(qMax(10, bytes)));
}

QString TotpAuth::base32Encode(const QByteArray &data)
{
    QString result;
    result.reserve((data.size() * 8 + 4) / 5);
    quint64 buffer = 0;
    int bits = 0;
    for (const char byte : data) {
        buffer = (buffer << 8) | static_cast<unsigned char>(byte);
        bits += 8;
        while (bits >= 5) {
            bits -= 5;
            result.append(QLatin1Char(kBase32Alphabet[(buffer >> bits) & 0x1f]));
        }
    }
    if (bits > 0)
        result.append(QLatin1Char(kBase32Alphabet[(buffer << (5 - bits)) & 0x1f]));
    return result;
}

QByteArray TotpAuth::base32Decode(const QString &text)
{
    QByteArray result;
    quint64 buffer = 0;
    int bits = 0;
    for (const QChar ch : text) {
        if (ch.isSpace() || ch == QLatin1Char('-') || ch == QLatin1Char('='))
            continue;
        const QChar upper = ch.toUpper();
        int value = -1;
        if (upper >= QLatin1Char('A') && upper <= QLatin1Char('Z'))
            value = upper.unicode() - 'A';
        else if (upper >= QLatin1Char('2') && upper <= QLatin1Char('7'))
            value = 26 + (upper.unicode() - '2');
        if (value < 0)
            continue;
        buffer = (buffer << 5) | static_cast<quint64>(value);
        bits += 5;
        if (bits >= 8) {
            bits -= 8;
            result.append(static_cast<char>((buffer >> bits) & 0xff));
        }
    }
    return result;
}

QString TotpAuth::codeFor(const QByteArray &secret, qint64 unixSeconds, int digits, int period)
{
    if (secret.isEmpty() || digits < 6 || digits > 8)
        return {};

    const quint64 counter = static_cast<quint64>(unixSeconds / period);
    QByteArray counterBytes(8, '\0');
    for (int i = 7; i >= 0; --i) {
        counterBytes[i] = static_cast<char>(counter >> ((7 - i) * 8));
    }

    const QByteArray hash = hmacSha1(secret, counterBytes);
    if (hash.size() < 20)
        return {};

    const int offset = hash.at(19) & 0x0f;
    const quint32 binary = ((static_cast<quint32>(hash.at(offset) & 0x7f) << 24)
                            | (static_cast<quint32>(hash.at(offset + 1) & 0xff) << 16)
                            | (static_cast<quint32>(hash.at(offset + 2) & 0xff) << 8)
                            | static_cast<quint32>(hash.at(offset + 3) & 0xff));

    quint32 modulus = 1;
    for (int i = 0; i < digits; ++i)
        modulus *= 10;

    return QStringLiteral("%1").arg(binary % modulus, digits, 10, QLatin1Char('0'));
}

bool TotpAuth::verify(const QString &base32Secret, const QString &code, int window, int period)
{
    QString normalized;
    for (const QChar ch : code) {
        if (ch.isDigit())
            normalized.append(ch);
    }
    if (normalized.size() != 6 && normalized.size() != 8)
        return false;
    if (base32Secret.trimmed().isEmpty())
        return false;

    const QByteArray secret = base32Decode(base32Secret);
    if (secret.isEmpty())
        return false;

    const qint64 now = QDateTime::currentSecsSinceEpoch();
    for (int offset = -window; offset <= window; ++offset) {
        const QString candidate = codeFor(secret, now + offset * period, normalized.size(), period);
        if (candidate.size() == normalized.size() && candidate == normalized)
            return true;
    }
    return false;
}

QString TotpAuth::otpauthUri(const QString &base32Secret, const QString &account, const QString &issuer)
{
    QUrl uri(QStringLiteral("otpauth://totp/"));
    const QString label = issuer + QLatin1Char(':') + account;
    uri.setPath(QLatin1Char('/') + label, QUrl::TolerantMode);

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("secret"), base32Secret);
    query.addQueryItem(QStringLiteral("issuer"), issuer);
    query.addQueryItem(QStringLiteral("algorithm"), QStringLiteral("SHA1"));
    query.addQueryItem(QStringLiteral("digits"), QStringLiteral("6"));
    query.addQueryItem(QStringLiteral("period"), QStringLiteral("30"));
    uri.setQuery(query);
    return uri.toString(QUrl::FullyEncoded);
}

QString TotpAuth::generateRecoveryCode()
{
    QByteArray raw = randomBytes(10);
    QString code;
    code.reserve(10);
    for (const char byte : raw)
        code.append(QLatin1Char(kRecoveryAlphabet[static_cast<unsigned char>(byte) & 0x1f]));
    return code.left(5) + QLatin1Char('-') + code.mid(5, 5);
}

QString TotpAuth::normalizeRecoveryCode(const QString &code)
{
    QString normalized;
    for (const QChar ch : code) {
        if (ch.isLetterOrNumber())
            normalized.append(ch.toUpper());
    }
    return normalized;
}

QByteArray TotpAuth::hashRecoveryCode(const QString &code)
{
    return QCryptographicHash::hash(normalizeRecoveryCode(code).toUtf8(), QCryptographicHash::Sha256);
}
