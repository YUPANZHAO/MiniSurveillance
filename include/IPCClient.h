#ifndef IPCCLIENT_H
#define IPCCLIENT_H

#include "debug.h"
#include "grpcpp/grpcpp.h"
#include <memory>
#include "IPC.grpc.pb.h"
#include "nlohmann/json.hpp"
#include <tuple>

using namespace ZYP;
using namespace std;

using grpc::ClientContext;
using grpc::Status;
using grpc::Channel;
using IPC::IPCSrv;
using IPC::IPCRequest;
using IPC::IPCReply;

using nlohmann::json;

class IPCClient {

public:
    IPCClient();
    ~IPCClient();

public:
    auto call(const json & ctx) -> tuple<json, bool>;

private:
    unique_ptr<IPCSrv::Stub> _stub;

};

#endif // IPCCLIENT_H
