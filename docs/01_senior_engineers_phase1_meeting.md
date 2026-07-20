# 📋 Vscan Air 기능 도출 시니어 4인 회의록 (Phase 1)

**일시**: 2026년 7월 20일  
**참석자**:
1. **Dr. Alex Vance** (20년차 DICOM / 의료 영상 전송 시니어 엔지니어)
2. **Dr. Elena Rostova** (20년차 Imaging & Signal Processing 시니어 엔지니어)
3. **Dr. Kenji Sato** (20년차 Medical Main UI / UX 시니어 엔지니어)
4. **Marcus Brody** (20년차 핸드헬드 초음파 POCUS PM)

---

## 🔍 1. 각 분야별 기능 검토 및 심도 토의

### 1) DICOM & PACS 통합 관점 (Dr. Alex Vance)
> "핸드헬드 초음파가 현장에서 가치를 가지려면 단독 스캔으로 끝나는 것이 아니라 병원의 **PACS/EMR 시스템과 즉시 동기화**되어야 합니다. 워크리스트(Modality Worklist - MWL)에서 환자 정보를 자동으로 끌어오고, 스캔 종료 후 **DICOM Structured Report (SR) 및 C-STORE 전송**이 원터치로 이뤄지는 POCUS 전용 DICOM 워크플로우를 최우선 순위로 구축해야 합니다."

### 2) Cine Loop & 영상 제어 관점 (Dr. Elena Rostova)
> "스마트폰 화면 특성상 실시간 스캔과 FREEZE 후 영상 재검토가 매우 자주 일어납니다. **최대 60프레임 Cine Loop 멀티프레임 재생기(Play/Pause, Step, 0.5x/1.0x/2.0x 속도 제어, Frame Slider)**가 필수적입니다. 또한 수성/지성 조직감 조절을 위한 **TGC(Time Gain Compensation) 실시간 대화형 연동 곡선**이 화면상에 오버레이로 그려져야 합니다."

### 3) Main UI / UX 관점 (Dr. Kenji Sato)
> "세로 모드(Portrait) 중심의 한 손 조작 환경에서는 버튼이 커야 하고 타겟팅이 명확해야 합니다. **Full-Screen Clinical Viewport Toggle(⛶ FULL 버튼)**을 통해 불필요한 바를 숨기고 뷰포트 공간을 최대화해야 합니다. 또한 **BodyMark(바디마크 픽토그램 오버레이)** 선택 및 프로브 탐촉자 위치 표시가 직관적으로 제공되어야 합니다."

### 4) POCUS 시장 & 워크플로우 관점 (Marcus Brody)
> "응급실, 구급차, 외래 POCUS 환경에서는 기기의 상태 파악과 신속성이 생명입니다. **프로브 배터리 잔량(🔋 92%), 헤드 온도(🌡️ 36.5°C), 5G Wi-Fi 연결 상태**가 상단에 실시간으로 표시되어야 하며, 복부/심장/신장/경동맥/갑상선 5대 바디마크 라이브러리가 즉시 지원되어야 합니다."

---

## 🏆 2. 최종 합의: 최우선 개발 5대 기능 선정

| 우선순위 | 담당 시니어 | 핵심 기능 명칭 | 주요 구현 내역 |
| :---: | :---: | :--- | :--- |
| **1** | Dr. Elena Rostova | **Interactive TGC Visual Curve Overlay** | 6개 깊이별 TGC 제어 노드를 연결하는 Cyan 곡선 오버레이 및 노드 터치 드래그 연동 |
| **2** | Dr. Elena Rostova | **Cine Loop Multi-Frame Player & Frame Slider** | FREEZE 모드 전환 시 자동으로 나타나는 Cine 컨트롤러 (▶/⏸, ▶\|/\|◀, 0.5x~2.0x, FR: XX/60) |
| **3** | Dr. Kenji Sato | **BodyMark Pictogram & Probe Marker System** | Abdomen, Heart (PLAX), Kidney, Carotid Artery, Thyroid 픽토그램 벡터 오버레이 |
| **4** | Dr. Alex Vance | **POCUS Quick Patient Worklist & DICOM SR Export** | MWL 환자 선택 모달 및 스캔 종료 시 DICOM SR (Structured Report) 즉시 생성 |
| **5** | Marcus Brody | **Full-Screen Clinical Viewport & Probe System Status** | ⛶ FULL 버튼 조작 및 프로브 배터리(92%), 온도(36.5°C), 5G 연결 상태 실시간 표시 |
