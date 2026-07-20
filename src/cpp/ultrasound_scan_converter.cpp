#include "ultrasound_scan_converter.h"

UltrasoundScanConverter::UltrasoundScanConverter(int out_width, int out_height)
    : out_width_(out_width), out_height_(out_height) {
    raw_matrix_.resize(TOTAL_RAW_ELEMENTS, 0.0f);
    filtered_matrix_.resize(TOTAL_RAW_ELEMENTS, 0.0f);
    compressed_matrix_.resize(TOTAL_RAW_ELEMENTS, 0.0f);
}

void UltrasoundScanConverter::generate_raw_acoustic_matrix(float gain, float frequency_mhz) {
    for (int line = 0; line < RAW_SCANLINES; ++line) {
        float norm_line = static_cast<float>(line) / static_cast<float>(RAW_SCANLINES - 1);
        for (int sample = 0; sample < RAW_SAMPLES_PER_LINE; ++sample) {
            float norm_sample = static_cast<float>(sample) / static_cast<float>(RAW_SAMPLES_PER_LINE - 1);
            
            // Synthetic acoustic scatterer distribution
            float acoustic_val = std::sin(norm_line * 12.56f) * std::cos(norm_sample * 25.12f) * gain;
            raw_matrix_[line * RAW_SAMPLES_PER_LINE + sample] = std::abs(acoustic_val);
        }
    }
}

void UltrasoundScanConverter::process_stage1_speckle_filter() {
    for (int line = 0; line < RAW_SCANLINES; ++line) {
        for (int sample = 0; sample < RAW_SAMPLES_PER_LINE; ++sample) {
            float sum = 0.0f;
            int count = 0;
            
            for (int d_line = -1; d_line <= 1; ++d_line) {
                int l = std::clamp(line + d_line, 0, RAW_SCANLINES - 1);
                for (int d_sample = -1; d_sample <= 1; ++d_sample) {
                    int s = std::clamp(sample + d_sample, 0, RAW_SAMPLES_PER_LINE - 1);
                    sum += raw_matrix_[l * RAW_SAMPLES_PER_LINE + s];
                    count++;
                }
            }
            filtered_matrix_[line * RAW_SAMPLES_PER_LINE + sample] = sum / static_cast<float>(count);
        }
    }
}

void UltrasoundScanConverter::process_stage2_log_compression(float dynamic_range_db) {
    float alpha = std::pow(10.0f, dynamic_range_db / 20.0f) - 1.0f;
    float scale = 255.0f / std::log10(1.0f + alpha);
    
    for (int i = 0; i < TOTAL_RAW_ELEMENTS; ++i) {
        float in_val = std::max(0.0f, filtered_matrix_[i]);
        float log_val = std::log10(1.0f + alpha * in_val);
        compressed_matrix_[i] = std::clamp(log_val * scale, 0.0f, 255.0f);
    }
}

std::vector<uint8_t> UltrasoundScanConverter::process_stage3_scan_conversion(
    TransducerGeometry geometry, float sector_angle_deg, float depth_cm) {
    
    std::vector<uint8_t> output_grid(out_width_ * out_height_, 0);
    float center_x = out_width_ * 0.5f;
    float half_angle_rad = (sector_angle_deg * 0.5f) * (3.14159265f / 180.0f);
    
    for (int y = 0; y < out_height_; ++y) {
        float norm_y = static_cast<float>(y) / static_cast<float>(out_height_ - 1);
        for (int x = 0; x < out_width_; ++x) {
            float dx = x - center_x;
            float dy = y;
            
            float radius = std::sqrt(dx * dx + dy * dy);
            float angle = std::atan2(dx, dy); // 0 deg is straight down
            
            if (std::abs(angle) <= half_angle_rad && radius <= out_height_) {
                float norm_u = (angle / half_angle_rad + 1.0f) * 0.5f; // [0..1] beam line
                float norm_v = radius / static_cast<float>(out_height_);   // [0..1] depth sample
                
                int line_idx = std::clamp(static_cast<int>(norm_u * (RAW_SCANLINES - 1)), 0, RAW_SCANLINES - 1);
                int sample_idx = std::clamp(static_cast<int>(norm_v * (RAW_SAMPLES_PER_LINE - 1)), 0, RAW_SAMPLES_PER_LINE - 1);
                
                float val = compressed_matrix_[line_idx * RAW_SAMPLES_PER_LINE + sample_idx];
                output_grid[y * out_width_ + x] = static_cast<uint8_t>(val);
            }
        }
    }
    
    return output_grid;
}
