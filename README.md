# insane-search-testbed

막힌 공개 웹페이지를 AI 에이전트가 읽을 수 있는지 테스트해보는 레포입니다.

원본은 [`fivetaku/insane-search`](https://github.com/fivetaku/insane-search)입니다.  
이 레포는 그 도구를 **Codex에서 바로 돌려보고 검증할 수 있게 만든 테스트베드**입니다.

## 한 줄로 말하면

일반 웹 요청으로는 막히는 공개 페이지를 `API`, `RSS`, `yt-dlp`, `curl_cffi`, `Playwright` 같은 여러 방법으로 다시 시도해 읽어오는 도구입니다.

여기서 중요한 말은 **공개 페이지**입니다.

로그인해야 볼 수 있는 글, 유료 글, 비공개 계정, DM, 관리자 페이지를 몰래 읽는 도구가 아닙니다.  
브라우저에서 누구나 볼 수 있거나, 공개 API나 공개 feed로 열려 있는 데이터만 다룹니다.

## 왜 필요한가요?

AI 에이전트에게 URL을 주면 이런 일이 자주 생깁니다.

- `403 Forbidden`이 뜹니다.
- 페이지는 열리는데 내용이 비어 있습니다.
- JavaScript로 렌더링되는 사이트라 HTML만 가져오면 쓸 내용이 없습니다.
- YouTube 영상인데 자막이나 설명을 못 가져옵니다.
- X, Reddit 같은 사이트가 비로그인 요청을 막습니다.

보통은 여기서 끝납니다.

insane-search는 바로 포기하지 않습니다.  
다른 공개 경로를 계속 시도합니다.

예를 들면:

- YouTube는 `yt-dlp`로 메타데이터와 자막 정보를 가져옵니다.
- Reddit은 `.rss` 같은 공개 feed를 먼저 봅니다.
- X는 oEmbed나 개별 tweet 공개 endpoint를 봅니다.
- Hacker News나 arXiv는 공개 API를 씁니다.
- 일반 사이트는 브라우저처럼 보이는 TLS 요청을 시도합니다.
- 그래도 안 되면 Playwright로 실제 브라우저 렌더링을 시도합니다.

## 이 레포는 원본과 뭐가 다른가요?

원본 `insane-search`는 Claude Code 플러그인입니다.

이 레포는 Codex에서 실험하기 쉽게 아래를 추가했습니다.

- Windows용 bootstrap 스크립트
- 테스트 실행 스크립트
- Python 의존성 목록
- Playwright 템플릿 의존성 설치
- 실제 사이트별 live route 테스트
- Windows에서 `bias_check.py`가 Phase 0 예외를 못 잡던 경로 버그 수정

즉, 이 레포는 “Codex에서 insane-search 엔진이 실제로 어디까지 되는지 확인하는 작업대”입니다.

## 설치하기

PowerShell에서 실행합니다.

```powershell
git clone https://github.com/yeohj0710/insane-search-testbed.git
cd insane-search-testbed
.\scripts\bootstrap.ps1
```

`bootstrap.ps1`이 하는 일:

- `.venv` 생성
- Python 패키지 설치
  - `curl_cffi`
  - `beautifulsoup4`
  - `PyYAML`
  - `yt-dlp`
- Playwright 템플릿용 npm 패키지 설치

## 전체 테스트 돌리기

```powershell
.\scripts\run-tests.ps1
```

성공하면 마지막에 summary/log 파일 위치가 나옵니다.

예:

```text
summary: C:\dev\insane-search-testbed\test-artifacts\summary-...
log: C:\dev\insane-search-testbed\test-artifacts\test-run-...
```

## URL 하나 직접 긁어보기

엔진은 `skills\insane-search` 폴더에서 실행합니다.

```powershell
cd skills\insane-search
..\..\.venv\Scripts\python.exe -m engine "https://example.com/" --selector h1 --json
```

YouTube 영상도 이렇게 볼 수 있습니다.

```powershell
..\..\.venv\Scripts\python.exe -m engine "https://youtu.be/vjSZIyYd0NI?si=4HCubGogjOOxnfBc" --json
```

Naver 검색도 이렇게 테스트할 수 있습니다.

```powershell
..\..\.venv\Scripts\python.exe -m engine "https://search.naver.com/search.naver?query=claude+code" --json
```

## 결과는 어떻게 읽나요?

`--json`을 붙이면 이런 값이 나옵니다.

```json
{
  "ok": true,
  "verdict": "strong_ok",
  "profile_used": "phase0:youtube",
  "summary": "Phase 0 official route: youtube:yt-dlp",
  "content_length": 591612
}
```

쉽게 보면 됩니다.

- `ok: true`면 읽기 성공입니다.
- `verdict: strong_ok`면 꽤 확실하게 성공입니다.
- `verdict: weak_ok`면 읽긴 했지만 검증 강도는 조금 약합니다.
- `profile_used`는 어떤 방식으로 성공했는지 보여줍니다.
- `trace`는 어떤 시도를 했고 어디서 막혔는지 보여줍니다.
- `content_length`는 가져온 내용 크기입니다.

## 실제로 어떤 사이트가 어떻게 됐나요?

이 레포에서 실제로 돌려본 결과입니다.

| 사이트 | 결과 | 어떻게 접근했나 |
|---|---|---|
| YouTube | 성공 | `yt-dlp`로 공개 메타데이터 수집 |
| Naver 검색 | 성공 | `curl_cffi`로 검색 HTML 수집 |
| Hacker News | 성공 | Firebase API, Algolia API 사용 |
| arXiv | 성공 | Atom API 사용 |
| X 개별 글 | 성공 | tweet-result, oEmbed 공개 endpoint 사용 |
| X timeline | 실패/제한 | 429 rate limit 발생 |
| Reddit | 불안정 | RSS는 성공할 때도 있지만 429/403 발생 가능 |
| LinkedIn | 실패 | 테스트 URL이 404였고 로그인 우회는 하지 않음 |
| example.com | 성공 | 기본 연결 확인용 |

여기서 “뚫린다”는 말은 해킹한다는 뜻이 아닙니다.

정확히는 이 뜻입니다.

> 사이트가 공개로 열어둔 다른 길을 찾아서 읽는다.

예를 들어 YouTube 페이지 HTML을 직접 읽기 어렵더라도 `yt-dlp`가 공개 메타데이터를 가져올 수 있습니다.  
X timeline은 막혀도 개별 tweet의 oEmbed는 열려 있을 수 있습니다.  
Hacker News는 HTML을 긁지 않아도 공식 공개 API가 있습니다.

## 일반 WebFetch와 뭐가 다른가요?

일반 WebFetch는 보통 한 번 요청하고 끝납니다.

insane-search는 다르게 움직입니다.

1. 먼저 플랫폼별 공개 경로를 봅니다.
2. 안 되면 일반 HTML 요청을 봅니다.
3. 안 되면 브라우저처럼 보이는 TLS 요청을 씁니다.
4. 안 되면 모바일 URL, RSS, JSON endpoint 같은 변형을 봅니다.
5. 그래도 안 되면 Playwright 브라우저 렌더링을 시도합니다.
6. 로그인/paywall이면 멈춥니다.

그래서 장점은 이것입니다.

- 한 번 막혔다고 바로 포기하지 않습니다.
- 사이트별 공개 route를 자동으로 먼저 봅니다.
- YouTube 같은 미디어 사이트는 `yt-dlp`를 씁니다.
- 결과가 진짜 내용인지 검증합니다.
- 실패해도 어디서 막혔는지 trace가 남습니다.

## 무엇에 쓸 수 있나요?

이런 용도에 잘 맞습니다.

- YouTube 영상 설명, 제목, 자막 후보 가져오기
- Naver 검색 결과 HTML 수집 테스트
- 공개 게시글 요약
- 공개 API가 있는 사이트의 데이터 수집
- AI 에이전트 리서치 자동화
- “이 URL을 AI가 읽을 수 있나?” 사전 테스트
- 사이트별 차단 지점 확인

예를 들어 이런 식입니다.

```powershell
cd skills\insane-search
..\..\.venv\Scripts\python.exe -m engine "https://youtu.be/vjSZIyYd0NI?si=4HCubGogjOOxnfBc" --json
```

이렇게 하면 YouTube 페이지를 그냥 긁는 대신, 먼저 `yt-dlp` 경로를 써서 공개 메타데이터를 가져옵니다.

## 무엇에는 못 쓰나요?

아래 용도로 쓰면 안 됩니다.

- 로그인 필요한 글 읽기
- 유료 콘텐츠 우회
- 비공개 계정 보기
- DM, 메일, 관리자 페이지 접근
- CAPTCHA를 억지로 푸는 자동화
- 사이트 약관을 무시한 대량 수집

이 도구는 공개 데이터 접근을 돕는 도구입니다.  
접근 권한이 없는 데이터를 가져오는 도구가 아닙니다.

## Codex에서 바로 플러그인처럼 쓸 수 있나요?

아직은 아닙니다.

원본은 Claude Code 플러그인 구조입니다.  
Codex에서는 지금처럼 Python engine을 직접 실행하는 방식으로 테스트했습니다.

즉, 현재 상태는 이렇습니다.

- Claude Code: 플러그인 형태로 붙일 수 있음
- Codex: 이 테스트베드에서 engine을 직접 실행 가능
- Codex용 완전한 wrapper/skill: 아직 별도 작업 필요

## 파일 구조

중요한 파일만 보면 됩니다.

```text
scripts/bootstrap.ps1          처음 설치
scripts/run-tests.ps1          전체 테스트 실행
requirements-test.txt          Python 테스트 의존성
skills/insane-search/engine    실제 fetch 엔진
skills/insane-search/tests     live route 테스트
test-artifacts                 테스트 결과 로그
```

## 빠른 시작

처음이면 이것만 실행하면 됩니다.

```powershell
git clone https://github.com/yeohj0710/insane-search-testbed.git
cd insane-search-testbed
.\scripts\bootstrap.ps1
.\scripts\run-tests.ps1
```

URL 하나만 바로 보고 싶으면:

```powershell
cd skills\insane-search
..\..\.venv\Scripts\python.exe -m engine "여기에_URL" --json
```

## 요약

이 레포는 AI 에이전트가 공개 웹페이지를 어디까지 읽을 수 있는지 테스트하는 레포입니다.

차별점은 단순합니다.

> 한 번 막히면 끝나는 게 아니라, 공개로 열려 있는 다른 길을 계속 찾아본다.

YouTube, Naver, Hacker News, arXiv처럼 공개 경로가 있는 곳은 잘 됩니다.  
X나 Reddit처럼 rate limit이 강한 곳은 일부만 됩니다.  
로그인해야 하는 곳은 안 됩니다.

그래서 이 레포는 “웹을 무조건 긁는 도구”가 아니라, **공개 데이터 접근 가능성을 AI 에이전트 기준으로 검증하는 테스트베드**입니다.
