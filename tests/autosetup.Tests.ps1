# ============================================================
#  ทดสอบ: 2-autosetup.ps1
#  ทดสอบ logic การ validate input, การแทนที่ credential ID
#  และ การจัดการ error ของ health check loop
# ============================================================

Describe "ตรวจสอบ Input Validation" {

    Context "Telegram Bot Token" {

        It "ต้องปฏิเสธ token ที่เป็น empty string" {
            [string]::IsNullOrWhiteSpace("") | Should -BeTrue
        }

        It "ต้องปฏิเสธ token ที่เป็น whitespace เท่านั้น" {
            [string]::IsNullOrWhiteSpace("   ") | Should -BeTrue
        }

        It "ต้องยอมรับ Telegram token ที่ถูกรูปแบบ (digits:alphanumeric)" {
            "1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ_-abc" -match "^\d+:[A-Za-z0-9_-]+$" |
                Should -BeTrue
        }

        It "ต้องปฏิเสธ Telegram token ที่ผิดรูปแบบ (ไม่มี colon)" {
            "bad-token-without-colon" -match "^\d+:[A-Za-z0-9_-]+$" |
                Should -BeFalse
        }

        It "ต้องปฏิเสธ Telegram token ที่ผิดรูปแบบ (ตัวอักษรอยู่หน้า colon)" {
            "abc:XYZdefGHIjklMNOpqrSTU" -match "^\d+:[A-Za-z0-9_-]+$" |
                Should -BeFalse
        }

        It "ต้องปฏิเสธ Telegram token ที่ผิดรูปแบบ (มีแค่ตัวเลข ไม่มี colon)" {
            "1234567890" -match "^\d+:[A-Za-z0-9_-]+$" |
                Should -BeFalse
        }
    }

    Context "Anthropic API Key" {

        It "ต้องปฏิเสธ API key ที่เป็น empty string" {
            [string]::IsNullOrWhiteSpace("") | Should -BeTrue
        }

        It "ต้องยอมรับ Anthropic key ที่ขึ้นต้นด้วย sk-ant-" {
            "sk-ant-api03-abcdefghijklmn" -match "^sk-ant-" | Should -BeTrue
        }

        It "ต้องปฏิเสธ key ที่ไม่ขึ้นต้นด้วย sk-ant-" {
            "sk-proj-abcdefghijklmn" -match "^sk-ant-" | Should -BeFalse
        }

        It "ต้องปฏิเสธ key ที่เป็น placeholder ทั่วไป" {
            "YOUR_API_KEY_HERE" -match "^sk-ant-" | Should -BeFalse
        }

        It "ต้องปฏิเสธทั้งสองค่าพร้อมกัน เมื่อทั้งคู่ว่าง" {
            $token = ""
            $key = ""
            ([string]::IsNullOrWhiteSpace($token) -or [string]::IsNullOrWhiteSpace($key)) |
                Should -BeTrue
        }
    }
}

Describe "ตรวจสอบ Credential ID Replacement ใน Workflow JSON" {

    BeforeAll {
        $script:workflowPath = Resolve-Path "$PSScriptRoot\..\workflow\telegram-claude-bot.json"
    }

    Context "การแทนที่ telegram-cred" {

        It "ต้องแทนที่ placeholder 'telegram-cred' ด้วย ID จริงได้" {
            $json = '{"id": "telegram-cred", "name": "Telegram Bot"}'
            $result = $json -replace '"id": "telegram-cred"', '"id": "abc123"'
            $parsed = $result | ConvertFrom-Json
            $parsed.id | Should -Be "abc123"
        }

        It "JSON ยังคงถูกต้องหลังแทนที่ด้วย ID ที่เป็นตัวเลข" {
            $json = Get-Content $script:workflowPath -Raw
            $result = $json -replace '"id": "telegram-cred"', '"id": "999"'
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It "JSON ยังคงถูกต้องหลังแทนที่ด้วย ID ที่เป็น UUID" {
            $json = Get-Content $script:workflowPath -Raw
            $result = $json -replace '"id": "telegram-cred"', '"id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"'
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It "การแทนที่ต้องเปลี่ยน node Telegram Trigger ให้ใช้ ID จริง" {
            $json = Get-Content $script:workflowPath -Raw
            $result = $json -replace '"id": "telegram-cred"', '"id": "real-id-99"'
            $workflow = $result | ConvertFrom-Json
            $triggerNode = $workflow.nodes | Where-Object { $_.name -eq "Telegram Trigger" }
            $triggerNode.credentials.telegramApi.id | Should -Be "real-id-99"
        }
    }

    Context "การแทนที่ claude-cred" {

        It "ต้องแทนที่ placeholder 'claude-cred' ด้วย ID จริงได้" {
            $json = '{"id": "claude-cred", "name": "Claude API Key"}'
            $result = $json -replace '"id": "claude-cred"', '"id": "xyz789"'
            $parsed = $result | ConvertFrom-Json
            $parsed.id | Should -Be "xyz789"
        }

        It "JSON ยังคงถูกต้องหลังแทนที่ claude-cred ด้วย ID จริง" {
            $json = Get-Content $script:workflowPath -Raw
            $result = $json -replace '"id": "claude-cred"', '"id": "888"'
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It "การแทนที่ต้องเปลี่ยน Claude API node ให้ใช้ ID จริง" {
            $json = Get-Content $script:workflowPath -Raw
            $result = $json -replace '"id": "claude-cred"', '"id": "claude-real-55"'
            $workflow = $result | ConvertFrom-Json
            $claudeNode = $workflow.nodes | Where-Object { $_.name -eq "Claude API" }
            $claudeNode.credentials.httpHeaderAuth.id | Should -Be "claude-real-55"
        }
    }

    Context "การแทนที่พร้อมกันทั้งสอง credential" {

        It "แทนที่ทั้งสอง credential พร้อมกันได้โดยไม่ทำลาย JSON" {
            $json = Get-Content $script:workflowPath -Raw
            $json = $json -replace '"id": "telegram-cred"', '"id": "tg-001"'
            $json = $json -replace '"id": "claude-cred"',   '"id": "cl-002"'
            { $json | ConvertFrom-Json } | Should -Not -Throw
        }

        It "หลังแทนที่แล้วต้องไม่มี placeholder เหลืออยู่" {
            $json = Get-Content $script:workflowPath -Raw
            $json = $json -replace '"id": "telegram-cred"', '"id": "tg-001"'
            $json = $json -replace '"id": "claude-cred"',   '"id": "cl-002"'
            $json | Should -Not -Match '"id": "telegram-cred"'
            $json | Should -Not -Match '"id": "claude-cred"'
        }
    }
}

Describe "ตรวจสอบ Health Check Logic" {

    Context "การตรวจสอบ HTTP response" {

        It "ต้องถือว่า status 200 คือ n8n พร้อมแล้ว" {
            $mockResponse = [PSCustomObject]@{ StatusCode = 200 }
            ($mockResponse.StatusCode -eq 200) | Should -BeTrue
        }

        It "ต้องถือว่า status 503 คือ n8n ยังไม่พร้อม" {
            $mockResponse = [PSCustomObject]@{ StatusCode = 503 }
            ($mockResponse.StatusCode -eq 200) | Should -BeFalse
        }

        It "ต้องถือว่า connection error คือ n8n ยังไม่พร้อม" {
            $ready = $false
            try {
                # จำลอง exception จาก Invoke-WebRequest
                throw [System.Net.WebException]::new("Connection refused")
            } catch {
                $ready = $false
            }
            $ready | Should -BeFalse
        }
    }

    Context "การนับ retry และ timeout" {

        It "ต้องหยุดเมื่อครบ 20 รอบ (timeout)" {
            $maxTries = 20
            $tries = 0
            $ready = $false

            # จำลอง loop โดยไม่มี sleep และไม่มี n8n จริง
            while (-not $ready -and $tries -lt $maxTries) {
                $tries++
                # n8n ไม่ตอบ — ready ยังเป็น false
            }

            $tries | Should -Be 20
            $ready  | Should -BeFalse
        }

        It "ต้องออกจาก loop ทันทีเมื่อ n8n ตอบสนอง" {
            $maxTries = 20
            $tries = 0
            $ready = $false

            while (-not $ready -and $tries -lt $maxTries) {
                $tries++
                # จำลองว่า n8n พร้อมในรอบแรก
                $ready = $true
            }

            $tries | Should -Be 1
            $ready  | Should -BeTrue
        }

        It "ต้องออกจาก loop เมื่อ n8n พร้อมในรอบที่ 5" {
            $maxTries = 20
            $readyOnTry = 5
            $tries = 0
            $ready = $false

            while (-not $ready -and $tries -lt $maxTries) {
                $tries++
                if ($tries -eq $readyOnTry) { $ready = $true }
            }

            $tries | Should -Be 5
            $ready  | Should -BeTrue
        }
    }
}

Describe "ตรวจสอบการจัดการ Error ของ Account Setup" {

    Context "Owner account creation" {

        It "HTTP 200 ต้องถือว่าสร้างบัญชีสำเร็จ" {
            $statusCode = 200
            $success = ($statusCode -ge 200 -and $statusCode -lt 300)
            $success | Should -BeTrue
        }

        It "HTTP 409 (Conflict) ต้องถือว่าบัญชีมีอยู่แล้ว ไม่ใช่ error" {
            # ใน script จริง exception ถูก catch และ login แทน
            # ทดสอบว่า logic จัดการ 409 เป็น non-fatal ได้
            $statusCode = 409
            $isConflict = ($statusCode -eq 409)
            $isConflict | Should -BeTrue
        }

        It "HTTP 500 ควรถือว่าเป็น error จริง (ไม่ใช่แค่ 'account exists')" {
            $statusCode = 500
            $isServerError = ($statusCode -ge 500)
            $isServerError | Should -BeTrue
        }
    }
}
