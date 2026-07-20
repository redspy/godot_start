#ifndef ULTRASOUND_SCAN_CONVERTER_H
#define ULTRASOUND_SCAN_CONVERTER_H

#include <vector>
#include <cmath>
#include <cstdint>
#include <algorithm>

/**
 * High-Performance C++ N-Stage Ultrasound Scan Converter Engine.
 * 
 * Manages raw RF/envelope matrix: 256 vector scanlines x 1024 depth samples (262,144 elements).
 * Executes 3-Stage Signal Processing Pipeline:
 *   Stage 1: Spatial Speckle Filter (Acoustic Noise Reduction)
 *   Stage 2: Dynamic Range Log Compression (8-bit Gray Levels 0..255)
 *   Stage 3: Polar-to-Cartesian (r, theta -> x, y) Resampling Scan Conversion
 */
class UltrasoundScanConverter {
public:
    static constexpr int RAW_SCANLINES = 256;
    static constexpr int RAW_SAMPLES_PER_LINE = 1024;
    static constexpr int TOTAL_RAW_ELEMENTS = RAW_SCANLINES * RAW_SAMPLES_PER_LINE;

    enum TransducerGeometry {
        SECTOR_CONVEX = 0, // Convex Sector Fan (e.g. 64 deg)
        SECTOR_PHASED = 1, // Phased Sector Cone (e.g. 80 deg)
        GRID_LINEAR   = 2, // Linear Rectangular Grid
        SECTOR_ENDO   = 3  # Endo Wide Fan (160 deg)
    };

    UltrasoundScanConverter(int out_width = 512, int out_height = 512);

    // Fills raw 256x1024 matrix with synthetic acoustic tissue scattering data
    void generate_raw_acoustic_matrix(float gain, float frequency_mhz);

    // Stage 1: Spatial 3x3 Speckle Filter
    void process_stage1_speckle_filter();

    // Stage 2: Dynamic Range Log Compression: I_out = C * log10(1 + alpha * I_in)
    void process_stage2_log_compression(float dynamic_range_db = 50.0f);

    // Stage 3: Polar-to-Cartesian (r, theta -> x, y) Resampling Scan Conversion
    std::vector<uint8_t> process_stage3_scan_conversion(TransducerGeometry geometry, float sector_angle_deg, float depth_cm);

    // Accessors
    const std::vector<float>& get_raw_matrix() const { return raw_matrix_; }
    const std::vector<float>& get_compressed_matrix() const { return compressed_matrix_; }

private:
    int out_width_;
    int out_height_;
    std::vector<float> raw_matrix_;        // 256x1024 raw data
    std::vector<float> filtered_matrix_;   // Stage 1 output
    std::vector<float> compressed_matrix_; // Stage 2 output
};

#endif // ULTRASOUND_SCAN_CONVERTER_H
