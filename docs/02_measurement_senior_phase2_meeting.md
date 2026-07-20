# 📋 Measurement 시니어 동참 2차 5대 어플리케이션 도출 회의록 (Phase 2)

**일시**: 2026년 7월 20일  
**참석자**:
1. **Dr. Sophia Lin** (20년차 Measurement & Clinical Application 시니어 엔지니어 - **신규 합류**)
2. **Dr. Kenji Sato** (20년차 Medical Main UI / UX 시니어 엔지니어)
3. **Dr. Elena Rostova** (20년차 Imaging & Signal Processing 시니어 엔지니어)
4. **Dr. Alex Vance** (20년차 DICOM / 의료 영상 전송 시니어 엔지니어)
5. **Marcus Brody** (20년차 핸드헬드 초음파 POCUS PM)

---

## 🔍 1. 임상 애플리케이션 및 측정 패키지 확충 토의

### 1) OB (산과) 정밀 측정 & Hadlock 자동 연산 엔진 (Dr. Sophia Lin)
> "산과 스캔에서는 단순 거리 측정을 넘어 **BPD(대횡두개경), FL(대퇴골길이), AC(복위), HC(두위), CRL(두둔길이)** 측정이 수반되어야 합니다. 특히 **Hadlock 수학적 연산 공식**에 기반하여 태아 임신주수(`GA: XXwXd`)와 예상태아체중(`EFW: XXXg`)이 실시간으로 연산되고, 화면 우측 하단에 **OB 리포트 테이블**로 즉시 출력되어야 합니다."

### 2) GYN & Abdomen 3D Organ Volume Package (Dr. Sophia Lin & Dr. Elena Rostova)
> "부인과 및 복부 스캔 시 자궁, 난소, 신장, 방광의 크기를 입체적으로 평가하기 위해 **장/단/고 3점 거리 측정 기반 $Vol = L \times W \times H \times 0.5233\text{ cm}^3$ 부피 자동 계산기**가 탑재되어야 합니다."

### 3) POCUS eFAST Rapid Trauma Protocol Checklist (Marcus Brody & Dr. Kenji Sato)
> "응급 외상 환자 처치(POCUS eFAST) 시 6대 핵심 영역(RUQ Morison, LUQ Splenorenal, Subxiphoid Cardiac, Pelvic Suprapubic, Right/Left Pleural) 가이드 오버레이와 **Free Fluid ([CLEAR] / [FLUID]) 수신호 체크리스트**가 병행되어야 신속한 진단이 가능합니다."

### 4) Dual Split-Screen Comparison Mode (Dr. Elena Rostova & Dr. Kenji Sato)
> "동일 부위의 B-Mode 구조와 Color Doppler 혈류를 실시간 비교하기 위한 **`🌗 DUAL` 분할 화면 모드 (Left: B-Mode Live, Right: Color Doppler Live)** 조작이 가능해야 합니다."

### 5) Multi-Application Quick Selector (Marcus Brody)
> "상단 바에서 원터치로 **👶 OB, 🧬 GYN, 🫁 Abdomen, 🚑 POCUS eFAST, ❤️ Cardiac 5대 전용 프로파일**로 즉시 전환되는 퀵 스위처가 구성되어야 합니다."

---

## 🏆 2. 최종 합의: 2차 5대 어플리케이션 우선순위

| 번호 | 담당 시니어 | 핵심 기능 명칭 | 주요 구현 스펙 |
| :---: | :---: | :--- | :--- |
| **1** | Dr. Sophia Lin | **Advanced OB Measurement & GA/EFW Calculators** | Hadlock 공식을 적용한 GA/EFW 실시간 연산 및 우측 하단 리포트 오버레이 |
| **2** | Dr. Sophia Lin | **GYN & Abdomen 3D Volume Package** | `CaliperType.VOLUME_3PT`: $Vol = L \times W \times H \times 0.5233\text{ cm}^3$ 부피 자동 계산 |
| **3** | Marcus Brody | **POCUS eFAST Rapid Trauma Protocol Checklist** | eFAST 6대 응급 영역 가이드 오버레이 및 Free Fluid 체크리스트 |
| **4** | Dr. Elena Rostova | **Dual Split-Screen Comparison Mode** | `is_split_screen` 뷰포트 좌우 분할 (Left B-Mode / Right Color Doppler) |
| **5** | Dr. Kenji Sato | **Multi-Application Quick Selector** | TopBar 5대 전용 임상 애플리케이션 원터치 프로파일 전환 퀵 패널 |
