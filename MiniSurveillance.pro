QT += quick multimedia

CONFIG += c++17
DEFINES += _DEBUG
DEFINES += _WIN32_WINNT=0x600

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        AACDecoder.cpp \
        AudioChannel.cpp \
        CameraFilter.cpp \
        FFmpeg_Decoder.cpp \
        FrameProvider.cpp \
        H264Decoder.cpp \
        IPC.grpc.pb.cc \
        IPC.pb.cc \
        IPCClient.cpp \
        MainCtrl.cpp \
        VideoChannel.cpp \
        VideoCtrl.cpp \
        VideoSender.cpp \
        main.cpp \
        VideoCapture.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

INCLUDEPATH += $$PWD/include
INCLUDEPATH += $$PWD/include/grpc

LIBS += $$PWD/libs/librtmp.a \
        -L$$PWD/libs/ffmpeg/ -lavcodec \
        -L$$PWD/libs/ffmpeg/ -lavdevice \
        -L$$PWD/libs/ffmpeg/ -lavfilter \
        -L$$PWD/libs/ffmpeg/ -lavformat \
        -L$$PWD/libs/ffmpeg/ -lavutil \
        -L$$PWD/libs/ffmpeg/ -lpostproc \
        -L$$PWD/libs/ffmpeg/ -lswresample \
        -L$$PWD/libs/ffmpeg/ -lswscale \
        $$PWD/libs/libfaac.a \
        $$PWD/libs/libx264.a

LIBS += -L$$PWD/libs/grpc/ -labsl_bad_optional_access.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_bad_variant_access.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_base.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_city.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_civil_time.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_cord.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_debugging_internal.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_demangle_internal.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_exponential_biased.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_graphcycles_internal.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_hash.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_hashtablez_sampler.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_int128.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_log_severity.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_malloc_internal.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_raw_hash_set.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_raw_logging_internal.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_spinlock_wait.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_stacktrace.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_status.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_str_format_internal.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_strings.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_strings_internal.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_symbolize.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_synchronization.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_throw_delegate.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_time.dll
LIBS += -L$$PWD/libs/grpc/ -labsl_time_zone.dll
LIBS += -L$$PWD/libs/grpc/ -laddress_sorting.dll
LIBS += -L$$PWD/libs/grpc/ -lcares.dll
LIBS += -L$$PWD/libs/grpc/ -lcrypto.dll
LIBS += -L$$PWD/libs/grpc/ -lgpr.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpc.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpc_plugin_support.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpc_unsecure.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpc++.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpc++_alts.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpc++_error_details.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpc++_reflection.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpc++_unsecure.dll
LIBS += -L$$PWD/libs/grpc/ -lgrpcpp_channelz.dll
LIBS += -L$$PWD/libs/grpc/ -llibprotobuf.dll
LIBS += -L$$PWD/libs/grpc/ -llibprotobuf-lite.dll
LIBS += -L$$PWD/libs/grpc/ -llibprotoc.dll
LIBS += -L$$PWD/libs/grpc/ -lre2.dll
LIBS += -L$$PWD/libs/grpc/ -lssl.dll
LIBS += -L$$PWD/libs/grpc/ -lupb.dll

LIBS += -lws2_32 -lwinmm
HEADERS += \
    include/AACDecoder.h \
    include/AudioChannel.h \
    include/CameraFilter.h \
    include/FFmpeg_Decoder.h \
    include/FrameProvider.h \
    include/H264Decoder.h \
    include/IPC.grpc.pb.h \
    include/IPC.pb.h \
    include/IPCClient.h \
    include/MainCtrl.h \
    include/SafeQueue.hpp \
    include/VideoCapture.h \
    include/VideoChannel.h \
    include/VideoCtrl.h \
    include/VideoSender.h \
    include/debug.h \
    include/faac/faac.h \
    include/faac/faaccfg.h \
    include/libavcodec/ac3_parser.h \
    include/libavcodec/adts_parser.h \
    include/libavcodec/avcodec.h \
    include/libavcodec/avdct.h \
    include/libavcodec/avfft.h \
    include/libavcodec/bsf.h \
    include/libavcodec/codec.h \
    include/libavcodec/codec_desc.h \
    include/libavcodec/codec_id.h \
    include/libavcodec/codec_par.h \
    include/libavcodec/d3d11va.h \
    include/libavcodec/defs.h \
    include/libavcodec/dirac.h \
    include/libavcodec/dv_profile.h \
    include/libavcodec/dxva2.h \
    include/libavcodec/jni.h \
    include/libavcodec/mediacodec.h \
    include/libavcodec/packet.h \
    include/libavcodec/qsv.h \
    include/libavcodec/vdpau.h \
    include/libavcodec/version.h \
    include/libavcodec/version_major.h \
    include/libavcodec/videotoolbox.h \
    include/libavcodec/vorbis_parser.h \
    include/libavcodec/xvmc.h \
    include/libavdevice/avdevice.h \
    include/libavdevice/version.h \
    include/libavdevice/version_major.h \
    include/libavfilter/avfilter.h \
    include/libavfilter/buffersink.h \
    include/libavfilter/buffersrc.h \
    include/libavfilter/version.h \
    include/libavfilter/version_major.h \
    include/libavformat/avformat.h \
    include/libavformat/avio.h \
    include/libavformat/version.h \
    include/libavformat/version_major.h \
    include/libavutil/adler32.h \
    include/libavutil/aes.h \
    include/libavutil/aes_ctr.h \
    include/libavutil/attributes.h \
    include/libavutil/audio_fifo.h \
    include/libavutil/avassert.h \
    include/libavutil/avconfig.h \
    include/libavutil/avstring.h \
    include/libavutil/avutil.h \
    include/libavutil/base64.h \
    include/libavutil/blowfish.h \
    include/libavutil/bprint.h \
    include/libavutil/bswap.h \
    include/libavutil/buffer.h \
    include/libavutil/camellia.h \
    include/libavutil/cast5.h \
    include/libavutil/channel_layout.h \
    include/libavutil/common.h \
    include/libavutil/cpu.h \
    include/libavutil/crc.h \
    include/libavutil/csp.h \
    include/libavutil/des.h \
    include/libavutil/detection_bbox.h \
    include/libavutil/dict.h \
    include/libavutil/display.h \
    include/libavutil/dovi_meta.h \
    include/libavutil/downmix_info.h \
    include/libavutil/encryption_info.h \
    include/libavutil/error.h \
    include/libavutil/eval.h \
    include/libavutil/ffversion.h \
    include/libavutil/fifo.h \
    include/libavutil/file.h \
    include/libavutil/film_grain_params.h \
    include/libavutil/frame.h \
    include/libavutil/hash.h \
    include/libavutil/hdr_dynamic_metadata.h \
    include/libavutil/hdr_dynamic_vivid_metadata.h \
    include/libavutil/hmac.h \
    include/libavutil/hwcontext.h \
    include/libavutil/hwcontext_cuda.h \
    include/libavutil/hwcontext_d3d11va.h \
    include/libavutil/hwcontext_drm.h \
    include/libavutil/hwcontext_dxva2.h \
    include/libavutil/hwcontext_mediacodec.h \
    include/libavutil/hwcontext_opencl.h \
    include/libavutil/hwcontext_qsv.h \
    include/libavutil/hwcontext_vaapi.h \
    include/libavutil/hwcontext_vdpau.h \
    include/libavutil/hwcontext_videotoolbox.h \
    include/libavutil/hwcontext_vulkan.h \
    include/libavutil/imgutils.h \
    include/libavutil/intfloat.h \
    include/libavutil/intreadwrite.h \
    include/libavutil/lfg.h \
    include/libavutil/log.h \
    include/libavutil/lzo.h \
    include/libavutil/macros.h \
    include/libavutil/mastering_display_metadata.h \
    include/libavutil/mathematics.h \
    include/libavutil/md5.h \
    include/libavutil/mem.h \
    include/libavutil/motion_vector.h \
    include/libavutil/murmur3.h \
    include/libavutil/opt.h \
    include/libavutil/parseutils.h \
    include/libavutil/pixdesc.h \
    include/libavutil/pixelutils.h \
    include/libavutil/pixfmt.h \
    include/libavutil/random_seed.h \
    include/libavutil/rational.h \
    include/libavutil/rc4.h \
    include/libavutil/replaygain.h \
    include/libavutil/ripemd.h \
    include/libavutil/samplefmt.h \
    include/libavutil/sha.h \
    include/libavutil/sha512.h \
    include/libavutil/spherical.h \
    include/libavutil/stereo3d.h \
    include/libavutil/tea.h \
    include/libavutil/threadmessage.h \
    include/libavutil/time.h \
    include/libavutil/timecode.h \
    include/libavutil/timestamp.h \
    include/libavutil/tree.h \
    include/libavutil/twofish.h \
    include/libavutil/tx.h \
    include/libavutil/uuid.h \
    include/libavutil/version.h \
    include/libavutil/video_enc_params.h \
    include/libavutil/xtea.h \
    include/librtmp/amf.h \
    include/librtmp/bytes.h \
    include/librtmp/dh.h \
    include/librtmp/dhgroups.h \
    include/librtmp/handshake.h \
    include/librtmp/http.h \
    include/librtmp/log.h \
    include/librtmp/rtmp.h \
    include/librtmp/rtmp_sys.h \
    include/libswresample/swresample.h \
    include/libswresample/version.h \
    include/libswresample/version_major.h \
    include/libswscale/swscale.h \
    include/libswscale/version.h \
    include/libswscale/version_major.h \
    include/types.h \
    include/x264/x264.h \
    include/x264/x264_config.h
