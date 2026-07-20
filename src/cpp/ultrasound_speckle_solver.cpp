#include "ultrasound_speckle_solver.h"
#include <algorithm>

UltrasoundSpeckleSolver::UltrasoundSpeckleSolver(uint32_t seed)
    : rng_(seed), gaussian_dist_(0.0f, 1.0f) {}

std::vector<float> UltrasoundSpeckleSolver::generate_rayleigh_matrix(int width, int height, float scatter_density, float sigma) {
    std::vector<float> output(width * height, 0.0f);
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            // Complex Gaussian components: X and Y ~ N(0, sigma^2)
            float real_part = gaussian_dist_(rng_) * sigma;
            float imag_part = gaussian_dist_(rng_) * sigma;
            
            // Rayleigh envelope: I = sqrt(X^2 + Y^2)
            float rayleigh_val = std::sqrt(real_part * real_part + imag_part * imag_part);
            
            output[y * width + x] = rayleigh_val * scatter_density;
        }
    }
    
    return output;
}

std::vector<float> UltrasoundSpeckleSolver::apply_point_spread_function(
    const std::vector<float>& input, int width, int height, float axial_sigma, float lateral_sigma) {
    
    std::vector<float> output(width * height, 0.0f);
    int kernel_radius_x = static_cast<int>(std::ceil(lateral_sigma * 3.0f));
    int kernel_radius_y = static_cast<int>(std::ceil(axial_sigma * 3.0f));
    
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float sum = 0.0f;
            float weight_sum = 0.0f;
            
            for (int ky = -kernel_radius_y; ky <= kernel_radius_y; ++ky) {
                int py = std::clamp(y + ky, 0, height - 1);
                float wy = std::exp(-0.5f * (ky * ky) / (axial_sigma * axial_sigma));
                
                for (int kx = -kernel_radius_x; kx <= kernel_radius_x; ++kx) {
                    int px = std::clamp(x + kx, 0, width - 1);
                    float wx = std::exp(-0.5f * (kx * kx) / (lateral_sigma * lateral_sigma));
                    
                    float w = wx * wy;
                    sum += input[py * width + px] * w;
                    weight_sum += w;
                }
            }
            
            output[y * width + x] = (weight_sum > 0.0f) ? (sum / weight_sum) : 0.0f;
        }
    }
    
    return output;
}

std::vector<UltrasoundSpeckleSolver::Point2D> UltrasoundSpeckleSolver::generate_tissue_scatterers(
    int num_scatterers, float bounds_x, float bounds_y, float gain) {
    
    std::vector<Point2D> scatterers;
    scatterers.reserve(num_scatterers);
    
    std::uniform_real_distribution<float> dist_x(0.0f, bounds_x);
    std::uniform_real_distribution<float> dist_y(0.0f, bounds_y);
    
    for (int i = 0; i < num_scatterers; ++i) {
        float x = dist_x(rng_);
        float y = dist_y(rng_);
        float rx = gaussian_dist_(rng_);
        float ry = gaussian_dist_(rng_);
        float intensity = std::sqrt(rx * rx + ry * ry) * gain;
        
        scatterers.push_back({x, y, intensity});
    }
    
    return scatterers;
}
