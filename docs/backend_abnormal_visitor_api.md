# [백엔드 요청] 아이폰 비정상 방문객 — 목록 조회 / 다중 삭제 API

관리자 대시보드의 **"아이폰 비정상 방문객 수"** 카드를 클릭하면, 비정상 방문객 **명단을 다이얼로그로 보여주고 체크박스로 여러 명을 선택해 한 번에 삭제**하는 기능을 추가합니다.
현재는 **카운트 API만** 있고(`GET /visitor/count/today/abnormal`), **목록 조회**와 **삭제** API가 없어 아래 2개 엔드포인트가 필요합니다.

- 비정상 방문객 = `visitor.type == "ABNORMAL"` (프론트 표기: "비정상 사용")
- 기존 방문객 응답/규약을 그대로 따릅니다.

---

## 공통 규약 (기존과 동일)

- Base URL: `https://gateon.co.kr:28008`
- 인증 헤더: `X-AUTH-TOKEN-ACCESS: {accessToken}` (관리자 access token)
- 권한: 요청한 **관리자 소속 업체(enterprise)의 방문객만** 대상 (기존 방문객 조회와 동일 스코프)
- 공통 응답 봉투:
  ```json
  { "statusCode": 200, "message": "SUCCESS", "data": { ... } }
  ```
- 리스트 응답은 `data.items` + `data.meta` 구조 (기존 `GET /visitor`와 동일)

---

## 1) 비정상 방문객 목록 조회

기존 `GET /visitor/count/today/abnormal`(카운트)와 짝이 되는 **목록** 버전입니다.

| 항목 | 값 |
|---|---|
| Method | `GET` |
| Path | `/visitor/today/abnormal` |
| Query | `page`(선택, 기본 1), `size`(선택, 기본 전체) |
| Header | `X-AUTH-TOKEN-ACCESS: {accessToken}` |

- 범위: **오늘(당일)**, `type == "ABNORMAL"` 인 방문객
- `page`/`size` 미전달 시 오늘치 전체 반환 허용 (다이얼로그는 기본적으로 전체를 한 번에 표시)

### 응답 예시 (기존 방문객 item 필드와 동일)
```json
{
  "statusCode": 200,
  "message": "SUCCESS",
  "data": {
    "items": [
      {
        "id": 1234,
        "disabledAt": "2026-08-31T00:12:00Z",
        "enabledAt": "2026-08-31T00:30:00Z",
        "deviceId": "A1B2C3D4",
        "deviceModel": "iPhone15,2",
        "osType": "APPLE",
        "osVersion": "18.1",
        "appVersion": "1.3.1",
        "isActive": false,
        "type": "ABNORMAL",
        "profileType": "DISABLE"
      }
    ],
    "meta": { "totalPages": 1, "totalCount": 1, "sizePerPage": 10, "currentPage": 1 }
  }
}
```

> item 스키마는 기존 `GET /visitor` 의 User 와 동일하게 주시면 됩니다. `id` 는 삭제 API에서 사용합니다.

---

## 2) 방문객 다중 삭제 (bulk delete)

체크박스로 선택한 여러 방문객을 **id 배열로 한 번에** 삭제합니다.

| 항목 | 값 |
|---|---|
| Method | `DELETE` |
| Path | `/visitor` |
| Header | `X-AUTH-TOKEN-ACCESS: {accessToken}`, `Content-Type: application/json` |
| Body | `{ "ids": [1234, 1235, 1236] }` |

### 응답 예시 (삭제된 건수를 data로)
```json
{ "statusCode": 200, "message": "SUCCESS", "data": 3 }
```

- `data` = 실제 삭제된 건수(int). 프론트는 성공 여부만 확인하고 목록을 새로고침합니다.
- 요청 id 중 **일부가 이미 없거나 권한 밖**이면: 가능한 것만 삭제하고 삭제 건수를 반환(부분 성공 허용). 전체 실패 정책을 원하시면 알려주세요.

> 참고: 프론트 HTTP 클라이언트는 DELETE 요청에 **body 전송을 지원**합니다. 만약 서버 프레임워크에서 DELETE + body가 불편하면 `POST /visitor/delete` (동일 body)로 바꿔주셔도 됩니다. 최종 채택 경로만 알려주세요.

---

## 확인이 필요한 결정 사항

1. **삭제 의미(중요)**: 이 삭제가 방문 기록을 **DB에서 완전 삭제(hard delete)** 인가요, 아니면 **숨김/비활성 처리(soft delete)** 인가요?
   - 완전 삭제라면 **누적 방문객 수 / 차단 방문객 수 등 다른 통계에도 영향**을 주는지 확인 필요.
   - 대시보드의 "비정상 방문객 수"(`count/today/abnormal`)는 삭제 후 **즉시 감소하도록** 반영되어야 합니다.
2. **삭제 범위 재확인**: 관리자는 **자기 업체 방문객만** 삭제 가능해야 합니다(타 업체 id는 무시/거부).
3. **목록 범위**: 카운트와 동일하게 "오늘"만인가요, 아니면 전체 기간 비정상 목록도 필요하신가요? (현재 요청은 카운트와 맞춰 "오늘" 기준)
4. **경로/메서드**: 위 제안(`GET /visitor/today/abnormal`, `DELETE /visitor`)으로 진행할지, 다른 네이밍을 쓸지.

프론트는 위 계약 그대로 구현해 두겠습니다. 경로/필드가 바뀌면 repository 한두 줄만 수정하면 됩니다.
