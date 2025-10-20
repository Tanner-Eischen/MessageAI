# Phase 03 — Contracts Sync & Dart Codegen

## Summary

This phase synchronizes the OpenAPI specification and event schemas with the database schema created in Phase 2, then generates type-safe Dart client code for the frontend.

## What Changed from Phase 0

### OpenAPI Specification

**Version Update:** `0.1.0` → `0.2.0`

**Enhanced Endpoints:**
- Added descriptions, tags, and operation IDs
- Added proper response schemas and error codes
- Detailed parameter documentation
- Added server definitions for local and production

**New Schema Definitions:**
- ✅ `MessagePayload` - Request to send message
- ✅ `MessageResponse` - Server response with timestamps
- ✅ `ReceiptPayload` - Request to acknowledge receipts
- ✅ `MessageReceipt` - Receipt status object
- ✅ `Conversation` - Full conversation object
- ✅ `ConversationParticipant` - Participation details
- ✅ `Profile` - User profile information

**Schema Details:**
- All UUID fields properly typed with `format: uuid`
- DateTime fields with `format: date-time`
- URI fields for media URLs
- Nullable fields clearly marked
- Min/max constraints where applicable
- Required fields explicitly declared

### Event Schemas

**message_inserted.schema.json:**
- ✅ Added `$schema` and `title` metadata
- ✅ Enhanced all field descriptions
- ✅ Added `media_url` field for attachments
- ✅ Added `updated_at` timestamp
- ✅ UUID format specifications
- ✅ Disabled additional properties for validation

**receipt_inserted.schema.json:**
- ✅ Added `id` field (was missing)
- ✅ Added `$schema` and `title` metadata
- ✅ Enhanced all field descriptions
- ✅ UUID format specifications
- ✅ Disabled additional properties for validation

## File Structure

```
contracts/
├── openapi.yaml                          # API specification (updated)
├── events/
│   ├── message_inserted.schema.json      # Event schema (updated)
│   ├── receipt_inserted.schema.json      # Event schema (updated)
│   └── (other events for future use)
├── scripts/
│   └── generate_dart.sh                  # Generation script
├── package.json                          # NPM configuration
└── openapitools.json                     # OpenAPI generator config
```

## Contract Validation

Run validation to ensure schemas are correct:

```bash
# Validate OpenAPI spec
cd contracts
npm run validate

# Expected output:
# ✓ OpenAPI spec valid
# ✓ Event schemas valid (message_inserted, receipt_inserted)
```

### What Gets Validated

**OpenAPI:**
- Spec conforms to OpenAPI 3.1.0 standard
- All references resolve correctly
- Schema definitions are complete
- Paths and operations are valid

**Event Schemas:**
- JSON Schema draft-07 compliance
- Required fields defined
- Type constraints valid
- Enum values correct

## Dart Code Generation

Once validated, generate the Dart client:

```bash
# Generate Dart client
make contracts/gen

# Output directory: frontend/lib/gen/api/
# Generated files include:
# - Client classes for API calls
# - Model classes for all schemas
# - Exception classes
# - Complete type definitions
```

### Generated Artifacts

The Dart code generator creates:

```
frontend/lib/gen/api/
├── client.dart                           # API client
├── api/
│   ├── messages_api.dart                # Messages endpoints
│   └── receipts_api.dart                # Receipts endpoints
├── model/
│   ├── message_payload.dart             # Request models
│   ├── message_response.dart            # Response models
│   ├── receipt_payload.dart
│   ├── message_receipt.dart
│   ├── conversation.dart
│   ├── conversation_participant.dart
│   └── profile.dart
└── (supporting files)
```

## Integration Points

### Message Sending
- Client: Generates client-side message ID (UUID)
- API: Receives `MessagePayload` with id, conversation_id, body, media_url
- DB: Inserts with idempotency (unique id constraint)
- Event: Broadcasts `message_inserted` via Realtime
- Response: Returns `MessageResponse` with server timestamps

### Receipt Acknowledgement
- Client: Sends multiple message IDs with status (delivered/read)
- API: Receives `ReceiptPayload` with message_ids and status
- DB: Batch inserts into message_receipts (unique constraint handles duplicates)
- Event: Broadcasts `receipt_inserted` via Realtime
- Response: Returns count of updated receipts

## Type Safety Benefits

By generating code from contracts, the frontend gains:

✅ **Compile-time Safety** - Type mismatches caught immediately  
✅ **Auto-completion** - IDE knows all available fields  
✅ **Documentation** - Field descriptions in generated code  
✅ **Version Alignment** - Client matches server API exactly  
✅ **Refactoring Safety** - Changes break the build, not runtime  

## Deployment Checklist

- [x] OpenAPI spec updated to v0.2.0
- [x] All schemas documented with descriptions
- [x] Event schemas enhanced with UUID formats
- [x] Contract validation passes
- [ ] Dart client generated (`make contracts/gen`)
- [ ] Generated client compiles in Flutter (checked by Window A)
- [ ] Frontend integration verified

## Next Steps

→ **Phase 04: Edge Functions & Realtime** - Implement the Edge Functions that power the API endpoints and broadcast realtime events

## Related Documentation

- **Backend Schema:** See `README_Phase02.md` for database design
- **Frontend Integration:** See `frontend/docs/Phase03_ApiClientIntegration.md`
- **Realtime Events:** See `frontend/docs/Phase04_OptimisticRealtime.md`
