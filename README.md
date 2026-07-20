# godot_start

Godot 4 프로젝트를 안드로이드 실기기에 빌드/배포하는 것을 목표로 하는 스타터 프로젝트입니다.

## 개발 환경

| 구성요소 | 버전/경로 |
|---|---|
| Godot | 4.7.1.stable (arm64, `brew install --cask godot`) |
| Android SDK | `~/Library/Android/sdk` (platform-tools, build-tools 30.0.3 / 34.0.0) |
| Java | OpenJDK 17 (`brew install openjdk@17`, keytool/apksigner용) |
| Export Templates | `~/Library/Application Support/Godot/export_templates/4.7.1.stable/` |

Godot 에디터를 처음 여는 사람은 `export/android/android_sdk_path`, `export/android/java_sdk_path`가
에디터 전역 설정(`~/Library/Application Support/Godot/editor_settings-4.7.tres`)에 잡혀 있는지 확인하세요.
GUI로 Godot.app을 더블클릭해서 켜면 셸 프로파일(PATH)을 읽지 않으므로, 이 값들이 비어 있으면
Project > Export 에서 Android 프리셋 하단에 경고가 뜹니다.

## Godot 프로젝트 폴더 구조

Godot 4는 프로젝트 루트의 `project.godot`를 기준으로 모든 리소스를 `res://`로 참조합니다.
이 저장소 기준 구조는 다음과 같습니다.

```
godot_start/
├── project.godot         # 프로젝트 엔진 설정 (필수, 아래 설명)
├── main.tscn              # 메인 씬 (앱 실행 시 처음 로드되는 화면)
├── export_presets.cfg     # 내보내기(Export) 프리셋 정의 (Android 등)
├── .gitignore
├── README.md
├── .godot/                 # 에디터가 자동 생성하는 캐시/임포트 폴더 (git 미포함)
└── build/                  # CLI로 내보낸 apk 산출물 (git 미포함)
```

프로젝트가 커지면 보통 아래와 같은 폴더들이 추가됩니다 (지금은 아직 없음).

- `scenes/` : 씬(.tscn) 파일 모음
- `scripts/` : GDScript(.gd) 또는 C# 스크립트
- `assets/` : 이미지, 오디오, 폰트 등 원본 리소스
- `addons/` : 에디터 플러그인 (버전관리 시 반드시 포함해야 함)

## 각 초기 파일의 용도

### `project.godot`
Godot 엔진이 읽는 프로젝트 설정 파일(ini 형식)입니다. 에디터의 "Project Settings"에서 바꾸는 값들이
이 파일에 저장됩니다. 직접 수정도 가능하지만 보통은 에디터 UI를 통해 편집합니다.

현재 설정된 값:
- `application/config/name` : 프로젝트/앱 이름 (`Godot Start`)
- `application/run/main_scene` : 실행 시 최초로 로드할 씬 (`res://main.tscn`)
- `application/config/features` : 이 프로젝트가 생성된 Godot 버전 및 프리셋(`4.7`, `Mobile`)
- `rendering/renderer/rendering_method` : 모바일 기기에 적합한 `mobile` 렌더러 사용
- `rendering/textures/vram_compression/import_etc2_astc` : ETC2/ASTC 텍스처 압축 활성화
  (Android 빌드 시 필수 옵션. 꺼져 있으면 Export가 에러로 막힘)

### `main.tscn`
앱 실행 시 최초로 뜨는 씬입니다. `Node2D` 루트 아래 배경(`ColorRect`)과 `Label`이 있고,
`Label`에 붙은 GDScript가 화면 터치(`InputEventScreenTouch`)/마우스 클릭을 감지해
탭 횟수를 세어 텍스트로 표시합니다. 실기기에서 입력이 정상적으로 들어오는지 확인하기 위한
최소 동작 확인용 씬입니다.

### `export_presets.cfg`
Project > Export 메뉴에서 설정하는 내보내기 프리셋(Android, iOS, Web 등)이 저장되는 파일입니다.
지금은 Android 프리셋 하나만 있습니다.

주요 옵션:
- `platform="Android"`, `runnable=true` : 실행 가능한 Android 빌드
- `export_path="build/android/GodotStart.apk"` : `godot --export-debug/--export-release` CLI 호출 시 기본 출력 경로
- `architectures/arm64-v8a=true` : arm64 기기만 타겟 (다른 아키텍처는 꺼둠, 빌드 속도/용량 절약)
- `package/unique_name="org.godotengine.godotstart"` : 안드로이드 패키지명(applicationId)
- `gradle_build/use_gradle_build=false` : Gradle 커스텀 빌드 대신 Godot 내장 빌드 시스템 사용
  (별도 네이티브 플러그인이 필요 없다면 이 편이 더 빠르고 설정이 단순함)
- `signing/debug_keystore*` : 디버그 서명 키 (비워두면 Godot가 에디터 전역 설정의 기본 디버그
  키스토어를 자동 생성/사용함, 비밀번호는 Android 표준 기본값 `android`이므로 민감정보 아님)
- `signing/release_keystore*` : 아직 비어있음. 릴리즈(정식) 배포 시 별도 keystore를 만들어
  채워야 하며, 이 값들은 절대 커밋하면 안 됨(비워두는 대신 로컬 환경변수/CI 시크릿으로 관리 권장)

### `.gitignore`
Godot 공식 템플릿 기준 + 이 프로젝트에서 추가한 항목:
- `.godot/` : 에디터가 매번 재생성하는 임포트 캐시. 기기/에디터 버전마다 달라질 수 있어 추적 안 함
- `/build/` : CLI export로 생성되는 apk 산출물
- `.DS_Store` : macOS 폴더 메타데이터
- `.claude/settings.local.json` : Claude Code 로컬 권한 설정 (사용자 로컬 환경 전용)

### `.godot/` (git 미포함, 참고용)
에디터가 프로젝트를 열거나 `godot --headless --path . --import`을 실행할 때 자동 생성하는 캐시 폴더입니다.
UID 캐시, 임포트된 리소스, 씬 폴딩 상태 등 로컬 편집 상태를 담고 있어 다른 환경에서 그대로 재사용할
이유가 없고, 각 클라이언트가 프로젝트를 처음 열 때 자동으로 다시 만들어집니다.

## 안드로이드 빌드 & 배포 (CLI)

에디터 GUI 없이 커맨드라인만으로 디버그 apk를 빌드해서 연결된 기기에 설치/실행할 수 있습니다.

```bash
cd godot_start

# 1) 디버그 APK 빌드 (export_presets.cfg의 "Android" 프리셋 사용)
godot --headless --export-debug "Android" build/android/GodotStart.apk

# 2) adb로 연결된 기기에 설치 (usb 디버깅 허용 + adb devices에 device로 잡혀야 함)
adb install -r build/android/GodotStart.apk

# 3) 앱 실행
adb shell monkey -p org.godotengine.godotstart -c android.intent.category.LAUNCHER 1
```

에디터 GUI를 쓸 경우, 우측 상단의 기기 드롭다운에서 연결된 안드로이드 기기를 선택하고
Play 버튼을 누르면 동일하게 원클릭 배포/실행됩니다 (SDK/Java 경로가 이미 설정되어 있음).

## 새 기기에서 처음 세팅할 때

1. `brew install --cask godot`
2. `brew install openjdk@17`
3. Android SDK 준비 (Android Studio 설치 후 SDK Manager로 platform-tools, build-tools 받기)
4. Godot 에디터 실행 > Editor Settings > Export > Android 에서 SDK/Java 경로 지정
   (또는 `ANDROID_HOME` 환경변수를 설정해두면 Godot가 자동 인식)
5. 에디터의 Export 프리셋 다운로드 안내를 따라 현재 Godot 버전에 맞는 Export Templates 설치
6. 안드로이드 기기에서 개발자 옵션 > USB 디버깅 활성화 후 USB 연결, 팝업에서 이 PC 신뢰(허용)
