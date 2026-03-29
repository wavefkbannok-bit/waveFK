# ============================================================
#  ทดสอบ: telegram-claude-bot.json
#  ตรวจสอบโครงสร้างและความถูกต้องของ workflow
# ============================================================

Describe "ตรวจสอบ Workflow JSON" {

    BeforeAll {
        $workflowPath = Resolve-Path "$PSScriptRoot\..\workflow\telegram-claude-bot.json"
        $rawJson = Get-Content $workflowPath -Raw
        $script:workflow = $rawJson | ConvertFrom-Json
    }

    Context "ความถูกต้องของ JSON" {

        It "ไฟล์ JSON ต้องอ่านและแปลงได้สำเร็จ" {
            $script:workflow | Should -Not -BeNullOrEmpty
        }

        It "ต้องมี field 'name' ที่ระดับ root" {
            $script:workflow.name | Should -Not -BeNullOrEmpty
        }

        It "ต้องมี field 'nodes' ที่ระดับ root" {
            $script:workflow.nodes | Should -Not -BeNullOrEmpty
        }

        It "ต้องมี field 'connections' ที่ระดับ root" {
            $script:workflow.connections | Should -Not -BeNullOrEmpty
        }
    }

    Context "จำนวนและชื่อ Node" {

        It "ต้องมี node ครบ 5 node" {
            $script:workflow.nodes.Count | Should -Be 5
        }

        It "ต้องมี node ชื่อ 'Telegram Trigger'" {
            $node = $script:workflow.nodes | Where-Object { $_.name -eq "Telegram Trigger" }
            $node | Should -Not -BeNullOrEmpty
        }

        It "ต้องมี node ชื่อ 'Extract Message'" {
            $node = $script:workflow.nodes | Where-Object { $_.name -eq "Extract Message" }
            $node | Should -Not -BeNullOrEmpty
        }

        It "ต้องมี node ชื่อ 'Claude API'" {
            $node = $script:workflow.nodes | Where-Object { $_.name -eq "Claude API" }
            $node | Should -Not -BeNullOrEmpty
        }

        It "ต้องมี node ชื่อ 'Extract Reply'" {
            $node = $script:workflow.nodes | Where-Object { $_.name -eq "Extract Reply" }
            $node | Should -Not -BeNullOrEmpty
        }

        It "ต้องมี node ชื่อ 'Send Reply'" {
            $node = $script:workflow.nodes | Where-Object { $_.name -eq "Send Reply" }
            $node | Should -Not -BeNullOrEmpty
        }
    }

    Context "ตรวจสอบ Credential Placeholders (ห้าม commit key จริง)" {

        It "Telegram Trigger ต้องใช้ credential placeholder 'telegram-cred'" {
            $node = $script:workflow.nodes | Where-Object { $_.name -eq "Telegram Trigger" }
            $node.credentials.telegramApi.id | Should -Be "telegram-cred"
        }

        It "Send Reply ต้องใช้ credential placeholder 'telegram-cred'" {
            $node = $script:workflow.nodes | Where-Object { $_.name -eq "Send Reply" }
            $node.credentials.telegramApi.id | Should -Be "telegram-cred"
        }

        It "Claude API ต้องใช้ credential placeholder 'claude-cred'" {
            $node = $script:workflow.nodes | Where-Object { $_.name -eq "Claude API" }
            $node.credentials.httpHeaderAuth.id | Should -Be "claude-cred"
        }

        It "ไม่มี API key จริงใน JSON (ห้ามขึ้นต้นด้วย sk-ant-)" {
            $rawJson = Get-Content (Resolve-Path "$PSScriptRoot\..\workflow\telegram-claude-bot.json") -Raw
            $rawJson | Should -Not -Match "sk-ant-"
        }

        It "ไม่มี Telegram token จริงใน JSON (ห้ามมีรูปแบบ digits:token)" {
            $rawJson = Get-Content (Resolve-Path "$PSScriptRoot\..\workflow\telegram-claude-bot.json") -Raw
            $rawJson | Should -Not -Match '"\d{8,12}:[A-Za-z0-9_-]{35}"'
        }
    }

    Context "ตรวจสอบการเชื่อมต่อระหว่าง Node" {

        It "Telegram Trigger ต้องเชื่อมต่อไปยัง Extract Message" {
            $conn = $script:workflow.connections.'Telegram Trigger'.main[0][0]
            $conn.node | Should -Be "Extract Message"
        }

        It "Extract Message ต้องเชื่อมต่อไปยัง Claude API" {
            $conn = $script:workflow.connections.'Extract Message'.main[0][0]
            $conn.node | Should -Be "Claude API"
        }

        It "Claude API ต้องเชื่อมต่อไปยัง Extract Reply" {
            $conn = $script:workflow.connections.'Claude API'.main[0][0]
            $conn.node | Should -Be "Extract Reply"
        }

        It "Extract Reply ต้องเชื่อมต่อไปยัง Send Reply" {
            $conn = $script:workflow.connections.'Extract Reply'.main[0][0]
            $conn.node | Should -Be "Send Reply"
        }
    }

    Context "ตรวจสอบการตั้งค่า Claude API Node" {

        BeforeAll {
            $script:claudeNode = $script:workflow.nodes | Where-Object { $_.name -eq "Claude API" }
        }

        It "ต้องเรียก Anthropic Messages API" {
            $script:claudeNode.parameters.url | Should -Be "https://api.anthropic.com/v1/messages"
        }

        It "ต้องใช้ method POST" {
            $script:claudeNode.parameters.method | Should -Be "POST"
        }

        It "ต้องระบุ model claude-haiku ใน jsonBody" {
            $script:claudeNode.parameters.jsonBody | Should -Match "claude-haiku"
        }

        It "ต้องมี max_tokens ใน jsonBody" {
            $script:claudeNode.parameters.jsonBody | Should -Match '"max_tokens"'
        }

        It "ต้องส่ง anthropic-version header" {
            $versionHeader = $script:claudeNode.parameters.headerParameters.parameters |
                Where-Object { $_.name -eq "anthropic-version" }
            $versionHeader | Should -Not -BeNullOrEmpty
        }
    }
}
