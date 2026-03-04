# Timer App Group Migration Plan

## Goal

Widget/Live Activity extension에서 `RealmSwift` 의존성을 제거하고, 타이머 제어 상태를 `App Group` 기반 공유 상태로만 처리한다.

## Current Constraints

- App Group ID: `group.com.Leo.YoriBogo`
- Widget intent가 현재 Realm 직접 접근 중
- Widget target에 `RealmSwift` 링크/임베드가 남아 있음
- Live Activity 갱신은 `ActivityKit`로 유지 가능
- (resolved) `LiveActivityManager` 활성 여부를 권한 기반으로 동적 판단하도록 전환
- (resolved) 앱 시작 시 `endAll()` 강제 종료 제거

## Progress

- Stage 1: completed
- Stage 2: completed
- Stage 3: completed
- Stage 4: completed
- Stage 5: completed
- Stage 6: completed
- Stage 7: in progress

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

### Stage 7 - 잠금화면/백그라운드 제어 동기화 보강

- 문제 시나리오:
  - 잠금화면/Live Activity 버튼으로 정지/취소는 되었지만 Expanded/Dynamic Island UI가 계속 카운트되는 현상
  - 동일 버튼 연타 시(특히 pause/resume 교차 탭) 상태 역전/시간 리셋 위험
- 조치:
  - Intent에서 `activityID`를 우선 타겟팅하고, 미매칭 시 `timerID` fallback 유지
  - Intent 상태 전이를 멱등하게 처리
    - 이미 pause 상태에서 pause 재호출 시 no-op
    - 이미 running 상태에서 resume 재호출 시 no-op
  - Intent 내부 상태 변경 구간을 잠금(`NSLock`)으로 직렬화해 연속 탭 경쟁 완화
  - Widget UI 렌더링 시 `context.state`보다 App Group의 `SharedTimerState`를 우선 반영해 표시 동기화
- 완료 조건:
  - 잠금화면/Expanded에서 pause/cancel 직후 표시가 running에 머물지 않고 즉시 정합하게 반영
  - pause/resume 연타 시 남은 시간이 임의로 리셋되거나 상태가 역전되지 않음

## Verification Checklist

- `rg "import RealmSwift" YoriBogoWidgets YoriBogo/Widgets` 결과 0건
- `project.pbxproj` 내 widget target의 Realm 참조 0건
- Live Activity 버튼으로 pause/resume/cancel 동작 확인
- 앱 진입 시 타이머 리스트 상태 일치 확인
- 잠금화면(앱 종료 상태)에서 pause/resume/cancel 모두 정상 동작 확인
- 포그라운드 복귀 시 App Group/Realm/UI/Live Activity 4자 상태 일치 확인
- 동일 버튼 연타(예: pause 2회, resume 2회)에서도 상태가 안정적으로 유지됨
- 잠금화면 Expanded에서 pause/cancel 직후 1~2초 내 카운트다운 정지/종료 반영 확인

## Confirmation Points

- Stage 1 완료 후 컨펌
- Stage 2 완료 후 컨펌
- Stage 3 완료 후 컨펌
- Stage 4 완료 후 컨펌
- Stage 5 완료 후 컨펌
- Stage 6 완료 후 컨펌
- Stage 7 완료 후 컨펌
