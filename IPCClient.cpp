#include "IPCClient.h"

IPCClient::IPCClient() {
    auto channel = grpc::CreateChannel("192.168.0.107:50052", grpc::InsecureChannelCredentials());
    _stub = make_unique<IPCSrv::Stub>(channel);
}

IPCClient::~IPCClient() {

}

auto IPCClient::call(const json & ctx) -> tuple<json, bool> {
    debug("start call", ctx.dump());
    IPCRequest request;
    IPCReply reply;
    ClientContext c_ctx;

    request.set_body(ctx.dump());

    Status status = _stub->call(&c_ctx, request, &reply);

    if(status.ok()) {
        json re = json::parse(reply.body());
        int code = re.value("code", 0);
        if(code == 200) {
            return { re.value("reply", json()), true };
        }else {
            debug("接口请求失败!", reply.body());
        }
    }else {
        debug("接口请求异常!", status.error_code(), status.error_message());
    }

    return { json(), false };
}

