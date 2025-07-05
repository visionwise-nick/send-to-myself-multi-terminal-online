# Send To Myself - 订阅服务API接口文档

## 概述

本文档定义了Send To Myself应用的订阅服务API接口，用于处理用户订阅、购买验证、状态同步和群组限制等功能。

## 基础信息

- **基础URL**: `https://api.sendtomyself.com/v1`
- **协议**: HTTPS
- **数据格式**: JSON
- **字符编码**: UTF-8
- **认证方式**: JWT Token

## 通用规范

### 请求头
```http
Content-Type: application/json
Authorization: Bearer <jwt_token>
User-Agent: SendToMyself/1.0.0 (Platform/Version)
```

### 响应格式
```json
{
  "success": true,
  "code": 200,
  "message": "Success",
  "data": {},
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 错误响应格式
```json
{
  "success": false,
  "code": 400,
  "message": "Bad Request",
  "error": "详细错误信息",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 状态码定义
- `200`: 请求成功
- `201`: 创建成功
- `400`: 请求参数错误
- `401`: 未授权
- `403`: 禁止访问
- `404`: 资源不存在
- `409`: 资源冲突
- `429`: 请求过于频繁
- `500`: 服务器内部错误

## 数据结构定义

### 订阅计划枚举
```typescript
enum SubscriptionPlan {
  FREE = "free",
  BASIC = "basic", 
  PRO = "pro",
  ENTERPRISE = "enterprise"
}
```

### 订阅状态枚举
```typescript
enum SubscriptionStatus {
  ACTIVE = "active",
  EXPIRED = "expired",
  CANCELLED = "cancelled",
  PENDING = "pending",
  NONE = "none"
}
```

### 平台枚举
```typescript
enum Platform {
  IOS = "ios",
  ANDROID = "android"
}
```

### 设备订阅信息
```typescript
interface DeviceSubscription {
  id: string;
  deviceId: string;
  plan: SubscriptionPlan;
  status: SubscriptionStatus;
  platform: Platform;
  transactionId: string;
  originalTransactionId?: string;
  productId: string;
  purchaseDate: string;
  expiresDate?: string;
  isTrialPeriod: boolean;
  isIntroductoryPricePeriod: boolean;
  createdAt: string;
  updatedAt: string;
}
```

### 购买验证数据
```typescript
interface PurchaseVerification {
  platform: Platform;
  receipt: string;
  deviceId: string;
  productId: string;
  transactionId: string;
}
```

### 群组限制检查数据
```typescript
interface GroupLimitCheck {
  groupId: string;
  action: 'join' | 'invite';
  targetDeviceId?: string;
}
```

### 群组统计信息
```typescript
interface GroupStats {
  groupId: string;
  memberCount: number;
  maxMembers: number;
  ownerDevice: {
    id: string;
    name: string;
    subscription: DeviceSubscription;
  };
  devices: Array<{
    id: string;
    name: string;
    isOnline: boolean;
    isOwner: boolean;
  }>;
}
```

## API端点定义

### 1. 设备认证（与现有机制一致）

#### 1.1 设备自动注册登录
```http
POST /device-auth/register
```

**请求体**:
```json
{
  "deviceId": "设备唯一标识",
  "name": "设备名称",
  "type": "设备类型",
  "platform": "ios|android",
  "model": "设备型号",
  "appVersion": "1.0.0"
}
```

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "设备注册成功",
  "data": {
    "token": "jwt_token_here",
    "device": {
      "id": "server_device_id",
      "deviceId": "设备唯一标识",
      "name": "设备名称",
      "type": "设备类型"
    },
    "group": {
      "id": "default_group_id",
      "name": "我的设备",
      "ownerId": "server_device_id",
      "memberCount": 1
    }
  }
}
```

#### 1.2 获取设备资料
```http
GET /device-auth/profile
```

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "获取成功",
  "data": {
    "device": {
      "id": "server_device_id",
      "deviceId": "设备唯一标识",
      "name": "设备名称",
      "isCurrentDevice": true,
      "isOnline": true
    },
    "groups": [
      {
        "id": "group_id",
        "name": "群组名称",
        "ownerId": "owner_device_id",
        "memberCount": 3,
        "devices": [
          {
            "id": "device_1",
            "name": "设备1",
            "isOnline": true,
            "isCurrentDevice": false
          }
        ]
      }
    ]
  }
}
```

### 2. 订阅管理（基于设备群组）

#### 2.1 获取设备订阅状态
```http
GET /subscription/device/status
```

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "获取成功",
  "data": {
    "subscription": {
      "id": "sub_123",
      "deviceId": "server_device_id",
      "plan": "basic",
      "status": "active",
      "platform": "ios",
      "transactionId": "1000000123456789",
      "productId": "basic_monthly",
      "purchaseDate": "2024-01-01T00:00:00Z",
      "expiresDate": "2024-02-01T00:00:00Z",
      "isTrialPeriod": false,
      "isIntroductoryPricePeriod": false,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    },
    "planConfig": {
      "maxDevices": 5,
      "features": ["group_sharing", "file_sync", "priority_support"]
    },
    "groupsAffected": [
      {
        "id": "group_1",
        "name": "我的设备",
        "isOwner": true,
        "currentMembers": 3,
        "maxMembers": 5
      }
    ]
  }
}
```

#### 2.2 验证购买（基于设备）
```http
POST /subscription/device/verify-purchase
```

**请求体**:
```json
{
  "platform": "ios",
  "receipt": "base64编码的购买凭证",
  "productId": "basic_monthly",
  "transactionId": "1000000123456789"
}
```

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "验证成功",
  "data": {
    "verified": true,
    "subscription": {
      "id": "sub_123",
      "deviceId": "server_device_id",
      "plan": "basic",
      "status": "active",
      "expiresDate": "2024-02-01T00:00:00Z"
    },
    "affectedGroups": [
      {
        "id": "group_1",
        "name": "我的设备",
        "newMaxMembers": 5
      }
    ]
  }
}
```

#### 2.3 恢复购买
```http
POST /subscription/restore
```

**请求体**:
```json
{
  "platform": "ios",
  "receipt": "base64编码的购买凭证"
}
```

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "恢复成功",
  "data": {
    "subscriptions": [
      {
        "id": "sub_123",
        "plan": "basic",
        "status": "active",
        "expiresDate": "2024-02-01T00:00:00Z"
      }
    ]
  }
}
```

#### 2.4 取消订阅
```http
POST /subscription/cancel
```

**请求体**:
```json
{
  "reason": "用户主动取消"
}
```

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "取消成功",
  "data": {
    "subscription": {
      "id": "sub_123",
      "status": "cancelled",
      "cancelDate": "2024-01-15T00:00:00Z"
    }
  }
}
```

#### 2.5 获取订阅历史
```http
GET /subscription/history
```

**查询参数**:
- `limit`: 返回数量限制，默认10，最大100
- `offset`: 偏移量，默认0
- `status`: 状态过滤，可选

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "获取成功",
  "data": {
    "subscriptions": [
      {
        "id": "sub_123",
        "plan": "basic",
        "status": "active",
        "purchaseDate": "2024-01-01T00:00:00Z",
        "expiresDate": "2024-02-01T00:00:00Z"
      }
    ],
    "total": 1,
    "hasMore": false
  }
}
```

### 3. 群组限制检查（基于群组内付费设备）

#### 3.1 检查群组成员限制
```http
POST /group/check-limit
```

**请求体**:
```json
{
  "groupId": "group_123",
  "action": "join|invite",
  "targetDeviceId": "device_789" // 被邀请设备ID（action为invite时）
}
```

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "检查完成",
  "data": {
    "allowed": true,
    "currentCount": 3,
    "maxCount": 10,
    "reason": "",
    "upgradeRequired": false,
    "suggestedPlan": null,
    "effectiveSubscription": {
      "plan": "pro",
      "maxDevices": 10,
      "isUnlimited": false
    },
    "paidDevices": [
      {
        "id": "device_456",
        "name": "付费设备A",
        "subscription": {
          "plan": "basic",
          "status": "active",
          "maxDevices": 5
        }
      },
      {
        "id": "device_789",
        "name": "付费设备B", 
        "subscription": {
          "plan": "pro",
          "status": "active",
          "maxDevices": 10
        }
      }
    ]
  }
}
```

**超出限制时的响应**:
```json
{
  "success": false,
  "code": 403,
  "message": "超出群组成员限制",
  "data": {
    "allowed": false,
    "currentCount": 10,
    "maxCount": 10,
    "reason": "当前群组最多支持10个成员，需要有设备购买企业版订阅",
    "upgradeRequired": true,
    "suggestedPlan": "enterprise",
    "effectiveSubscription": {
      "plan": "pro",
      "maxDevices": 10,
      "isUnlimited": false
    },
    "paidDevices": [
      {
        "id": "device_789",
        "name": "付费设备",
        "subscription": {
          "plan": "pro", 
          "status": "active",
          "maxDevices": 10
        }
      }
    ]
  }
}
```

**无限设备的响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "检查完成",
  "data": {
    "allowed": true,
    "currentCount": 25,
    "maxCount": -1,
    "reason": "企业版支持无限台设备",
    "upgradeRequired": false,
    "suggestedPlan": null,
    "effectiveSubscription": {
      "plan": "enterprise",
      "maxDevices": -1,
      "isUnlimited": true
    },
    "paidDevices": [
      {
        "id": "device_999",
        "name": "企业版设备",
        "subscription": {
          "plan": "enterprise",
          "status": "active",
          "maxDevices": -1
        }
      }
    ]
  }
}
```

#### 3.2 获取群组成员统计
```http
GET /group/{groupId}/stats
```

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "获取成功",
  "data": {
    "groupId": "group_123",
    "memberCount": 8,
    "maxMembers": 10,
    "isUnlimited": false,
    "effectiveSubscription": {
      "plan": "pro",
      "maxDevices": 10,
      "providedBy": "device_456"
    },
    "ownerDevice": {
      "id": "owner_device_id",
      "name": "群主设备",
      "isOwner": true,
      "hasSubscription": false
    },
    "paidDevices": [
      {
        "id": "device_456",
        "name": "付费设备A",
        "subscription": {
          "plan": "basic",
          "status": "active",
          "maxDevices": 5,
          "expiresDate": "2024-02-01T00:00:00Z"
        }
      },
      {
        "id": "device_789",
        "name": "付费设备B",
        "subscription": {
          "plan": "pro",
          "status": "active", 
          "maxDevices": 10,
          "expiresDate": "2024-03-01T00:00:00Z"
        }
      }
    ],
    "devices": [
      {
        "id": "device_1",
        "name": "设备1",
        "isOnline": true,
        "isOwner": true,
        "hasSubscription": false
      },
      {
        "id": "device_456",
        "name": "付费设备A",
        "isOnline": true,
        "isOwner": false,
        "hasSubscription": true,
        "subscriptionPlan": "basic"
      },
      {
        "id": "device_789",
        "name": "付费设备B",
        "isOnline": false,
        "isOwner": false,
        "hasSubscription": true,
        "subscriptionPlan": "pro"
      }
    ]
  }
}
```

**企业版无限设备的响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "获取成功",
  "data": {
    "groupId": "group_456",
    "memberCount": 25,
    "maxMembers": -1,
    "isUnlimited": true,
    "effectiveSubscription": {
      "plan": "enterprise",
      "maxDevices": -1,
      "providedBy": "device_999"
    },
    "ownerDevice": {
      "id": "owner_device_id",
      "name": "群主设备",
      "isOwner": true,
      "hasSubscription": false
    },
    "paidDevices": [
      {
        "id": "device_999",
        "name": "企业版设备",
        "subscription": {
          "plan": "enterprise",
          "status": "active",
          "maxDevices": -1,
          "expiresDate": "2024-12-01T00:00:00Z"
        }
      }
    ],
    "devices": [
      // ... 设备列表
    ]
  }
}
```

### 4. 产品信息

#### 4.1 获取订阅产品列表
```http
GET /products/subscriptions
```

**查询参数**:
- `platform`: 平台过滤，ios|android

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "获取成功",
  "data": {
    "products": [
      {
        "id": "basic_monthly",
        "plan": "basic",
        "type": "monthly",
        "price": "9.9",
        "currency": "CNY",
        "title": "基础版月付",
        "description": "支持5台设备群组",
        "features": ["5台设备", "云同步", "优先支持"]
      },
      {
        "id": "basic_yearly",
        "plan": "basic",
        "type": "yearly",
        "price": "99.9",
        "currency": "CNY",
        "title": "基础版年付",
        "description": "支持5台设备群组，年付优惠",
        "features": ["5台设备", "云同步", "优先支持"],
        "discount": "17%"
      },
      {
        "id": "pro_monthly",
        "plan": "pro",
        "type": "monthly",
        "price": "19.9",
        "currency": "CNY",
        "title": "专业版月付",
        "description": "支持10台设备群组",
        "features": ["10台设备", "云同步", "优先支持", "高级功能"]
      },
      {
        "id": "pro_yearly",
        "plan": "pro", 
        "type": "yearly",
        "price": "199.9",
        "currency": "CNY",
        "title": "专业版年付",
        "description": "支持10台设备群组，年付优惠",
        "features": ["10台设备", "云同步", "优先支持", "高级功能"],
        "discount": "17%"
      },
      {
        "id": "enterprise_monthly",
        "plan": "enterprise",
        "type": "monthly", 
        "price": "39.9",
        "currency": "CNY",
        "title": "企业版月付",
        "description": "支持无限台设备群组",
        "features": ["无限台设备", "云同步", "专属客服", "高级功能", "API支持"]
      },
      {
        "id": "enterprise_yearly",
        "plan": "enterprise",
        "type": "yearly",
        "price": "399.9", 
        "currency": "CNY",
        "title": "企业版年付",
        "description": "支持无限台设备群组，年付优惠",
        "features": ["无限台设备", "云同步", "专属客服", "高级功能", "API支持"],
        "discount": "17%"
      }
    ]
  }
}
```

### 5. Webhooks

#### 5.1 Apple App Store Server Notifications
```http
POST /webhooks/apple
```

**请求体**:
```json
{
  "signedPayload": "Apple签名的负载数据"
}
```

#### 5.2 Google Play Developer Notifications
```http
POST /webhooks/google
```

**请求体**:
```json
{
  "message": {
    "data": "base64编码的通知数据",
    "messageId": "消息ID",
    "publishTime": "发布时间"
  }
}
```

### 6. 管理接口

#### 6.1 获取用户订阅统计
```http
GET /admin/stats/subscriptions
```

**需要管理员权限**

**查询参数**:
- `startDate`: 开始日期
- `endDate`: 结束日期
- `plan`: 订阅计划过滤

**响应**:
```json
{
  "success": true,
  "code": 200,
  "message": "获取成功",
  "data": {
    "totalUsers": 1000,
    "activeSubscriptions": 150,
    "revenue": {
      "monthly": 1485.0,
      "yearly": 9990.0
    },
    "planDistribution": {
      "free": 850,
      "basic": 120,
      "pro": 30
    }
  }
}
```

## 错误处理

### 常见错误码
- `4001`: 无效的购买凭证
- `4002`: 购买凭证已被使用
- `4003`: 订阅已过期
- `4004`: 超出群组成员限制
- `4005`: 无效的产品ID
- `4006`: 平台不支持
- `4007`: 用户订阅不存在

### 错误响应示例
```json
{
  "success": false,
  "code": 4001,
  "message": "无效的购买凭证",
  "error": "Receipt validation failed",
  "details": {
    "platform": "ios",
    "transactionId": "1000000123456789",
    "validationError": "Receipt is not valid"
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## 业务逻辑说明

### 群组设备数量限制计算规则

群组的最大设备数量基于群组内所有付费设备的**最高订阅等级**：

1. **基础计算逻辑**：
   ```
   群组最大设备数 = MAX(群组内所有付费设备的max_devices)
   ```

2. **订阅等级对应的设备数量**：
   - 免费版：2台设备
   - 基础版：5台设备
   - 专业版：10台设备  
   - 企业版：无限台设备（-1）

3. **计算示例**：
   - 群组内无付费设备：最多2台设备（免费版）
   - 群组内有1台基础版设备：最多5台设备
   - 群组内有1台基础版 + 1台专业版设备：最多10台设备（取最高等级）
   - 群组内有1台企业版设备：无限台设备

4. **付费设备离开群组的影响**：
   - 当付费设备离开群组时，群组的最大设备数量会重新计算
   - 如果群组当前设备数量超过新的限制，需要提醒移除多余设备
   - 系统会自动阻止新设备加入，直到满足新的限制

5. **订阅过期的处理**：
   - 付费设备的订阅过期后，自动降级为免费版
   - 群组的最大设备数量会重新计算
   - 如果超出新限制，会通知群组成员升级订阅

## 安全考虑

### 1. 购买凭证验证
- iOS: 使用Apple App Store Server API验证购买凭证
- Android: 使用Google Play Developer API验证购买凭证

### 2. 防重放攻击
- 每个购买凭证只能使用一次
- 记录所有验证过的transactionId

### 3. 访问控制
- 设备只能访问自己的订阅信息
- 群组限制检查需要验证设备权限

### 4. 数据加密
- 敏感数据在传输和存储时都要加密
- 使用HTTPS协议

### 5. 群组限制强制执行
- 服务端实时计算群组最大设备数量
- 防止客户端绕过设备数量限制
- 付费设备状态变更时自动重新计算限制

## 数据库设计建议

### 设备表 (devices)
```sql
CREATE TABLE devices (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    type VARCHAR(50),
    platform VARCHAR(20),
    model VARCHAR(100),
    app_version VARCHAR(20),
    last_activity TIMESTAMP,
    is_online BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_device_id (device_id),
    INDEX idx_last_activity (last_activity)
);
```

### 订阅表 (subscriptions)
```sql
CREATE TABLE subscriptions (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    plan ENUM('free', 'basic', 'pro', 'enterprise') NOT NULL,
    status ENUM('active', 'expired', 'cancelled', 'pending', 'none') NOT NULL,
    platform ENUM('ios', 'android') NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    original_transaction_id VARCHAR(255),
    product_id VARCHAR(255),
    purchase_date TIMESTAMP,
    expires_date TIMESTAMP,
    is_trial_period BOOLEAN DEFAULT FALSE,
    is_introductory_price_period BOOLEAN DEFAULT FALSE,
    max_devices INT DEFAULT 2 COMMENT '最大设备数，-1表示无限制',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id),
    INDEX idx_device_id (device_id),
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_status (status),
    INDEX idx_plan_status (plan, status)
);
```

### 购买验证日志表 (purchase_verifications)
```sql
CREATE TABLE purchase_verifications (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    platform ENUM('ios', 'android') NOT NULL,
    receipt_data TEXT NOT NULL,
    verification_result JSON,
    success BOOLEAN,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id),
    INDEX idx_device_id (device_id),
    INDEX idx_created_at (created_at)
);
```

### 群组表 (groups)
```sql
CREATE TABLE groups (
    id VARCHAR(255) PRIMARY KEY,
    owner_device_id VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    member_count INT DEFAULT 0,
    -- max_members字段移除，动态计算基于群组内付费设备
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_device_id) REFERENCES devices(id),
    INDEX idx_owner_device_id (owner_device_id)
);
```

### 群组成员表 (group_members)
```sql
CREATE TABLE group_members (
    id VARCHAR(255) PRIMARY KEY,
    group_id VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id),
    FOREIGN KEY (device_id) REFERENCES devices(id),
    UNIQUE KEY unique_group_device (group_id, device_id),
    INDEX idx_group_id (group_id),
    INDEX idx_device_id (device_id)
);
```

## 部署和监控

### 环境变量配置
```bash
# 数据库
DATABASE_URL=mysql://user:password@localhost/sendtomyself

# JWT密钥
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=24h

# Apple配置
APPLE_KEY_ID=your-apple-key-id
APPLE_ISSUER_ID=your-apple-issuer-id
APPLE_PRIVATE_KEY=your-apple-private-key

# Google配置
GOOGLE_SERVICE_ACCOUNT_KEY=your-google-service-account-key

# Redis配置
REDIS_URL=redis://localhost:6379

# 监控
SENTRY_DSN=your-sentry-dsn
```

### 监控指标
- API响应时间
- 购买验证成功率
- 订阅状态同步频率
- 错误率统计
- 群组限制检查频率

### 日志记录
- 所有API请求和响应
- 购买验证过程
- 错误和异常
- 性能指标

## 测试建议

### 单元测试
- 购买凭证验证逻辑
- 订阅状态计算
- 群组限制检查
- 错误处理

### 集成测试
- 完整的购买流程
- Webhook处理
- 数据库操作
- 第三方API调用

### 性能测试
- 并发用户购买
- 大量群组限制检查
- 数据库查询优化

这份API文档涵盖了Send To Myself应用订阅功能的所有核心接口，您可以提供给后端开发团队进行实现。如需要补充或修改任何部分，请告诉我。 