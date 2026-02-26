# Timer App Group Migration Plan

## Goal

Widget/Live Activity extension에서 `RealmSwift` 의존성을 제거하고, 타이머 제어 상태를 `App Group` 기반 공유 상태로만 처리한다.

## Current Constraints

- App Group ID: `group.com.Leo.YoriBogo`
- Widget intent가 현재 Realm 직접 접근 중
- Widget target에 `RealmSwift` 링크/임베드가 남아 있음
- Live Activity 갱신은 `ActivityKit`로 유지 가능
- 현재 `LiveActivityManager.isEnabled = false`로 시작/동기화가 비활성화됨
- 앱 시작 시 `endAll()` 호출로 기존 Live Activity를 강제 종료함

## Progress

- Stage 1: completed
- Stage 2: completed
- Stage 3: pending
- Stage 4: pending
- Stage 5: pending
- Stage 6: pending

## Stage Plan

### Stage 1 - Shared State Layer 추가

- `SharedTimerState` 모델 추가
- `TimerSharedStateStore`(UserDefaults suite 기반) 추가
- 최소 상태 필드 정의 및 다중 타이머 저장 구조 정의
- 저장 구조: `timerID` key 기반 dictionary 또는 `[SharedTimerState]` + 인덱스 맵
- 필드:
  - `timerID`
  - `title`
  - `startTime`
  - `endTime`
  - `isRunning`
  - `remainingSeconds`
  - `lastUpdatedAt`
  - `version`
- 완료 조건:
  - 앱/위젯 양쪽에서 참조 가능한 공용 상태 저장소 코드 존재
  - 타이머 N개 동시 처리 가능한 key 기반 데이터 모델 확정

### Stage 2 - App(TimerManager)에서 App Group 상태 쓰기

- start/pause/restart/cancel/delete/complete/update 동작 시 App Group 상태 동기화
- 알림 스케줄 owner를 앱으로 단일화(중복 등록 방지)
- 완료 경계 처리 규칙 정의:
  - `endDate <= now`면 running 상태라도 complete로 정규화
  - pause/resume 연타에도 idempotent 하게 처리
- 완료 조건:
  - 앱 동작만으로 App Group 상태가 일관되게 갱신됨
  - 동일 타이머 반복 액션 시 상태 꼬임이 없음

### Stage 3 - Widget Intent Realm 제거

- `PauseResumeTimerIntent`, `CancelTimerIntent`에서 Realm 접근 제거
- App Group 상태만 읽고 상태 전이 수행
- Activity 업데이트/종료 로직은 유지
- 잠금화면 실행 정책 명시:
  - `authenticationPolicy`를 의도에 맞게 명시 (`alwaysAllowed` 또는 `requiresAuthentication`)
  - `openAppWhenRun = false` 유지 시 앱 비실행 상태에서도 intent 완결성 보장
- 완료 조건:
  - 위젯 제어가 Realm 없이 동작
  - 잠금화면에서 제어 시 인증/실행 UX가 의도대로 동작

### Stage 4 - 앱에서 App Group 변경 반영

- 앱 활성화 시점(`sceneDidBecomeActive`) + 초기 복원 시점에서 App Group -> 앱 상태 반영
- Realm은 앱 내부 단일 소스로 유지하되, 외부 조작(Intent) 결과를 흡수
- 충돌 해결 규칙 명시:
  - `version` 우선, 동률 시 `lastUpdatedAt` 비교 (last-write-wins)
  - 선택적으로 `writer`(`app`/`intent`) 필드로 디버깅 가능하게 유지
- 완료 조건:
  - 위젯 제어 후 앱 진입 시 UI/Realm 상태 정합성 유지
  - 충돌 상황에서도 결정 규칙이 일관됨

### Stage 5 - Widget Target Realm 링크 제거

- Widget target에서 `RealmSwift` package dependency 제거
- Widget target의 Frameworks/Embed Frameworks에서 Realm 제거
- Widget target에서 Realm 관련 소스 참조 제거
- 완료 조건:
  - `YoriBogoWidgetsExtension.appex/Frameworks`에 `RealmSwift.framework` 미포함

### Stage 6 - Live Activity 생명주기 안정화

- 앱 시작 시 무조건 `endAll()` 하던 동작 제거 또는 조건부화
- `LiveActivityManager.isEnabled`를 실제 운영 값으로 전환
- Activity stale/종료 시점 정리:
  - 필요 시 `ActivityContent(..., staleDate:)` 기반 stale 처리
  - complete/cancel 시 dismissal policy 점검 (`immediate` vs `after`)
- 완료 조건:
  - 잠금화면에서 제어 후 앱 복귀/재실행해도 Live Activity가 불필요하게 끊기지 않음

## Verification Checklist

- `rg "import RealmSwift" YoriBogoWidgets YoriBogo/Widgets` 결과 0건
- `project.pbxproj` 내 widget target의 Realm 참조 0건
- Live Activity 버튼으로 pause/resume/cancel 동작 확인
- 앱 진입 시 타이머 리스트 상태 일치 확인
- 잠금화면(앱 종료 상태)에서 pause/resume/cancel 모두 정상 동작 확인
- 포그라운드 복귀 시 App Group/Realm/UI/Live Activity 4자 상태 일치 확인
- 동일 버튼 연타(예: pause 2회, resume 2회)에서도 상태가 안정적으로 유지됨

## Confirmation Points

- Stage 1 완료 후 컨펌
- Stage 2 완료 후 컨펌
- Stage 3 완료 후 컨펌
- Stage 4 완료 후 컨펌
- Stage 5 완료 후 컨펌
- Stage 6 완료 후 컨펌
