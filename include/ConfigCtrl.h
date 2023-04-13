#ifndef CONFIGCTRL_H
#define CONFIGCTRL_H

#include <QObject>

class ConfigCtrl : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString configFile READ configFile WRITE setConfigFile NOTIFY configFileChanged)

public:
    ConfigCtrl();
    ~ConfigCtrl();

    QString configFile() const;
    void setConfigFile(const QString & path);

signals:
    void configFileChanged();

public:
    Q_INVOKABLE void setValue(const QString key, const QString value);
    Q_INVOKABLE QString getValue(const QString key);
    Q_INVOKABLE void publish();

private:
    std::string _configFile;
    std::map<std::string, std::string> _values;

    void initValues();
};

#endif // CONFIGCTRL_H
