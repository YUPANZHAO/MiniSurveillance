#include "ConfigCtrl.h"
#include <windows.h>
#include "debug.h"
#include <sstream>

using namespace ZYP;

ConfigCtrl::ConfigCtrl() {
}

ConfigCtrl::~ConfigCtrl() {

}

QString ConfigCtrl::configFile() const {
    return _configFile.c_str();
}

void ConfigCtrl::setConfigFile(const QString & path) {
    _configFile = path.toStdString();
    initValues();
}

void ConfigCtrl::setValue(const QString key, const QString value) {
    _values[key.toStdString()] = value.toStdString();
}

QString ConfigCtrl::getValue(const QString key) {
    return _values[key.toStdString()].c_str();
}

void ConfigCtrl::publish() {
    if(_configFile.empty()) return;
    FILE *fd = fopen(_configFile.c_str(), "w");
    if(fd == NULL) {
        debug("can not open file");
        return;
    }
    for(auto pair : _values) {
        std::string content = pair.first + ":" + pair.second + "\n";
        size_t len = fwrite(content.c_str(), 1, content.length(), fd);
    }
    fclose(fd);
}

void ConfigCtrl::initValues() {
    if(_configFile.empty()) return;
    FILE *fd = fopen(_configFile.c_str(), "r");
    if(fd == NULL) {
        debug("can not open file");
        return;
    }
    std::string content;
    char buf[1024];
    while(true) {
        size_t len = fread(buf, 1, 1024, fd);
        if(len == 0) break;
        for(size_t i=0; i < len; ++i) {
            content += buf[i];
        }
    }
    fclose(fd);
    std::stringstream ss(content);
    std::string line;
    while(ss >> line) {
        auto cut_idx = line.find_first_of(':');
        if(cut_idx == std::string::npos) {
            debug("no found ':'");
            continue;
        }
        std::string key = line.substr(0, cut_idx);
        std::string value = line.substr(cut_idx+1, line.length());
        debug(key, value);
        _values[key] = value;
    }
}
