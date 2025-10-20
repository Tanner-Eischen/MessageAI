# Phase 05 — Storage & Groups

## Summary

This phase adds two key features:
1. **Media Storage** - Supabase Storage buckets for user avatars and message media
2. **Group Creation** - Optional Edge Function for creating group conversations with multiple members

## Storage Buckets

### Overview

Supabase Storage provides cloud file storage with fine-grained access control. MessageAI uses two buckets:
- **avatars** - User profile pictures
- **media** - Message attachments (images, videos, documents)

### Bucket 1: avatars

**Purpose:** Store user profile pictures

**Features:**
- Public access via signed URLs
- User-namespaced folder structure: `avatars/{user_id}/{filename}`
- Users can only upload/edit their own avatars
- File size: Limited by Supabase (default 5GB)

**Policies:**
- ✅ **INSERT:** Users can upload avatars to their folder
- ✅ **SELECT:** All authenticated users can view avatars
- ✅ **UPDATE:** Users can update their own avatars
- ✅ **DELETE:** Users can delete their own avatars

**Usage Example:**
```dart
// Upload avatar
final file = File('path/to/avatar.jpg');
await supabase.storage
  .from('avatars')
  .upload('${userId}/profile.jpg', file);

// Get signed URL (1 hour expiry)
final url = supabase.storage
  .from('avatars')
  .getPublicUrl('${userId}/profile.jpg');

// With signed URL for expiring access:
final signedUrl = supabase.storage
  .from('avatars')
  .createSignedUrl('${userId}/profile.jpg', 3600); // 1 hour
```

### Bucket 2: media

**Purpose:** Store message attachments (images, videos, documents)

**Features:**
- Public access via signed URLs
- User-namespaced folder structure: `media/{user_id}/{filename}`
- Users can only upload/delete their own media
- Typically linked from messages via `media_url`

**Policies:**
- ✅ **INSERT:** Users can upload media to their folder
- ✅ **SELECT:** All authenticated users can view media
- ✅ **DELETE:** Users can delete their own media

**Usage Example:**
```dart
// Upload media attachment
final file = File('path/to/image.jpg');
final path = await supabase.storage
  .from('media')
  .upload('${userId}/${messageId}_image.jpg', file);

// Get signed URL with expiry
final signedUrl = supabase.storage
  .from('media')
  .createSignedUrl('${userId}/${messageId}_image.jpg', 3600);

// Send message with media
await supabase.functions.invoke('messages_send', body: {
  'id': messageId,
  'conversation_id': conversationId,
  'body': 'Check this out!',
  'media_url': signedUrl, // Use signed URL for security
});
```

### Security Model

**Folder Structure Enforcement:**
- Bucket policies use `storage.foldername()` to extract user ID from path
- Files must be in user's folder: `bucket/{user_id}/...`
- Prevents users from accessing other users' private files

**Signed URLs:**
- All URLs should be signed with expiration (1 hour recommended)
- Prevents direct access without permission
- Expiration enforces security boundary

**Access Control:**
- Storage policies use `auth.uid()` for user context
- Only authenticated users can access buckets
- Policies apply at file level

### File Structure

```
backend/supabase/
└── storage/
    └── buckets.sql          # Bucket definitions and policies
```

## Group Creation Edge Function

### Overview

The optional `create_group` function allows authenticated users to create group conversations with multiple members.

**Endpoint:** `POST /v1/create_group`

### Request Format

```json
{
  "title": "Project Team",
  "description": "Main project discussion group",
  "member_ids": [
    "user-uuid-1",
    "user-uuid-2",
    "user-uuid-3"
  ]
}
```

**Fields:**
- `title` (string, required) - Group name (1-255 characters)
- `description` (string, optional) - Group description
- `member_ids` (array, required) - User UUIDs to add (1-500 members)

### Response Format

```json
{
  "id": "conv-uuid",
  "title": "Project Team",
  "description": "Main project discussion group",
  "is_group": true,
  "created_by": "user-uuid-creator",
  "created_at": "2025-10-20T15:30:00.000Z",
  "member_count": 3,
  "members": [
    {
      "user_id": "user-uuid-1",
      "joined_at": "2025-10-20T15:30:00.000Z"
    },
    {
      "user_id": "user-uuid-2",
      "joined_at": "2025-10-20T15:30:00.000Z"
    },
    {
      "user_id": "user-uuid-3",
      "joined_at": "2025-10-20T15:30:00.000Z"
    }
  ]
}
```

### Features

✅ **Automatic Deduplication:** Creator is automatically included (only once)  
✅ **Member Validation:** All users must exist in profiles table  
✅ **Size Limits:** Maximum 500 members per group  
✅ **Error Handling:** Clear validation errors  
✅ **Batch Operations:** Creates conversation and all participant records atomically  

### Error Responses

| Status | Error | Cause |
|--------|-------|-------|
| 400 | Missing required fields | title or member_ids missing |
| 400 | Group title cannot be empty | Title is empty after trim |
| 400 | Group title too long | Title > 255 characters |
| 400 | member_ids must be non-empty array | member_ids is empty |
| 400 | Too many members | > 500 members in group |
| 400 | Invalid member IDs | One or more members don't exist |
| 401 | Invalid token | Missing or expired auth |
| 500 | Failed to validate members | Database error |
| 500 | Failed to create group | Conversation creation failed |

### Security

**Authentication:** Bearer token required in Authorization header

**Validation:**
- Title length checked (1-255 characters)
- Member array size checked (1-500)
- All members validated against profiles table

**Authorization:**
- Creator is automatically added (always included)
- Function uses authenticated user's ID
- RLS policies enforce conversation access

### Usage Example (Dart)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

// Create a group
final response = await supabase.functions.invoke(
  'create_group',
  body: {
    'title': 'Team Meeting',
    'description': 'Weekly standup',
    'member_ids': [
      'uuid-1',
      'uuid-2',
      'uuid-3',
    ],
  },
);

// Handle response
if (response.status == 200) {
  final groupData = response.data;
  print('Created group: ${groupData['id']}');
  print('Members: ${groupData['member_count']}');
} else {
  print('Error: ${response.data['error']}');
}
```

## Deployment

### 1. Add Storage Configuration

Storage buckets are typically created via Supabase Dashboard or Migration:

```bash
# Run migration (adds buckets and policies)
make db/migrate
```

### 2. Verify Buckets

```bash
# Connect to Supabase
supabase status

# Check buckets in dashboard:
# Navigate to Storage tab
# Should see: avatars and media buckets
```

### 3. Deploy Function

```bash
cd backend

# Start function dev server
make funcs/dev

# Function available at:
# http://localhost:54321/functions/v1/create_group
```

### 4. Test Function

```bash
# Create a group
curl -X POST http://localhost:54321/functions/v1/create_group \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Group",
    "member_ids": ["user-uuid-1", "user-uuid-2"]
  }'
```

## Integration with Frontend

### Upload User Avatar

```dart
// After user signs up, upload profile picture
Future<void> uploadAvatar(String userId, File imageFile) async {
  try {
    // Upload to Storage
    await supabase.storage
      .from('avatars')
      .upload('$userId/profile.jpg', imageFile);
    
    // Get signed URL
    final signedUrl = await supabase.storage
      .from('avatars')
      .createSignedUrl('$userId/profile.jpg', 3600);
    
    // Update profile with avatar URL
    await supabase
      .from('profiles')
      .update({'avatar_url': signedUrl})
      .eq('user_id', userId);
  } catch (e) {
    print('Error uploading avatar: $e');
  }
}
```

### Send Message with Media

```dart
// When user sends message with media attachment
Future<void> sendMessageWithMedia(
  String conversationId,
  String messageBody,
  File mediaFile,
) async {
  final user = supabase.auth.currentUser!;
  final messageId = const Uuid().v4();
  
  try {
    // Upload media
    final mediaPath = '${user.id}/${messageId}_attachment';
    await supabase.storage
      .from('media')
      .upload(mediaPath, mediaFile);
    
    // Get signed URL
    final mediaUrl = await supabase.storage
      .from('media')
      .createSignedUrl(mediaPath, 3600);
    
    // Send message
    await supabase.functions.invoke('messages_send', body: {
      'id': messageId,
      'conversation_id': conversationId,
      'body': messageBody,
      'media_url': mediaUrl,
    });
  } catch (e) {
    print('Error sending message with media: $e');
  }
}
```

### Create Group

```dart
Future<void> createNewGroup(
  String title,
  List<String> memberIds,
) async {
  try {
    final response = await supabase.functions.invoke(
      'create_group',
      body: {
        'title': title,
        'member_ids': memberIds,
      },
    );
    
    if (response.status == 200) {
      final groupId = response.data['id'];
      print('Group created: $groupId');
      // Navigate to new group
    } else {
      final error = response.data['error'];
      print('Error: $error');
    }
  } catch (e) {
    print('Error creating group: $e');
  }
}
```

## File Naming Conventions

### Avatars
```
avatars/{user_id}/profile.jpg
avatars/{user_id}/avatar.png
```

### Media
```
media/{user_id}/{message_id}_image.jpg
media/{user_id}/{message_id}_video.mp4
media/{user_id}/{message_id}_document.pdf
```

**Benefits:**
- User isolation (each user has own folder)
- Message association (files linked by message ID)
- Easy cleanup (delete by user or message)

## Troubleshooting

### Storage Upload Fails

- Verify user is authenticated
- Check bucket policies exist
- Ensure file path includes user ID folder
- Check file size doesn't exceed limit

### Create Group Returns "Invalid member IDs"

- Verify all member user_ids exist in profiles table
- Check user_ids are valid UUIDs
- Ensure members have completed signup

### Signed URL Expires Too Quickly

- Increase URL expiration time (default 3600 = 1 hour)
- Generate new URL when needed
- Consider caching URLs temporarily (with expiry tracking)

## Next Steps

→ **Phase 06: Push Notifications** - Add device registration and push notification support

## Completion Checklist

- [x] Avatars bucket created with policies
- [x] Media bucket created with policies
- [x] Storage buckets configuration validated
- [x] create_group function implemented
- [x] Input validation complete
- [x] Error handling implemented
- [x] Documentation complete
- [ ] Deployed to Supabase
- [ ] Frontend integration tested
- [ ] File upload tested with real media

## Code Statistics

| Component | Lines | Purpose |
|-----------|-------|---------|
| buckets.sql | 95 | Storage buckets + policies |
| create_group/index.ts | 160 | Group creation function |
| Documentation | 400+ | Setup and usage guides |
| **Total** | **655+** | Phase 05 implementation |
