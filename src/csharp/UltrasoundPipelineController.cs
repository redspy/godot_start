using System;
using System.Collections.Generic;

namespace UltrasoundEngine
{
    /// <summary>
    /// C# Managed Pipeline Controller for 256x1024 Acoustic Signal Processing & Scan Conversion.
    /// Orchestrates N-stage execution blocks, memory buffers, and transducer sector parameters.
    /// </summary>
    public class UltrasoundPipelineController
    {
        public const int RawScanlines = 256;
        public const int RawSamplesPerLine = 1024;
        
        public float DynamicRangeDb { get; set; } = 50.0f;
        public float Gain { get; set; } = 1.0f;
        public float SectorAngleDeg { get; set; } = 64.0f;
        public float DepthCm { get; set; } = 8.9f;
        
        public enum PipelineStage
        {
            RawAcquisition,
            SpeckleFiltering,
            LogarithmicCompression,
            ScanConversion
        }
        
        private readonly List<PipelineStage> _stageChain = new List<PipelineStage>();
        
        public UltrasoundPipelineController()
        {
            _stageChain.Add(PipelineStage.RawAcquisition);
            _stageChain.Add(PipelineStage.SpeckleFiltering);
            _stageChain.Add(PipelineStage.LogarithmicCompression);
            _stageChain.Add(PipelineStage.ScanConversion);
        }
        
        public int GetStageCount()
        {
            return _stageChain.Count;
        }
        
        /// <summary>
        /// Converts normalized acoustic beam/depth coordinates (u, v) in [0..1] x [0..1]
        /// to polar scan conversion coordinates.
        /// </summary>
        public (float lineIndex, float sampleIndex) MapAcousticCoordinates(float normU, float normV)
        {
            float lineIdx = normU * (RawScanlines - 1);
            float sampleIdx = normV * (RawSamplesPerLine - 1);
            return (lineIdx, sampleIdx);
        }
    }
}
