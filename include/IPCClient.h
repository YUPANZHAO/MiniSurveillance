#ifndef IPCCLIENT_H
#define IPCCLIENT_H

#include "debug.h"
#include "grpcpp/grpcpp.h"
#include <memory>
#include "IPC.grpc.pb.h"
#include "nlohmann/json.hpp"
#include <tuple>
#include <iostream>
#include <fstream>
#include <QCoreApplication>
#include <QDir>

using namespace ZYP;
using namespace std;

using grpc::ClientContext;
using grpc::Status;
using grpc::Channel;
using IPC::IPCSrv;
using IPC::IPCRequest;
using IPC::IPCReply;
using IPC::FileReply;

using nlohmann::json;

class IPCClient {

public:
    IPCClient(const std::string ip, const std::string port);
    ~IPCClient();

public:
    auto call(const json & ctx) -> tuple<json, bool>;
    void streamCall(const json & ctx, function<void(const string &)> msgHandle);
    auto recordDownload(const json & ctx) -> optional<string>;

private:
    unique_ptr<IPCSrv::Stub> _stub;

};

#endif // IPCCLIENT_H
