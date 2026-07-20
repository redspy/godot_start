using System;

namespace MedicalUltrasound.SignalProcessing
{
    /// <summary>
    /// High-Precision C# / .NET Medical Ultrasound Signal Processing Engine.
    /// Handles Hilbert Transform Analytic Signal Envelope Extraction,
    /// 6-Band Depth Time-Gain Compensation (TGC), and Dynamic Range Logarithmic Compression.
    /// </summary>
    public class UltrasoundSignalProcessor
    {
        private readonly int _sampleCount;
        private readonly float[] _hanningWindow;

        public UltrasoundSignalProcessor(int sampleCount = 256)
        {
            _sampleCount = sampleCount;
            _hanningWindow = new float[sampleCount];
            for (int i = 0; i < sampleCount; i++)
            {
                _hanningWindow[i] = 0.5f * (1.0f - (float)Math.Cos(2.0 * Math.PI * i / (sampleCount - 1)));
            }
        }

        /// <summary>
        /// Hilbert Transform analytic envelope detection: E(t) = sqrt(RF(t)^2 + H{RF(t)}^2)
        /// </summary>
        public float[] ExtractHilbertEnvelope(float[] rfData)
        {
            int len = rfData.Length;
            float[] envelope = new float[len];
            
            // Quad-phase quadrature demux approximation for real-time B-mode signal processing
            for (int i = 0; i < len; i++)
            {
                float realSignal = rfData[i];
                float quadSignal = (i > 0 && i < len - 1) ? (rfData[i + 1] - rfData[i - 1]) * 0.5f : 0.0f;
                
                envelope[i] = (float)Math.Sqrt(realSignal * realSignal + quadSignal * quadSignal);
            }
            
            return envelope;
        }

        /// <summary>
        /// 6-Band Depth Time-Gain Compensation (TGC) attenuation curve correction.
        /// </summary>
        public float[] ApplyDepthTGC(float[] envelope, float[] tgcBands)
        {
            int len = envelope.Length;
            float[] compensated = new float[len];
            int numBands = tgcBands.Length;

            for (int i = 0; i < len; i++)
            {
                float normDepth = (float)i / (float)len;
                float bandIdx = normDepth * (numBands - 1);
                int b0 = (int)Math.Floor(bandIdx);
                int b1 = Math.Min(b0 + 1, numBands - 1);
                float frac = bandIdx - b0;

                float tgcGain = (1.0f - frac) * tgcBands[b0] + frac * tgcBands[b1];
                compensated[i] = envelope[i] * tgcGain;
            }

            return compensated;
        }

        /// <summary>
        /// Logarithmic Compression & Dynamic Range Mapping:
        /// I_out = C * log10(1 + alpha * I_in) mapped to 8-bit gray scale [0..255].
        /// </summary>
        public float[] LogCompress(float[] signal, float dynamicRangeDb = 50.0f)
        {
            int len = signal.Length;
            float[] compressed = new float[len];
            float alpha = (float)(Math.Pow(10.0, dynamicRangeDb / 20.0) - 1.0);
            float scale = 255.0f / (float)Math.Log10(1.0 + alpha);

            for (int i = 0; i < len; i++)
            {
                float normVal = Math.Max(0.0f, signal[i]);
                float logVal = (float)Math.Log10(1.0 + alpha * normVal);
                compressed[i] = Math.Clamp(logVal * scale, 0.0f, 255.0f);
            }

            return compressed;
        }
    }
}
