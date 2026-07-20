# 🩺 Handheld Ultrasound System Engine (Godot 4.7)

본 프로젝트는 고성능 C++/C# 신호 처리 파이프라인과 Godot 엔진을 기반으로 구축된 최첨단 핸드헬드 초음파 시스템 진단 어플리케이션입니다.

---

## 📁 회의록 및 아키텍처 문서 (Documentation)

모든 회의록 및 상세 아키텍처 문서는 [`docs/`](./docs) 디렉토리에 정리되어 있습니다.

- 📋 **Phase 1 회의록**: [01_senior_engineers_phase1_meeting.md](./docs/01_senior_engineers_phase1_meeting.md) (TGC 오버레이, Cine Loop, BodyMark, DICOM SR, 프로브 상태)
- 📋 **Phase 2 회의록**: [02_measurement_senior_phase2_meeting.md](./docs/02_measurement_senior_phase2_meeting.md) (OB Hadlock, 3D Volume, eFAST 체크리스트, Dual Split)
- 📋 **Vscan Air 10대 UX 회의록**: [03_vscan_air_measurement_10_features_meeting.md](./docs/03_vscan_air_measurement_10_features_meeting.md) (2.5x 돋보기 휠, Trace 면적, Color Coding 등)
- 📋 **Scan Conversion 아키텍처 회의록**: [04_scan_conversion_architecture_meeting.md](./docs/04_scan_conversion_architecture_meeting.md) (256×1024 C++/C# 파이프라인 & 음향 좌표계)
- 📄 **구현 계획서**: [IMPLEMENTATION_PLAN.md](./docs/IMPLEMENTATION_PLAN.md)
- 📊 **검증 보고서**: [WALKTHROUGH.md](./docs/WALKTHROUGH.md)

---

## 🚀 주요 기능 아키텍처

1. **B-Mode Pinch Zoom System**: 멀티 터치 핀치 제스처를 감지하여 1.0x~3.0x 배율 스캔 조작
2. **256×1024 C++/C# Scan Converter**: 256 라인 × 1024 샘플 Raw 음향 어레이 N-Stage 신호 처리 파이프라인 (`src/cpp/ultrasound_scan_converter.cpp`, `src/csharp/UltrasoundPipelineController.cs`)
3. **Normalized Acoustic Coordinate System $(u, v)$ Overlay Store**: Scan Conversion 이전 정규화 음향 좌표계 오버레이 분리 저장 및 독립 JSON 메타데이터 내보내기/불러오기
4. **Vscan Air 10대 Advanced Measurement UX**: 2.5x 돋보기 휠 (Loupe Glass), Freehand Trace 면적/둘레, Color-Coded Multi-Caliper, Magnetic Edge Snap, Caliper Lock, Auto Ratio/Stenosis 등
5. **OB/GYN/Abdomen/POCUS 임상 패키지**: Hadlock GA/EFW 산과 연산 엔진, 3D 장기 부피 연산기, POCUS eFAST 트라우마 체크리스트, Dual Split-Screen 모드
