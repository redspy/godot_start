# 초음파 소프트웨어 전체 개발 및 아키텍처 구현 계획서 (Implementation Plan)

본 문서는 핸드헬드 초음파 시스템 개발 프로젝트의 모든 개발 단계 및 기술 아키텍처 구현 내역을 종합 정리한 계획서입니다.

---

## 1. 시스템 핵심 구현 기능 요약

### 1) B-Mode Pinch Zoom & Mouse Wheel System
- **Touchscreen Pinch Zoom**: `InputEventMagnifyGesture` 제스처를 감지하여 1.0x ~ 3.0x 배율로 초음파 스캔을 자유롭게 확대
- **Visual Indicator**: `🔍 ZOOM X.Xx` 배율 2D 오버레이 표시
- **Acoustic Coordinate Stability**: `acoustic_to_screen()`과 `screen_to_acoustic()` 양방향 음향 좌표계 변환을 적용하여, 확대/축소 시에도 오버레이 위치가 100% 흡착 유지

### 2) 256×1024 C++/C# Scan Conversion Engine
- **Raw Acoustic Matrix**: `256 Vector Scanlines × 1024 Depth Samples` (`float[256 * 1024]`)
- **N-Stage Processing Chain**:
  - `Stage 1`: Spatial Speckle Filter (3×3 수치 스펙클 노이즈 제거)
  - `Stage 2`: Log Compression & Dynamic Range Mapping
  - `Stage 3`: Polar-to-Cartesian ($r, \theta \to x, y$) Scan Conversion
- **C# Managed Pipeline Controller**: N-Stage 파이프라인 제어 및 버퍼/파라미터 디렉팅

### 3) Normalized Acoustic Coordinate System $(u, v)$ Overlay Store
- Scan Conversion 이전 정규화 음향 좌표계 $(u, v) \in [0.0..1.0] \times [0.0..1.0]$ 기반 오버레이 분리 저장
- `export_overlay_store_json()`: 이미지 픽셀 데이터와 완전 분리된 독립 JSON 오버레이 저장/불러오기 지원

### 4) Vscan Air 동등 이상 10대 Advanced Measurement UI & Operation
- Touch 2.5x 돋보기 휠 (Loupe Glass)
- Freehand Trace 둘레(cm) & 면적(cm²) Shoelace 수치 연산
- Multi-Caliper Color Coding (D1 Cyan, D2 Yellow, D3 Magenta, D4 Lime)
- Magnetic Edge Snap to Tissue Boundary
- Interactive Caliper Lock / Unlock Toggle (`is_caliper_locked`)
- Auto Ratio (D1/D2) & Stenosis % Calculator
- Interactive Label Drag & Position Adjust
- One-Touch Caliper Undo (`undo_last_caliper()`)
- Real-Time Unit Switcher (cm ↔ mm ↔ in)
- Touch Haptic & Visual Pulse Feedback

### 5) 2차 5대 OB/GYN/Abdomen/POCUS 임상 어플리케이션
- Hadlock 공식 기반 GA/EFW 자동 산출 연산 엔진
- GYN & Abdomen 3D Organ Volume Package ($Vol = L \times W \times H \times 0.5233\text{ cm}^3$)
- POCUS eFAST Rapid Trauma Protocol Checklist (6대 스캔 영역 가이드 및 Free Fluid 체크리스트)
- Dual Split-Screen Comparison Mode (`is_split_screen`: Left B-Mode / Right Color Doppler)
- Multi-Application Quick Selector (OB, GYN, Abdomen, POCUS, Cardiac)

### 6) 1차 핵심 POCUS 초음파 기능
- Interactive TGC Visual Curve Overlay (6개 노드 연동)
- Cine Loop Multi-Frame Player (▶/⏸, ▶|/|◀, 0.5x~2.0x, FR: XX/60)
- BodyMark Pictogram Library (Abdomen, Heart, Kidney, Carotid, Thyroid)
- POCUS Quick Patient Worklist & DICOM SR Export
- Full-Screen Clinical Viewport & Probe Status (🔋 92%, 🌡️ 36.5°C, 📶 5G)
