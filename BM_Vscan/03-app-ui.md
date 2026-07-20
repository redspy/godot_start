# 3. 앱 UI/UX 상세 구조 (매뉴얼 기반)

공식 유저 매뉴얼(FCC 공개 PDF) 목차를 통해 확보한 실제 앱 화면/메뉴 구조.

## 3-1. 온보딩 / 계정

- Vscan Air 계정 생성 → 앱 등록 → 프로브 등록(기존 계정으로)
- Adding users (다중 사용자 추가), 사용자별 로그인/로그아웃
- Guest mode: 로그인 없이 스캔 가능 (긴급 상황 대응)
- 계정 삭제 기능도 별도 존재

## 3-2. 메인 스캔 화면 구성 (B-mode 기준 실측 레이아웃)

### 상단 상태바
- 배터리 잔량 아이콘
- 무선 연결 품질 표시기 (Wi-Fi 신호 세기)
- 프로브 온도(열) 인디케이터 — 과열 시 열 관리(thermal management) 알림
- 선택된 프리셋 이름
- Exam 번호, 현재 exam 내 이미지/비디오 개수 카운터

### 화면 중앙
- 이미지 방향 마커(orientation marker)
- 이미지 크롭 경계 표시 (노란 점선)
- Thermal Index(TI) / Mechanical Index(MI) 안전 지표 실시간 표시
- Focus marker, Depth 표시

### 하단 컨트롤바
- 비디오/이미지 저장(Store) 버튼
- Freeze(정지) 버튼
- Color Flow(도플러) 토글
- 추가 옵션 메뉴

### 좌/우 패널 (스와이프 제스처 기반 — 특징적인 UX)
- 왼쪽 패널: 화면을 좌→우로 스와이프하거나 좌상단 프로브 아이콘 탭 → 프리셋 목록 + 메뉴 표시
- 오른쪽 패널: 화면을 우→좌로 스와이프하거나 우상단 "Exams" 아이콘 탭 → 현재 exam 접근, exam 종료, 과거 저장된 exam 리뷰
- 좌/우 패널을 열면 라이브 스캔이 자동으로 freeze 상태로 전환됨 (실기기 조작 중 실수 방지 설계)

## 3-3. 스캔 모드

B-mode(흑백), Color Doppler(컬러 플로우), Pulsed Wave(PW) Doppler, M-mode.
HD-SRI(고해상도 스펙클 감소 이미징), SignalMAX(화질 기술), XDclear(SL 모델 화질 기술).

## 3-4. 프리셋 (트랜스듀서별 상이)

| Curved | Linear | Sector |
|---|---|---|
| Abdominal(복부) | Vascular(혈관) | Abdominal |
| Cardiac(심장) | Nerves(신경) | Cardiac |
| MSK(근골격) | Small Parts | OB-GYN |
| OB-GYN(산부인과) | MSK | Lung |
| Vascular | Lung | TCD(경두개도플러) |
| Lung(폐) | Neo Head(신생아 두부) | Cardiac guidance* |
| Bladder volume*(방광용적) | Ophthalmic(안과) | Bladder volume* |
| Lung guidance* | Aesthetics*, Lung guidance* | Lung guidance* |

(*표시는 옵션/유료 애드온, 국가별 미제공 가능)

## 3-5. 측정/주석 도구

- 기본 거리/각도 측정, 자유 텍스트 주석(annotation) 도구
- OB(산과) 측정: 태아 크기, 양수량 체크, angle of progression(분만 진행각), 예상 체중(EFW) 등
- Heart Rate 계산: PW/M-mode에서 1/2/3 beat 분석 선택 가능
- 측정 단위: cm/mm 선택

## 3-6. AI 기능

- **Vscan Air CL**: AI 기반 자동 방광 용적 측정(Auto Bladder) — 불필요한 도뇨(catheterization) 감소 목적
- **Vscan Air SL + Caption AI** (심장 전용, 태블릿 7.3"↑ 필요):
  - 실시간 프로브 조작 가이드(화살표 등으로 "probe를 이렇게 움직이세요" 안내) + 품질 미터
  - AutoCapture: 품질 기준 충족 시 손 안 대고 자동 클립 저장
  - AutoEF: Plax/AP2/AP4 뷰 조합으로 좌심실 박출률(LVEF) 자동 계산
  - 표준 심장 뷰 10종, 사용자 워크플로우에 맞게 커스터마이즈 가능

## 3-7. 리뷰/저장/내보내기

- Review Current Exam / 과거 exam 리콜 / Audit Logs(감사 로그)
- Export Data: 개별 이미지/비디오 공유, exam 전체 공유
- DICOM Image Server 전송, Secure DICOM, Network Shared Folder 전송
- 서드파티 클라우드는 DICOMweb 프로토콜 지원
- 데이터는 기기 내 프라이빗 저장공간에 격리 저장 (다른 앱 접근 불가) — 의료정보 보안 설계

## 3-8. 설정(Configuration) 메뉴 — 실제 항목 전체

- Scan Settings: Centerline Marker, Focus Marker, TGC(Time Gain Compensation, 최대 6단), Doppler Audio on/off, Cardiac Flip L/R, Auto Freeze Time, Clip Duration(비디오 버퍼 길이), Probe Button Action(프로브 물리버튼을 Freeze/Save/Off 중 매핑)
- Measurements: Heart Rate 1/2/3-beat, 단위(cm/mm)
- Regional Preferences: 언어 (영어 포함 26개 언어 지원)
- Security: Automatic Sign Out(자동 세션종료 시간), Data Access PIN
- Application Mode: Preview Mode on/off
- Probe Storage: 장기보관용 "Storage Mode" (최대 36개월)
- 기타: Store Binary Image Data(비디오와 함께 raw 데이터 저장 여부)
- 추가로 User Account / Support(등록/미등록별 상이) / Diagnostics(진단 테스트) / About 메뉴 존재

## 출처
- FCC 유저 매뉴얼: https://fcc.report/FCC-ID/YOM-VSCANAIR/5040759.pdf
- Configuration: https://vscanair-support.gehealthcare.com/support/solutions/articles/47001169992-configuration
- Display Screen: https://vscanair-support.gehealthcare.com/support/solutions/articles/47001169694-vscan-air-display-screen
- Left Panel/Display Features: https://vscanair-support.gehealthcare.com/support/solutions/articles/47001170423-display-features
- Probes and Presets: https://vscanair-support.gehealthcare.com/support/solutions/articles/47001170581-probes-and-presets
