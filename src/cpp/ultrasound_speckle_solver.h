#ifndef ULTRASOUND_SPECKLE_SOLVER_H
#define ULTRASOUND_SPECKLE_SOLVER_H

#include <vector>
#include <cmath>
#include <random>

/**
 * High-Performance C++ Medical Ultrasound Backscatter & Rayleigh Speckle Solver
 * 
 * Simulates tissue acoustic backscattering, Point Spread Function (PSF) axial/lateral convolution,
 * and 2D Rayleigh distributed speckle field generation:
 * I = sqrt(X^2 + Y^2),  X, Y ~ N(0, sigma^2)
 */
class UltrasoundSpeckleSolver {
public:
    struct Point2D {
        float x;
        float y;
        float intensity;
    };

    UltrasoundSpeckleSolver(uint32_t seed = 54321);

    // Generates Rayleigh distributed speckle noise matrix for ultrasound phantom
    std::vector<float> generate_rayleigh_matrix(int width, int height, float scatter_density, float sigma);

    // Applies Point Spread Function (PSF) 2D Gaussian beam convolution
    std::vector<float> apply_point_spread_function(const std::vector<float>& input, int width, int height, float axial_sigma, float lateral_sigma);

    // Generates sparse acoustic tissue scatterers for B-mode rendering
    std::vector<Point2D> generate_tissue_scatterers(int num_scatterers, float bounds_x, float bounds_y, float gain);

private:
    std::mt19937 rng_;
    std::normal_distribution<float> gaussian_dist_;
};

#endif // ULTRASOUND_SPECKLE_SOLVER_H
