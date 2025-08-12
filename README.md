# Todo CLI

what've i gotta do?... sorry seems to be the hardest word.

## 기능

- 마크다운 텍스트 파일에 할일 저장
- Curses 기반의 대화형 터미널 사용자 인터페이스
- 할일 추가, 편집, 삭제 및 완료/미완료 표시
- 할일 항목 순서 변경 기능
- Undo(작업 취소) 및 Redo(작업 다시 실행) 지원 (최대 100개 작업까지)
- 도움말 화면 제공

## 설치 방법

필요한 의존성을 설치하려면:

```
bundle install
```

## 실행 방법

다음 명령어로 앱을 실행할 수 있습니다:

```
./bin/todo
```

또는 다음과 같이 실행할 수도 있습니다:

```
bundle exec ruby todo.rb
```

## 사용 방법

### 기본 단축키

- `↑`/`↓`: 항목 사이 이동
- `Space`: 할일 완료/미완료 토글
- `A`: 새 할일 추가
- `E`: 선택한 할일 편집
- `D`: 선택한 할일 삭제
- `Shift+↑`/`↓` 또는 `K`/`J`: 선택한 항목을 위/아래로 이동
- `Shift+Z`: 작업 취소(Undo)
- `Shift+R`: 취소한 작업 다시 실행(Redo)
- `H`: 도움말 화면 표시
- `Q`: 앱 종료

### 저장 정보

- 할일 목록: `~/.todo-cli/tasks.md` (마크다운 형식)
- 작업 기록: `~/.todo-cli/.todo_history.json` (Undo/Redo 기록)
