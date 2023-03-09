#include "IPCClient.h"

IPCClient::IPCClient() {
    auto channel = grpc::CreateChannel("localhost:9000", grpc::InsecureChannelCredentials());
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

void IPCClient::streamCall(const json & ctx, function<void(const string &)> msgHandle) {
    debug("start stream call");
    ClientContext c_ctx;
    IPCRequest request;
    IPCReply reply;

    request.set_body(ctx.dump());

    auto reader = _stub->streamCall(&c_ctx, request);

    while(reader->Read(&reply)) {
        msgHandle(reply.body());
    }

    Status stauts = reader->Finish();
    if(!stauts.ok()) {
        debug("消息回调rpc流异常!");
    }

    debug("消息回调结束");
}

auto IPCClient::recordDownload(const json & ctx) -> optional<string> {
    debug("start record download");
    ClientContext c_ctx;
    IPCRequest request;
    FileReply reply;

    request.set_body(ctx.dump());

    auto reader = _stub->recordDownload(&c_ctx, request);

    ofstream outfile;
    const char* data;
    string root_path = QCoreApplication::applicationDirPath().toStdString() + "/record";
    string save_path = root_path + "/record.flv";
    QDir dir(root_path.c_str());
    if(!dir.exists()) {
        dir.mkdir(root_path.c_str());
    }

    outfile.open(save_path.c_str(), ofstream::out | ofstream::trunc | ofstream::binary);
    while(reader->Read(&reply)) {
        data = reply.buffer().c_str();
        outfile.write(data, reply.buffer().length());
    }
    outfile.close();

    Status stauts = reader->Finish();
    if(!stauts.ok()) {
        debug("获取录像文件异常!");
    }

    debug("获取录像文件结束");
    return save_path;
}
