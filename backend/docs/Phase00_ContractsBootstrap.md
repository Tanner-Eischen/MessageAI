# Phase 00 — Contracts Bootstrap (Shared, owned by Backend)

**Branch:** `feat/contracts-bootstrap`  
**PR:** `[B] Phase 00 — Contracts bootstrap (OpenAPI + Events + Scripts)`

## Summary
Initialize `/contracts` as the source of truth and generate a stub Dart client.

## Tasks
- [ ] Create directories:
  - [ ] `contracts/`
  - [ ] `contracts/events/`
  - [ ] `contracts/scripts/`
- [ ] Create files:
  - [ ] `contracts/openapi.yaml`
  - [ ] `contracts/events/message_inserted.schema.json`
  - [ ] `contracts/events/receipt_inserted.schema.json`
  - [ ] `contracts/package.json`
  - [ ] `contracts/scripts/generate_dart.sh`
- [ ] Add minimal endpoints:
  - [ ] `POST /v1/messages.send`
  - [ ] `POST /v1/receipts.ack`
- [ ] Validate & generate:
  - [ ] `npm --prefix contracts run validate`
  - [ ] `npm --prefix contracts run gen:dart` → writes to `/frontend/lib/gen/api/`

## Files (templates)

**contracts/openapi.yaml (stub)**
```yaml
openapi: 3.1.0
info: { title: MessageAI API, version: 0.1.0 }
paths:
  /v1/messages.send:
    post:
      requestBody:
        content:
          application/json:
            schema: { $ref: '#/components/schemas/MessagePayload' }
      responses: { '200': { description: OK } }
  /v1/receipts.ack:
    post:
      requestBody:
        content:
          application/json:
            schema: { $ref: '#/components/schemas/ReceiptPayload' }
      responses: { '200': { description: OK } }
components:
  schemas:
    MessagePayload:
      type: object
      properties: { id: {type: string}, conversation_id: {type: string}, body: {type: string} }
      required: [id, conversation_id]
    ReceiptPayload:
      type: object
      properties: { message_ids: {type: array, items: {type: string}}, status: {type: string, enum: [delivered, read]} }
      required: [message_ids, status]
```

**contracts/events/message_inserted.schema.json**
```json
{ "$id": "message_inserted.schema.json", "type": "object",
  "properties": { "id": {"type":"string"}, "conversation_id": {"type":"string"}, "sender_id":{"type":"string"}, "body":{"type":"string"}, "created_at":{"type":"string","format":"date-time"} },
  "required": ["id","conversation_id","sender_id","created_at"] }
```

**contracts/events/receipt_inserted.schema.json**
```json
{ "$id": "receipt_inserted.schema.json", "type": "object",
  "properties": { "message_id":{"type":"string"}, "user_id":{"type":"string"}, "status":{"type":"string","enum":["delivered","read"]}, "at":{"type":"string","format":"date-time"} },
  "required": ["message_id","user_id","status","at"] }
```

**contracts/package.json**
```json
{
  "scripts": {
    "validate": "openapi-generator-cli validate -i openapi.yaml && ajv -s events/*.json",
    "gen:dart": "openapi-generator-cli generate -g dart-dio -i openapi.yaml -o ../frontend/lib/gen/api --additional-properties=pubName=message_ai_client"
  },
  "devDependencies": {
    "@openapitools/openapi-generator-cli": "^2.9.0",
    "ajv-cli": "^5.0.0"
  }
}
```

**contracts/scripts/generate_dart.sh**
```bash
#!/usr/bin/env bash
set -e
npm --prefix contracts run validate
npm --prefix contracts run gen:dart
echo "Generated Dart client to /frontend/lib/gen/api"
```

## Testing
- [ ] `npm --prefix contracts run validate` passes

## Completion
- Contracts folder validates; initial client generation possible.
