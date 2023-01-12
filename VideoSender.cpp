#include "VideoSender.h"

VideoSender::VideoSender()
: rtmp_push_thread(nullptr)
, videoChannel(nullptr)
, audioChannel(nullptr)
, is_pushing(false)
, is_pushing_audio(false) {
    RTMPPacketCallBack = [&](RTMPPacket *packet) {
        if(packet) {
            packet->m_nTimeStamp = RTMP_GetTime() - push_start_time;
            packets.push(packet);
            // cout << "��������һ�� packet time_stamp: " << packet->m_nTimeStamp <<  endl;
        }
    };
    packets.setReleaseHandle([](RTMPPacket * & packet) {
        if(packet) {
            delete packet;
            packet = nullptr;
        }
    });
    videoChannel = make_shared<VideoChannel>();
    videoChannel->setRTMPPacketCallBack(RTMPPacketCallBack);
    videoChannel->setVideoEncoderParams(640, 360, 15, 4000000);
}

VideoSender::~VideoSender() {

}

CameraFilter* VideoSender::cameraSource() {
    return source;
}

void VideoSender::setCameraSource(CameraFilter* filter) {
    source = filter;
    if(source) {
        connect(source, &CameraFilter::getOneFrame, this, &VideoSender::receiveOneFrame);
    }
}

void VideoSender::receiveOneFrame(const QVideoFrame & frame) {
    if(is_pushing) {
        videoChannel->encodeData((uint8_t*)frame.bits());
    }
}

void VideoSender::setRtmpUrl(const QString & url) {
    rtmp_push_url = url.toStdString();
}

void VideoSender::push() {
    if(is_pushing) return;
    is_pushing = true;

    rtmp_push_thread = make_shared<std::thread>([&]() {

        RTMP* rtmp = nullptr;
        RTMPPacket* packet = nullptr;

        do {
            rtmp = RTMP_Alloc();
            if(!rtmp) {
                qDebug() << "���� RTMP �ڴ�ʧ��";
                break;
            }

            RTMP_Init(rtmp);
            rtmp->Link.timeout = 5;

            int ret = RTMP_SetupURL(rtmp, const_cast<char*>(rtmp_push_url.c_str()));
            if(!ret) {
                qDebug() << "���� RTMP ������������ַ " << rtmp_push_url.c_str() << " ʧ��";
                break;
            }

            RTMP_EnableWrite(rtmp);

            ret = RTMP_Connect(rtmp, NULL);
            if(!ret) {
                qDebug() << "���� RTMP ������ " << rtmp_push_url.c_str() << " ʧ��";
                break;
            }

            ret = RTMP_ConnectStream(rtmp, 0);
            if(!ret) {
                qDebug() << "���� RTMP �� " << rtmp_push_url.c_str() << " ʧ��";
                break;
            }

            push_start_time = RTMP_GetTime();

            packets.setWork(1);

            qDebug() << "��ʼ����";
            while(is_pushing) {
                packets.pop(packet);

                if(!packet) {
                    continue;
                }

                // cout << "ȡ��һ�����ݰ� time_stamp: " << packet->m_nTimeStamp << endl;

                packet->m_nInfoField2 = rtmp->m_stream_id;

                ret = RTMP_SendPacket(rtmp, packet, 1);

                if(packet) {
                    RTMPPacket_Free(packet);
                    delete packet;
                    packet = nullptr;
                }

                if(!ret) {
                    qDebug() << "RTMP ���ݰ�����ʧ��";
                    break;
                }
            }
        }while(false);

        if(rtmp) {
            RTMP_Close(rtmp);
            RTMP_Free(rtmp);
        }

        if(packet) {
            RTMPPacket_Free(packet);
            delete packet;
            packet = nullptr;
        }

        packets.setWork(0);
        packets.clear();
        is_pushing = false;

        qDebug() << "�����߳̽���";
    });
}

void VideoSender::stop() {
    if(!is_pushing) return;
    if(is_pushing_audio) {
        stopAudio();
    }
    is_pushing = false;
    packets.setWork(0);
    packets.clear();
    rtmp_push_thread->join();
    rtmp_push_thread = nullptr;
}

void VideoSender::openAudio() {
    if(!is_pushing) return;

    int sampleRateInHz = 44100;
    int channels = 2;
    int bits = 16;
    audioChannel = make_shared<AudioChannel>();
    audioChannel->setRTMPPacketCallBack(RTMPPacketCallBack);
    audioChannel->setAudioEncodeParams(sampleRateInHz, channels);
    RTMPPacketCallBack(audioChannel->getAudioDecodeInfo());

    QAudioFormat fmt;
    fmt.setSampleRate(sampleRateInHz);
    fmt.setChannelCount(channels);
    fmt.setSampleSize(bits);
    fmt.setCodec("audio/pcm");
    fmt.setByteOrder(QAudioFormat::LittleEndian);
    fmt.setSampleType(QAudioFormat::SignedInt);

    audioInput = make_shared<QAudioInput>(fmt);
    audio_io = audioInput->start();

    is_pushing_audio = true;

    audio_data_thread = make_shared<std::thread>([&, sampleRateInHz, channels, bits]() {
        int len = audioChannel->getInputSamples() * (bits >> 3);
        char* buf = new char [len];
        int ready = 0;
        while(true) {
            if(!is_pushing_audio) break;
            if(audio_io) {
                ready += audio_io->read(buf + ready, len - ready);
            }
            if(ready < len) {
                Sleep(2);
                continue;
            }
            if(audioChannel) {
                audioChannel->encodeAudioData((BYTE*)buf);
            }
            ready = 0;
        }
        delete [] buf;
        is_pushing_audio = false;
    });

    qDebug() << "������Ƶ����";
}

void VideoSender::stopAudio() {
    if(!is_pushing_audio) return;
    is_pushing_audio = false;
    if(audio_data_thread) {
        audio_data_thread->join();
        audio_data_thread = nullptr;
    }
    audioChannel = nullptr;
    if(audioInput) {
        audio_io->close();
        audio_io = nullptr;
        audioInput->stop();
        audioInput = nullptr;
    }
    qDebug() << "�ر���Ƶ����";
}
