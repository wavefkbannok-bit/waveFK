# waveFK — Home Assistant

ระบบผู้ช่วย AI ที่สั่งงานได้ผ่าน Telegram โดยมีคอมที่บ้านเป็นตัวหลัก

```
มือถือ (Telegram)  →  n8n (คอมที่บ้าน)  →  Claude AI  →  ตอบกลับ Telegram
```

---

## สิ่งที่ต้องมีก่อนเริ่ม

- [ ] Windows 10 / 11
- [ ] Node.js (ดาวน์โหลดที่ https://nodejs.org/ เลือก LTS)
- [ ] Claude API Key (จาก https://console.anthropic.com/)
- [ ] บัญชี Telegram

---

## ขั้นตอนที่ 1: ติดตั้ง Node.js

1. เข้าไปที่ https://nodejs.org/
2. กดดาวน์โหลด **LTS version**
3. ติดตั้งตามปกติ (กด Next ไปเรื่อย ๆ)
4. เปิด Command Prompt แล้วทดสอบ:
   ```
   node --version
   ```
   ถ้าเห็นเลข version เช่น `v20.x.x` แสดงว่าติดตั้งสำเร็จ

---

## ขั้นตอนที่ 2: สร้าง Telegram Bot

1. เปิด Telegram แล้วค้นหา **@BotFather**
2. ส่งข้อความ `/newbot`
3. ตั้งชื่อ bot เช่น `waveFK Assistant`
4. ตั้ง username เช่น `wavefk_bot` (ต้องลงท้ายด้วย `bot`)
5. คัดลอก **Bot Token** ที่ได้รับ (รูปแบบ: `123456789:ABCdef...`)

---

## ขั้นตอนที่ 3: เริ่ม n8n

1. ดับเบิลคลิกที่ไฟล์ `setup/start-n8n.bat`
2. รอให้ n8n ติดตั้งและเริ่มทำงาน (ครั้งแรกอาจใช้เวลา 2-3 นาที)
3. เปิดเบราว์เซอร์ไปที่: **http://localhost:5678**
4. สร้างบัญชี n8n (ใช้ email ใดก็ได้ เป็น local account)

---

## ขั้นตอนที่ 4: ตั้งค่า Credentials ใน n8n

### 4.1 เพิ่ม Telegram Bot Token

1. ใน n8n ไปที่เมนู **Credentials** (ซ้ายมือ)
2. กด **Add Credential**
3. ค้นหา **Telegram**
4. ใส่ **Bot Token** ที่ได้จาก BotFather
5. กด **Save** ตั้งชื่อว่า `Telegram Bot`

### 4.2 เพิ่ม Claude API Key

1. กด **Add Credential** อีกครั้ง
2. ค้นหา **Header Auth**
3. ตั้งค่าดังนี้:
   - **Name:** `x-api-key`
   - **Value:** `sk-ant-xxxxxxxx` (Claude API Key ของคุณ)
4. กด **Save** ตั้งชื่อว่า `Claude API Key`

---

## ขั้นตอนที่ 5: Import Workflow

1. ใน n8n ไปที่เมนู **Workflows**
2. กด **Import from File**
3. เลือกไฟล์ `workflow/telegram-claude-bot.json`
4. เชื่อม credentials:
   - Node **Telegram Trigger** → เลือก `Telegram Bot`
   - Node **Claude API** → เลือก `Claude API Key`
   - Node **Send Reply** → เลือก `Telegram Bot`
5. กด **Save**

---

## ขั้นตอนที่ 6: เปิดใช้งาน

1. กด **Activate** (toggle สีเขียวมุมบนขวา)
2. เปิด Telegram แล้วหา Bot ที่สร้างไว้
3. ส่งข้อความทดสอบ เช่น `สวัสดี`
4. Bot ควรตอบกลับภายใน 3-5 วินาที

---

## โครงสร้างไฟล์

```
waveFK/
├── README.md                        # คู่มือนี้
├── .env.example                     # Template สำหรับ API Keys
├── workflow/
│   └── telegram-claude-bot.json     # n8n workflow พร้อม import
└── setup/
    └── start-n8n.bat                # Script เริ่ม n8n (Windows)
```

---

## การแก้ปัญหาเบื้องต้น

| ปัญหา | วิธีแก้ |
|-------|--------|
| Bot ไม่ตอบ | ตรวจสอบว่า n8n รันอยู่และ workflow ถูก Activate |
| Error: 401 Unauthorized | Claude API Key ผิด ตรวจสอบใน Credentials |
| Error: Telegram token invalid | Bot Token ผิด ตรวจสอบจาก BotFather |
| n8n ไม่เปิด | รัน `start-n8n.bat` แบบ Run as Administrator |
| คอมปิดแล้ว bot ไม่ทำงาน | n8n ต้องรันอยู่ตลอด ฝาก PC เปิดทิ้งไว้ |

---

## ฟีเจอร์ที่จะเพิ่มได้ในอนาคต

- บันทึก conversation history (จำการสนทนา)
- รองรับรูปภาพ / เอกสาร
- สั่งเปิด/ปิดโปรแกรมบนคอม
- ตั้ง reminder และแจ้งเตือน
- เชื่อมต่อกับ Google Calendar, Notion, ฯลฯ
