# 📋 Vscan Air 동등 이상 수준 Measurement UI & Operation 10대 도출 회의록

**일시**: 2026년 7월 21일  
**참석자**:
1. **Dr. Sophia Lin** (20년차 Measurement & Clinical Application 시니어 엔지니어)
2. **Dr. Kenji Sato** (20년차 Medical Main UI / UX 시니어 엔지니어)
3. **Dr. Elena Rostova** (20년차 Imaging & Signal Processing 시니어 엔지니어)
4. **Dr. Alex Vance** (20년차 DICOM / 의료 영상 전송 시니어 엔지니어)
5. **Marcus Brody** (20년차 핸드헬드 초음파 POCUS PM)

---

## 🔍 1. Vscan Air 대비 Measurement UI & Operation 격차 분석 및 토의

### 1) 터치 손가락 가림(Touch Occlusion) 및 정밀도 문제 (Dr. Sophia Lin & Dr. Kenji Sato)
> "스마트폰 화면에서 손가락으로 캘리퍼 끝점을 잡고 움직일 때 손가락이 정확한 타겟을 가리는 현상이 가장 큰 불만사항입니다. Vscan Air를 능가하려면 **캘리퍼 포인트를 터치할 때 터치 위치 상단 75px 위치에 2.5배 돋보기(Magnifying Loupe Glass) 원형 뷰포트**가 떠서 조직 경계를 0.1mm 단위로 정밀 조작할 수 있어야 합니다."

### 2) Trace / Spline 자유 곡선 면적 연산 (Dr. Elena Rostova)
> "직선 거리 측정뿐만 아니라, **터치 드래그로 복위(AC), 두위(HC), 갑상선 결절 결절 면적을 따라 선을 그리면 둘레(Perimeter cm) 및 넓이(Area cm²)**가 자동 계산되는 Trace / Ellipse Spline 측정기가 구현되어야 합니다."

### 3) 캘리퍼 시각적 구분 및 세션 관리 (Marcus Brody)
> "화면에 여러 개 캘리퍼가 찍혔을 때 어떤 선이 D1이고 D2인지 헷갈립니다. **D1(Cyan), D2(Yellow), D3(Magenta), D4(Lime)으로 색상을 자동으로 다채롭게 구분(Color-Coded Calipers)**하고, 실수로 건드려 미끄러지는 것을 방지하는 **Caliper Lock/Unlock 버튼**이 필요합니다."

---

## 🏆 2. 최종 합의: Vscan Air 동등 이상 수준 10대 Measurement UI & Operation 스펙

| 번호 | 기능 명칭 | 핵심 Operation & UI 스펙 |
| :---: | :--- | :--- |
| **1** | **Touch Magnifying Loupe Glass (돋보기 휠)** | 캘리퍼 포인트 터치 이동 시 손가락 상단 75px에 2.5배 확대 돋보기 원형 뷰포트 팝업 |
| **2** | **Freehand Trace & Spline Area / Perimeter** | 손가락 드래그로 곡선을 그려 둘레(cm) 및 면적(cm²) Shoelace 공식으로 자동 연산 |
| **3** | **Color-Coded Multi-Caliper Style (D1/D2/D3)** | D1(Cyan), D2(Yellow), D3(Magenta), D4(Lime) 다채로운 색상 자동 인덱싱 |
| **4** | **Magnetic Edge Snap to Tissue Boundary** | 고반사 조직/골 표면(Skull, Skin, Wall) 접근 시 캘리퍼 십자가가 자석처럼 자동 흡착 |
| **5** | **Interactive Caliper Lock / Unlock Toggle** | `is_caliper_locked`: 측정 완료 후 캘리퍼 잠금으로 의도치 않은 터치 미끄러짐 방지 |
| **6** | **Auto Ratio & Stenosis % Calculator (D1/D2)** | 2개 이상 거리 측정 시 비율(D1/D2 Ratio) 및 혈관 협착률(% Stenosis) 자동 연산 |
| **7** | **Interactive Label Drag & Position Adjust** | 측정값 텍스트 라벨("D1: 2.3cm") 위치를 자유롭게 드래그하여 배경 시야 확보 |
| **8** | **One-Touch Caliper Undo (`undo_last_caliper()`)** | 마지막 찍은 포인트를 취소하는 1-터치 Undo 버튼 지원 |
| **9** | **Real-Time Unit Switcher (cm ↔ mm ↔ in)** | 센티미터(cm), 밀리미터(mm), 인치(in) 단위 실시간 변환 렌더링 |
| **10** | **Touch Haptic & Visual Pulse Feedback** | 캘리퍼 고정 시 시각적 펄스 파동 연출 |
