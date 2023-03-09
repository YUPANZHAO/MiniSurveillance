#include "FlvPlayer.h"

FlvPlayer::FlvPlayer() : feed_thread(nullptr), need_sleep(false), is_regulating(false), request_step(false), step_one_frame(false) {
    this->is_pause = this->is_playing = false;
    file_fd = -1;
    tag_header = new BYTE [TAG_HEADER_SIZE];
    tag_data = new BYTE [TAG_DATA_SIZE];
}

FlvPlayer::~FlvPlayer() {
    delete [] tag_header;
    delete [] tag_data;
}

void FlvPlayer::set_file_path(const string & file_path) {
    if(is_playing) return;
    debug("set file path", file_path);
    this->file_path = file_path;
    if(this->file_fd != -1) {
        close(this->file_fd);
        this->file_fd = -1;
    }
    this->file_fd = open(this->file_path.c_str(), O_RDONLY | O_BINARY);
}

void FlvPlayer::start() {
    if(is_playing || file_fd == -1) return;
    is_playing = true;
    is_pause = false;
    need_I_frame = true;
    feed_thread = make_unique<thread>([this]() {
        this->feed_task();
    });
}

void FlvPlayer::stop() {
    if(!is_playing) return;
    is_playing = false;
    is_pause = false;
    feed_thread->join();
    feed_thread = nullptr;
    if(file_fd != -1) {
        close(file_fd);
        file_fd = -1;
    }
}

void FlvPlayer::pause() {
    if(is_pause) {
        is_pause = false;
    }else {
        is_pause = true;
    }
}

void FlvPlayer::step_by_frame(int count) {
    request_step = true;
    unique_lock<mutex> lock(file_mutex);
    request_step = false;
    if(is_regulating) return;
    is_regulating = true;
    count -= 1;
    if(count == 0) {
        is_regulating = false;
        return;
    }
    int dire = abs(count) / count;
    TAG_TYPE type;
    count = abs(count);
    while(count > 0) {
        move(dire, type);
        if(cur_idx + TAG_HEADER_SIZE > total_bytes
        || cur_idx == FLV_HEADER_LENGTH + 4) {
            break;
        }
        if(type == TAG_TYPE::VIDEO && tag_data[1] == 0x01) count--;
    }
    if(cur_idx + TAG_HEADER_SIZE > total_bytes) {
        while(true) {
            move(-1, type);
            if(type == TAG_TYPE::VIDEO) break;
        }
    }
    // 当前帧正好是I帧，直接解码
    bool is_i_frame = move(0, type);
    if(type == TAG_TYPE::VIDEO && is_i_frame) {
        is_regulating = false;
        return;
    }
    // 当前帧是P帧，找到当前视频帧前的第一个I帧，交由解码线程解码到当前帧
    regulate_tag_count = 0;
    while(true) {
        if(cur_idx == FLV_HEADER_LENGTH + 4) {
            break;
        }
        is_i_frame = move(-1, type);
        if(type == TAG_TYPE::VIDEO) {
            regulate_tag_count++;
        }
        if(is_i_frame) break;
    }
    // 若找不到I帧，则跳到后面的第一个I帧
    if(!is_i_frame) {
        need_I_frame = true;
        is_regulating = false;
        return;
    }
}

void FlvPlayer::step_one_frame_forward() {
    if(!is_playing) return;
    is_pause = true;
    step_one_frame = true;
}

void FlvPlayer::step_one_frame_backward() {
    if(!is_playing) return;
    is_pause = true;
    step_by_frame(-1);
    step_one_frame = true;
}

void FlvPlayer::step_by_seconds(int sec) {
    if(!is_playing) return;
    is_pause = true;
    thread step_thread([this, sec]() {
        this->step_by_frame(sec * fps);
        is_pause = false;
    });
    step_thread.detach();
}

void FlvPlayer::feed_task() {
    total_bytes = lseek(this->file_fd, 0, SEEK_END);
    lseek(this->file_fd, 0, SEEK_SET);
    cur_idx = 0;
    buf_len = 0;
    while(is_playing) {
        if(is_pause && !step_one_frame) {
            usleep(10000); // 10 ms
            continue;
        }

        if(request_step) usleep(1);
        unique_lock<mutex> lock(file_mutex);
        if(cur_idx + FLV_HEADER_LENGTH > total_bytes) {
            usleep(10000); // 10 ms
            continue;
        }
        cur_idx += read(file_fd, tag_header, FLV_HEADER_LENGTH);
        if(is_flv_header(tag_header)) {
            lseek(file_fd, 4, SEEK_CUR); // previous tag size
            cur_idx += 4;
            continue;
        }else {
            cur_idx += read(file_fd, tag_header + FLV_HEADER_LENGTH, TAG_HEADER_SIZE - FLV_HEADER_LENGTH);
        }

        UINT32 temp1 = tag_header[1] & 0xFF;
        UINT32 temp2 = tag_header[2] & 0xFF;
        UINT32 temp3 = tag_header[3] & 0xFF;
        buf_len = ((temp1 << 16) | (temp2 << 8) | (temp3)) & 0x00FFFFFF;
        cur_idx += read(file_fd, tag_data, buf_len);
        handle_tag((TAG_TYPE)(tag_header[0] & 0x1F), tag_data, buf_len);

        if(need_sleep && !is_regulating && !step_one_frame) {
            usleep(1000000 / fps);
            need_sleep = false;
        }

        if(step_one_frame
        && !is_regulating
        && (TAG_TYPE)(tag_header[0] & 0x1F) == TAG_TYPE::VIDEO
        && tag_data[1] == 0x01) {
            step_one_frame = false;
        }

        if(is_regulating && (TAG_TYPE)(tag_header[0] & 0x1F) == TAG_TYPE::VIDEO) {
            regulate_tag_count--;
            if(regulate_tag_count == 0) {
                is_regulating = false;
            }
        }

        lseek(file_fd, 4, SEEK_CUR); // previous tag size
        cur_idx += 4;
    }
}

bool FlvPlayer::is_flv_header(BYTE* buf) {
    for(int i=0; i < FLV_HEADER_LENGTH; ++i) {
        if(i == 4) continue;
        if(buf[i] != flv_header[i]) return false;
    }
    return true;
}

void FlvPlayer::handle_tag(TAG_TYPE type, BYTE* buf, UINT32 len) {
    if(type == TAG_TYPE::VIDEO) {
        handle_video_tag_data(buf, len);
    }else if(type == TAG_TYPE::AUDIO) {
        handle_audio_tag_data(buf, len);
    }
}

void FlvPlayer::handle_video_tag_data(BYTE* buf, UINT32 len) {
    if(0x00 == buf[1]) {
        handle_sps_pps(buf, len);
    }else {
        handle_frame(buf, len);
    }
}

void FlvPlayer::handle_sps_pps(BYTE* buf, UINT32 len) {
    UINT32 offset = 10;
    UINT32 sps_num = buf[offset++] & 0x1F;
    for(UINT32 i=0; i < sps_num; ++i) {
        UINT32 num0 = buf[offset++] & 0xFF;
        UINT32 num1 = buf[offset++] & 0xFF;
        UINT32 sps_len = ((num0 << 8) | num1);
        video_callback(NALU_TYPE_SPS, (BYTE*)buf + offset, sps_len, !is_regulating);
        offset += sps_len;
    }
    UINT32 pps_num = buf[offset++] & 0x1F;
    for(UINT32 i=0; i < pps_num; ++i) {
        UINT32 num0 = buf[offset++] & 0xFF;
        UINT32 num1 = buf[offset++] & 0xFF;
        UINT32 pps_len = ((num0 << 8) | num1);
        video_callback(NALU_TYPE_PPS, (BYTE*)buf + offset, pps_len, !is_regulating);
        offset += pps_len;
    }
}

void FlvPlayer::handle_frame(BYTE* buf, UINT32 len) {
    UINT32 offset = 5;
    UINT32 num0 = buf[offset++] & 0xFF;
    UINT32 num1 = buf[offset++] & 0xFF;
    UINT32 num2 = buf[offset++] & 0xFF;
    UINT32 num3 = buf[offset++] & 0xFF;
    UINT32 data_len = ((num0 << 24) | (num1 << 16) | (num2 << 8) | num3);
    if((uint8_t)buf[0] == 0x17) {
        video_callback(NALU_TYPE_IDR, (BYTE*)buf + offset, data_len, !is_regulating);
        need_I_frame = false;
    }else if(!need_I_frame) {
        video_callback(NALU_TYPE_OTHER, (BYTE*)buf + offset, data_len, !is_regulating);
    }
    offset += data_len;
}

void FlvPlayer::handle_audio_tag_data(BYTE* buf, UINT32 len) {
    if(0x00 == buf[1]) {
        handle_audio_decode_info(buf, len);
    }else {
        handle_audio_data(buf, len);
    }
}

void FlvPlayer::handle_audio_decode_info(BYTE* buf, UINT32 len) {
    UINT32 offset = 2;
    UINT32 data_len = len - offset;
    if((uint8_t)buf[0] == 0xAE)
        audio_callback(AUDIO_INFO, AUDIO_CHANNEL_MONO, (BYTE*)buf + offset, data_len, !is_regulating);
    else
        audio_callback(AUDIO_INFO, AUDIO_CHANNEL_STEREO, (BYTE*)buf + offset, data_len, !is_regulating);
    offset += data_len;
}

void FlvPlayer::handle_audio_data(BYTE* buf, UINT32 len) {
    UINT32 offset = 2;
    UINT32 data_len = len - offset;
    if((uint8_t)buf[0] == 0xAE)
        audio_callback(AUDIO_DATA, AUDIO_CHANNEL_MONO, (BYTE*)buf + offset, data_len, !is_regulating);
    else
        audio_callback(AUDIO_DATA, AUDIO_CHANNEL_STEREO, (BYTE*)buf + offset, data_len, !is_regulating);
    offset += data_len;
}

void FlvPlayer::set_video_callback(VideoCallBack cb) {
    video_callback = cb;
}

void FlvPlayer::set_audio_callback(AudioCallBack cb) {
    audio_callback = cb;
}

void FlvPlayer::sleep_once(int fps) {
    this->fps = fps;
    need_sleep = true;
}

bool FlvPlayer::move(int tag_count, TAG_TYPE& type) {
    if(tag_count >= 0) move_forward(tag_count);
    else move_backward(-tag_count);
    type = TAG_TYPE::AUDIO;
    if(cur_idx + TAG_HEADER_SIZE > total_bytes) return false;
    read(file_fd, tag_header, TAG_HEADER_SIZE);
    read(file_fd, tag_data, 2);
    lseek(file_fd, -TAG_HEADER_SIZE-2, SEEK_CUR);
    type = (TAG_TYPE)(tag_header[0] & 0x1F);
    if(type == TAG_TYPE::VIDEO && tag_data[0] == 0x17 && tag_data[1] == 0x01) {
        return true;
    }
    return false;
}

void FlvPlayer::move_forward(int tag_count) {
    while(tag_count && cur_idx + TAG_HEADER_SIZE <= total_bytes) {
        tag_count--;
        cur_idx += read(file_fd, tag_header, TAG_HEADER_SIZE);
        UINT32 temp1 = tag_header[1] & 0xFF;
        UINT32 temp2 = tag_header[2] & 0xFF;
        UINT32 temp3 = tag_header[3] & 0xFF;
        buf_len = ((temp1 << 16) | (temp2 << 8) | (temp3)) & 0x00FFFFFF;
        lseek(file_fd, buf_len + 4, SEEK_CUR);
        cur_idx += buf_len + 4;
    }
}

void FlvPlayer::move_backward(int tag_count) {
    while(tag_count && cur_idx > 0) {
        tag_count--;
        lseek(file_fd, -4, SEEK_CUR);
        read(file_fd, tag_header, 4);
        UINT32 temp1 = tag_header[0] & 0xFF;
        UINT32 temp2 = tag_header[1] & 0xFF;
        UINT32 temp3 = tag_header[2] & 0xFF;
        UINT32 temp4 = tag_header[3] & 0xFF;
        buf_len = ((temp1 << 24) | (temp2 << 16) | (temp3 << 8) | (temp4)) & 0xFFFFFFFF;
        if(buf_len == 0) break;
        cur_idx -= 4 + buf_len;
        lseek(file_fd, -4-buf_len, SEEK_CUR);
    }
}
