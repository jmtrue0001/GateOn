# [백엔드 요청] 아이폰 비정상 방문객 — 해제(담당자·사유 기록) API

관리자 대시보드 "아이폰 비정상 방문객" 다이얼로그에서, 선택한 방문객의 **비정상(ABNORMAL) 상태를 해제**하는 기능입니다.
삭제가 아니라 **상태만 해제**하며, **건별로 담당자·사유를 함께 기록**합니다. (감사 이력용)

---

## 1) 비정상 해제 API (담당자·사유 기록)

| 항목 | 값 |
|---|---|
| Method | `PATCH` |
| Path | `/visitor/abnormal` |
| Header | `X-AUTH-TOKEN-ACCESS: {accessToken}`, `Content-Type: application/json` |

### 요청 Body
건별로 담당자·사유가 다를 수 있어 **items 배열**로 전송합니다.
```json
{
  "items": [
    { "id": 1234, "manager": "홍길동", "reason": "관리자 확인 후 정상 처리" },
    { "id": 1235, "manager": "김철수", "reason": "오탐으로 확인" }
  ]
}
```

| 필드 | 타입 | 제약 | 설명 |
|---|---|---|---|
| `items[].id` | int | 필수 | 방문객 id |
| `items[].manager` | string | 필수, **최대 10자** | 담당자 |
| `items[].reason` | string | 필수, **최대 40자** | 해제 사유 |

### 응답 (공통 봉투)
```json
{ "statusCode": 200, "message": "success", "data": 2 }
```
- `data`(int) = 처리된 건수

### 서버 처리 요구사항
1. **상태 해제**: 각 id의 비정상 상태 해제 (레코드는 삭제하지 않음, `isActive`/상태값 정상화).
2. **담당자·사유 저장(중요)**: 각 방문객에 **manager·reason을 영속 저장**. 나중에 방문객 상세조회에서 다시 내려줘야 함(아래 3번).
3. **실시간 해제(SSE)**: 각 id에 대해 기존 `unban` 이벤트 발송 로직 유지 (앱 자동 복귀).
4. **통계 반영**: "오늘 비정상 수"(`count/today/abnormal`)는 감소. 삭제가 아니므로 누적/차단 등 다른 통계는 유지.
5. **목록 반영**: 해제한 방문객은 `GET /visitor/today/abnormal` 목록에서 제외.
6. **스코프**: 요청 관리자 소속 업체의 방문객만 처리 (타 업체 id 무시/거부).
7. **필수 검증**: manager/reason 빈 값이면 400 (프론트 1차 검증하지만 서버 방어). 길이(10/40) 초과도 400 권장.
8. **부분 실패 정책**: 일부 id가 잘못돼도 나머지 처리 후 건수 반환할지, 전체 롤백할지 **정해서 알려주세요.**

---

## 2) 비정상 목록 조회 (기존 — 참고)

```
GET /visitor/today/abnormal
Header: X-AUTH-TOKEN-ACCESS: {accessToken}
```
- 오늘 `type == "ABNORMAL"` 방문객 목록. 응답은 기존 `GET /visitor` item 스키마(`data.items` + `data.meta`).

---

## 3) 방문객 상세조회에 담당자·사유 추가 (신규 요청)

방문객 리스트 → **방문객 상세정보** 화면에서, 해당 방문객이 해제된 경우 **입력했던 담당자·사유를 표시**해야 합니다.
→ **방문객 상세조회 응답(User)에 아래 두 필드를 추가**해 주세요.

대상 API (기존): `GET /visitor/{id}` (상세조회)

### 응답 item에 추가할 필드
```json
{
  "id": 1234,
  "deviceId": "f9c5fe52-...",
  "deviceModel": "iPhone15,2",
  "osType": "APPLE",
  "osVersion": "iOS 26.5",
  "appVersion": "1.3.1",
  "disabledAt": "...",
  "enabledAt": "...",
  "isActive": true,
  "type": "...",
  "profileType": "...",

  "releaseManager": "홍길동",              // ← 추가: 비정상 해제 담당자 (해제 이력 없으면 null)
  "releaseReason": "관리자 확인 후 정상 처리"  // ← 추가: 비정상 해제 사유 (없으면 null)
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `releaseManager` | string \| null | 비정상 해제 시 기록된 담당자. 해제 이력 없으면 null |
| `releaseReason` | string \| null | 비정상 해제 시 기록된 사유. 없으면 null |

> 필드명(`releaseManager`/`releaseReason`)은 제안값입니다. 백엔드 선호명이 있으면 알려주세요 — 프론트 모델을 맞추겠습니다.
> 만약 한 방문객이 여러 번 비정상→해제될 수 있고 이력이 여러 건이면, **최근 1건**을 내려줄지 / 이력 전체를 배열로 줄지도 정해주세요. (기본은 최근 1건)

---

## 확인 요약 (백엔드 회신 바랍니다)
1. `PATCH /visitor/abnormal` 요청 형식을 **`{"items":[{id,manager,reason}]}`** 로 받는 것 확정?
2. manager 10자 / reason 40자 제약 — DB 컬럼 길이 맞는지?
3. 상세조회(`GET /visitor/{id}`)에 **releaseManager/releaseReason** 추가 가능한지, 필드명은?
4. 부분 실패 정책 / 해제 이력이 여러 건일 때 반환 방식.
