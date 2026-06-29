# insane-search-testbed

공개 웹페이지를 많이 읽어야 할 때 쓰는 AI 리서치 테스트베드입니다.

원본은 [`fivetaku/insane-search`](https://github.com/fivetaku/insane-search)입니다.
이 레포는 그 엔진을 Codex에서 바로 설치하고, 여러 URL에 돌려보고, 어떤 공개 경로가 먹히는지 확인하기 쉽게 만든 작업대입니다.

## 이 레포의 타겟

한두 개 로그인 페이지를 대신 눌러주는 도구가 아닙니다.

이 레포의 타겟은 이쪽입니다.

- 공개 웹페이지를 많이 모아야 할 때
- 여러 사이트를 한 번에 조사해야 할 때
- 일반 fetch가 막히는 공개 페이지를 다시 시도해야 할 때
- YouTube, Naver, X, Reddit, HN, arXiv 같은 공개 출처를 리서치해야 할 때
- AI 에이전트가 “이 페이지 못 읽어요” 하고 멈추는 일을 줄이고 싶을 때

핵심은 **많이**입니다.

공개 URL을 여러 개 넣고, 가능한 공개 경로를 계속 시도해서, 읽을 수 있는 건 읽고 못 읽는 건 왜 못 읽는지 남기는 것이 목적입니다.

## 한 줄로 말하면

공개 웹페이지 대량 리서치를 위해 `API`, `RSS`, `yt-dlp`, `curl_cffi`, `Playwright` 같은 여러 접근 방법을 자동으로 시도하는 테스트베드입니다.

여기서 중요한 말은 **공개**입니다.

로그인해야만 보이는 글, 유료 글, 비공개 계정, DM, 주문내역, 관리자 화면을 우회해서 읽는 도구가 아닙니다.

## 왜 쓰나요?

AI 에이전트로 리서치를 하다 보면 이런 일이 자주 생깁니다.

- URL을 줬는데 `403 Forbidden`이 뜹니다.
- 페이지는 열리지만 본문이 비어 있습니다.
- YouTube 영상인데 설명이나 자막 정보를 못 가져옵니다.
- X나 Reddit은 비로그인 요청을 자주 막습니다.
- Naver 같은 사이트는 그냥 HTTP 요청과 브라우저 요청 결과가 다를 수 있습니다.
- 사이트마다 크롤링 코드를 새로 짜기 귀찮습니다.

insane-search는 여기서 바로 포기하지 않습니다.

먼저 공개 API나 공개 feed를 찾습니다.
그다음 일반 HTML 요청을 해봅니다.
그래도 안 되면 브라우저처럼 보이는 요청을 해봅니다.
필요하면 Playwright로 실제 브라우저 렌더링까지 시도합니다.

## 차별점

일반 `WebFetch`는 보통 한 번 요청하고 끝납니다.

이 레포는 여러 공개 경로를 순서대로 시도합니다.

| 상황 | 보통 fetch | insane-search |
|---|---|---|
| YouTube 영상 | HTML만 보거나 실패 | `yt-dlp`로 공개 메타데이터 확인 |
| X 개별 글 | 로그인/차단 가능성 큼 | oEmbed, tweet-result 같은 공개 경로 확인 |
| Reddit | 403/429 가능성 큼 | RSS 등 공개 feed 먼저 확인 |
| HN/arXiv | 직접 HTML 긁기 | 공개 API 사용 |
| 일반 WAF 페이지 | 실패하면 끝 | TLS fingerprint, 모바일 URL, Playwright fallback 시도 |
| 실패 분석 | 왜 실패했는지 모호함 | `trace`로 어떤 route가 막혔는지 남김 |

차별점은 이겁니다.

> 공개로 열려 있는 다른 길을 많이 찾아본다.

## 설치

PowerShell에서 실행합니다.

```powershell
git clone https://github.com/yeohj0710/insane-search-testbed.git
cd insane-search-testbed
.\scripts\bootstrap.ps1
```

설치되는 것:

- Python venv
- `curl_cffi`
- `beautifulsoup4`
- `PyYAML`
- `yt-dlp`
- Playwright 템플릿용 npm 패키지

## 전체 테스트

```powershell
.\scripts\run-tests.ps1
```

이 테스트는 엔진이 정상인지 확인합니다.

테스트에 포함된 것:

- 내부 regression 테스트
- 안전 테스트
- YouTube 공개 메타데이터 테스트
- Naver 검색 HTML 테스트
- Hacker News 공개 API 테스트
- arXiv 공개 API 테스트
- Playwright 템플릿 테스트

결과는 `test-artifacts` 폴더에 저장됩니다.

## URL 하나만 읽어보기

```powershell
cd skills\insane-search
..\..\.venv\Scripts\python.exe -m engine "https://example.com/" --json
```

YouTube 예시:

```powershell
..\..\.venv\Scripts\python.exe -m engine "https://youtu.be/vjSZIyYd0NI?si=4HCubGogjOOxnfBc" --json
```

Naver 검색 예시:

```powershell
..\..\.venv\Scripts\python.exe -m engine "https://search.naver.com/search.naver?query=claude+code" --json
```

## URL 여러 개 한 번에 돌리기

대량 리서치가 이 레포의 핵심입니다.

먼저 URL 목록을 만듭니다.

```text
# examples/urls.sample.txt
https://youtu.be/vjSZIyYd0NI?si=4HCubGogjOOxnfBc
https://news.ycombinator.com/
https://hn.algolia.com/api/v1/search?query=claude&tags=story&hitsPerPage=3
http://export.arxiv.org/api/query?search_query=all:large+language+model&max_results=3
```

실행합니다.

```powershell
.\scripts\run-url-list.ps1 -UrlsFile .\examples\urls.sample.txt
```

결과는 `test-artifacts\research-run-날짜` 폴더에 저장됩니다.

각 URL마다 아래 파일이 생깁니다.

- `001.stdout.json`
- `001.stderr.txt`
- `002.stdout.json`
- `002.stderr.txt`
- `summary.json`

성공한 URL과 실패한 URL을 나눠서 볼 수 있습니다.

## 결과 읽는 법

`--json` 결과에서 이 값만 보면 됩니다.

```json
{
  "ok": true,
  "verdict": "strong_ok",
  "profile_used": "phase0:youtube",
  "summary": "Phase 0 official route: youtube:yt-dlp",
  "content_length": 591612
}
```

- `ok: true`: 읽기 성공
- `verdict: strong_ok`: 꽤 확실한 성공
- `verdict: weak_ok`: 읽긴 했지만 검증은 약함
- `profile_used`: 어떤 방식이 먹혔는지
- `summary`: 성공/실패 요약
- `trace`: 어떤 시도를 했는지
- `content_length`: 가져온 내용 크기

대량 리서치에서는 `ok`, `profile_used`, `summary`를 먼저 보면 됩니다.

## 실제로 어디까지 됐나요?

이 레포에서 돌려본 결과입니다.

| 사이트 | 결과 | 접근 방식 |
|---|---|---|
| YouTube | 성공 | `yt-dlp`로 공개 메타데이터 수집 |
| Naver 검색 | 제한적 | HTML 200은 받을 수 있지만 engine 검증에서 challenge로 볼 수 있음 |
| Hacker News | 성공 | Firebase API, Algolia API |
| arXiv | 성공 | Atom API |
| X 개별 글 | 성공 | tweet-result, oEmbed 공개 endpoint |
| X timeline | 제한적 | 429 rate limit 발생 |
| Reddit | 불안정 | RSS는 성공할 때도 있지만 429/403 가능 |
| LinkedIn | 실패 | 테스트 URL이 404, 로그인 우회 없음 |
| example.com | 성공 | 기본 연결 확인 |

여기서 “성공”은 이런 뜻입니다.

> 사이트가 공개로 열어둔 경로를 통해 데이터를 읽었다.

해킹이나 로그인 우회가 아닙니다.

## 예시로 보면 더 쉽습니다

### YouTube

브라우저 HTML을 직접 긁는 대신 `yt-dlp`를 먼저 씁니다.

얻을 수 있는 것:

- 제목
- 설명
- 채널 정보
- 공개 자막 후보
- 공개 메타데이터

대량으로 영상 URL을 넣으면 영상 리서치에 쓸 수 있습니다.

### Naver 검색

일반 요청이 막히거나 빈약할 수 있어서 `curl_cffi`로 브라우저에 가까운 요청을 시도합니다.

얻을 수 있는 것:

- 검색 HTML
- 공개 검색 결과 구조
- 검색 페이지에서 보이는 공개 텍스트

주의할 점:

- HTML은 200으로 받아도 내부에 `captcha` 같은 문자열이 있으면 engine이 실패로 볼 수 있습니다.
- 즉, Naver는 “항상 성공”이 아니라 “공개 HTML을 받을 수는 있지만 검증이 까다로운 쪽”입니다.

스마트스토어 판매자센터처럼 로그인 필요한 화면은 대상이 아닙니다.

### X

timeline 전체는 rate limit에 걸릴 수 있습니다.

하지만 개별 글은 공개 endpoint가 열려 있으면 읽을 수 있습니다.

얻을 수 있는 것:

- 공개 tweet 텍스트
- oEmbed HTML
- 일부 공개 메타데이터

로그인 전용 피드, DM, 비공개 계정은 대상이 아닙니다.

### Reddit

RSS가 열려 있으면 읽을 수 있습니다.

하지만 rate limit이 자주 발생합니다.

그래서 Reddit은 “항상 된다”가 아니라 “공개 feed가 살아 있으면 된다”에 가깝습니다.

## 잘 맞는 사용처

이런 작업에 잘 맞습니다.

- 공개 웹페이지 수십 개를 한 번에 조사
- 여러 출처에서 공개 텍스트 수집
- YouTube 영상 목록 메타데이터 수집
- 공개 검색 결과 리서치
- 공개 API/RSS가 있는 사이트 조사
- AI 에이전트가 읽을 수 있는 URL인지 사전 검증
- 사이트별 차단 원인 확인

예를 들어 이런 식입니다.

1. 리서치할 URL을 `urls.txt`에 모읍니다.
2. `run-url-list.ps1`로 한 번에 돌립니다.
3. `summary.json`에서 성공/실패를 봅니다.
4. 성공한 JSON만 AI에게 넘겨 요약합니다.

## 잘 안 맞는 사용처

이런 작업에는 맞지 않습니다.

- 인스타 로그인 화면 읽기
- 네이버 스마트스토어 판매자센터 읽기
- 주문내역, 정산, 매출, 관리자 데이터 수집
- DM, 메일, 비공개 게시글 읽기
- paywall 우회
- 로그인 세션으로 화면을 대신 클릭하는 업무 자동화

이런 작업은 `@chrome` 같은 브라우저 자동화가 더 맞습니다.
공식 API가 있으면 공식 API가 더 안정적입니다.

## Codex에서는 어떻게 보나요?

원본은 Claude Code 플러그인입니다.

Codex에서는 플러그인처럼 바로 붙인 게 아니라, Python engine을 직접 실행하는 방식으로 검증했습니다.

현재 상태:

- Claude Code: 플러그인 형태로 사용 가능
- Codex: 이 레포에서 engine 직접 실행 가능
- Codex wrapper/skill: 별도 작업 필요

## 파일 구조

```text
scripts/bootstrap.ps1          처음 설치
scripts/run-tests.ps1          전체 테스트
scripts/run-url-list.ps1       URL 여러 개 대량 실행
examples/urls.sample.txt       샘플 URL 목록
requirements-test.txt          Python 의존성
skills/insane-search/engine    실제 fetch 엔진
skills/insane-search/tests     live route 테스트
test-artifacts                 테스트 결과
```

## 빠른 시작

처음이면 이것만 실행합니다.

```powershell
git clone https://github.com/yeohj0710/insane-search-testbed.git
cd insane-search-testbed
.\scripts\bootstrap.ps1
.\scripts\run-tests.ps1
```

대량 리서치를 바로 해보려면:

```powershell
.\scripts\run-url-list.ps1 -UrlsFile .\examples\urls.sample.txt
```

내 URL 목록을 쓰려면:

```powershell
.\scripts\run-url-list.ps1 -UrlsFile .\my-urls.txt
```

## 결론

이 레포는 로그인 페이지 자동화 도구가 아닙니다.

이 레포는 **공개 웹 대량 리서치용 fallback 테스트베드**입니다.

한 번 요청하고 막히면 끝나는 방식이 아니라, 공개로 열려 있는 다른 길을 계속 찾아봅니다.

그래서 YouTube, Hacker News, arXiv처럼 공개 경로가 명확한 곳에 강합니다.
Naver 검색처럼 HTML은 받아도 검증이 애매한 곳은 결과를 확인하면서 써야 합니다.
X나 Reddit처럼 rate limit이 강한 곳은 일부만 됩니다.
로그인해야 하는 곳은 안 됩니다.

가장 잘 맞는 말은 이겁니다.

> AI 에이전트가 공개 웹을 많이 읽어야 할 때, 어디까지 자동으로 읽을 수 있는지 검증하는 레포.
