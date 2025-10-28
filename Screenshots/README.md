# 📸 스크린샷 추가 가이드

이 폴더에 앱의 스크린샷을 추가하여 README.md에 표시할 수 있습니다.

## 📋 필요한 스크린샷

다음 스크린샷을 추가해주세요:

### 주요 화면 (8개)
1. **fridge.png** - 냉장고 화면 (재료 관리 및 D-day 표시)
2. **recommend.png** - 레시피 추천 화면 (보유 재료 기반 추천)
3. **recipe_list.png** - 레시피 목록 화면 (북마크 & 나의 레시피)
4. **recipe_detail.png** - 레시피 상세 화면 (재료 및 조리법)
5. **recipe_add.png** - 레시피 작성 화면 (이미지 & 단계별 입력)
6. **search.png** - 레시피 검색 화면
7. **notification.png** - 소비기한 알림 화면
8. **settings.png** - 설정 화면

## 🎨 스크린샷 가이드라인

### 권장 사양
- **기기**: iPhone 14 Pro Max (또는 iPhone 15 Pro Max)
- **해상도**: 1170 x 2532 pixels (3x)
- **형식**: PNG (투명 배경 권장)
- **파일 크기**: 각 파일 최대 1MB

### 스크린샷 촬영 방법

#### 1. 시뮬레이터에서 촬영
```bash
# 시뮬레이터에서 Cmd + S로 스크린샷 저장
# 저장 위치: ~/Desktop
```

#### 2. 실제 기기에서 촬영
```bash
# iPhone에서 볼륨 업 + 사이드 버튼 동시 누르기
# Mac으로 AirDrop 전송
```

#### 3. 스크린샷 리사이징 (필요시)
```bash
# ImageMagick 사용
brew install imagemagick
mogrify -resize 1170x2532 *.png

# 또는 macOS Preview 앱 사용
# 도구 > 크기 조절 > 1170 x 2532
```

### 스크린샷 최적화

#### PNG 압축 (파일 크기 줄이기)
```bash
# pngquant 사용
brew install pngquant
pngquant --quality=65-80 --output fridge.png fridge_original.png

# 또는 TinyPNG 웹사이트 사용
# https://tinypng.com/
```

## 📐 스크린샷 구도 권장사항

### 냉장고 화면 (fridge.png)
- 재료가 3-5개 정도 보이도록
- D-day가 다양하게 표시된 상태 (-7, -3, 0 등)
- 카테고리 칩이 보이도록

### 레시피 추천 화면 (recommend.png)
- 추천 레시피 카드 2-3개가 보이도록
- 재료 일치율 표시가 명확하게

### 레시피 상세 화면 (recipe_detail.png)
- 메인 이미지가 상단에 보이도록
- 재료 목록과 조리 단계가 일부 보이도록

### 레시피 작성 화면 (recipe_add.png)
- 이미지 업로드 UI가 보이도록
- 재료 입력 필드가 보이도록
- 단계별 입력 UI가 일부 보이도록

## 🎬 데모 영상 (선택사항)

GIF 애니메이션을 추가하면 더욱 효과적입니다:

```bash
# GIF 생성 (ffmpeg 사용)
brew install ffmpeg

# 동영상 → GIF 변환
ffmpeg -i demo.mov -vf "fps=10,scale=320:-1:flags=lanczos" -c:v gif demo.gif

# 또는 온라인 도구 사용
# https://ezgif.com/video-to-gif
```

### 추천 데모
- **fridge_demo.gif** - 재료 추가/삭제 과정
- **recommend_demo.gif** - 레시피 추천 및 상세 화면 전환
- **notification_demo.gif** - 알림 수신 및 앱 진입

## 📝 체크리스트

스크린샷 추가 완료 후 확인사항:

- [ ] 모든 스크린샷 파일 추가 (8개)
- [ ] 파일명이 README.md와 일치
- [ ] 파일 크기 최적화 (각 1MB 이하)
- [ ] 이미지 해상도 적절 (가로 1170px)
- [ ] 개인정보/민감정보 제거 확인
- [ ] README.md에서 이미지가 정상 표시되는지 확인

## 🚀 추가 후 확인

```bash
# 프로젝트 루트에서 실행
cd /path/to/YoriBogo
open README.md  # 또는 GitHub에서 미리보기
```

---

**💡 Tip**: 스크린샷은 첫인상을 결정하는 중요한 요소입니다. 깔끔하고 의미 있는 데이터가 표시된 화면을 선택하세요!
