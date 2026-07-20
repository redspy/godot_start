# 📋 256×1024 Scan Conversion 파이프라인 & 음향 좌표계 오버레이 분리 아키텍처 회의록

**일시**: 2026년 7월 21일  
**참석자**:
1. **Dr. Alex Vance** (20년차 DICOM & 데이터 모델링 시니어 엔지니어)
2. **Dr. Elena Rostova** (20년차 Imaging Signal Processing & Scan Conversion C++ 엔지니어)
3. **Dr. Sophia Lin** (20년차 Clinical Measurement & 좌표계 연산 엔지니어)
4. **Dr. Kenji Sato** (20년차 Medical Main UI / UX 엔지니어)
5. **Marcus Brody** (20년차 핸드헬드 초음파 POCUS PM)

---

## 💬 1. 구조 설계 토의 및 핵심 아키텍처 결정

### 1) 256×1024 Raw Array & N-Stage C++ Scan Conversion Engine (Dr. Elena Rostova & Dr. Alex Vance)
> "의료용 초음파의 핵심은 **256개 라인 × 라인당 1024개 샘플의 Raw 음향 배열 데이터(256×1024 array)**입니다. 이 Raw 배열을 C++ 고성능 블록에서 N회(N-Stage) 필터링, 로그 압축, 그리고 극좌표-직교좌표($r, \theta \to x, y$) **Scan Conversion**을 거쳐 최종 픽셀 텍스처로 전환해야 합니다. 이 모든 파이프라인 블록 메모리와 매핑 파라미터 제어는 **C# (`UltrasoundPipelineController.cs`)**에서 통합 관리하도록 설계합니다."

### 2) Scan Conversion 이전 초음파 음향 좌표계 $(u, v)$ 분리 저장 (Dr. Sophia Lin & Dr. Kenji Sato)
> "뷰포트 크기나 해상도가 변경되어도 오버레이(Annotation, BodyMark, Caliper, Measurement)가 항상 초음파 빔 영역 내 해당 장기 위치에 완벽히 고정되려면, screen $(x, y)$ 좌표가 아니라 **Scan Conversion 이전의 음향 탐촉자 정규화 좌표계 $(u, v) \in [0.0..1.0] \times [0.0..1.0]$**로 저장되어야 합니다.  
> - $u$: 정규화 빔 라인 위치 ($0.0 \sim 1.0$, Line 0~255)  
> - $v$: 정규화 침투 깊이 위치 ($0.0 \sim 1.0$, Sample 0~1023)  
> 렌더링 시에는 `acoustic_to_screen(u, v)` 순방향 변환을, 터치 입력 시에는 `screen_to_acoustic(x, y)` 역방향 변환을 수행하여 **이미지 픽셀 데이터와 오버레이 데이터를 완전 분리 및 메타데이터 독립 저장**합니다."

---

## 🏆 2. 모듈화 설계 및 리팩토링 아키텍처 구조

```
+-----------------------------------------------------------------------------------+
|  1. C++ High-Performance N-Stage Scan Conversion Core                             |
|     (src/cpp/ultrasound_scan_converter.h & .cpp)                                  |
|     - Raw 256 Lines x 1024 Samples Matrix Buffer Allocation                       |
|     - Stage 1: Spatial Speckle Filter                                             |
|     - Stage 2: Dynamic Range Log Compressor                                       |
|     - Stage 3: Polar (r, θ) -> Cartesian (x, y) Scan Conversion Transform           |
+-----------------------------------------------------------------------------------+
                                        │ (Managed Buffer Control)
                                        ▼
+-----------------------------------------------------------------------------------+
|  2. C# Managed Pipeline Controller & Stage Director                               |
|     (src/csharp/UltrasoundPipelineController.cs)                                 |
|     - N-Stage Processing Block Chain Management                                  |
|     - Transducer Geometry Parameters (Radius Min/Max, Sector Angle)               |
+-----------------------------------------------------------------------------------+
                                        │ (Normalized Acoustic Coordinates u, v)
                                        ▼
+-----------------------------------------------------------------------------------+
|  3. Standalone Acoustic Coordinate Overlay Manager & Independent Storage Engine   |
|     (Acoustic Overlay Store in scripts/ultrasound_viewport.gd)                    |
|     - Transducer Acoustic Coordinates: u ∈ [0..1] (Line), v ∈ [0..1] (Depth)      |
|     - Resolution/Aspect independent overlay rendering & JSON serialization         |
+-----------------------------------------------------------------------------------+
```
