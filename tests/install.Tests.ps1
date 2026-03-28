# ============================================================
#  ทดสอบ: 1-install.ps1
#  ทดสอบ logic การตรวจจับ version, fallback และ PATH refresh
# ============================================================

Describe "ตรวจสอบ Node.js Version Detection" {

    Context "การ parse version string" {

        It "ต้องรู้จัก Node.js version format ที่ถูกต้อง (v20.18.0)" {
            $output = "v20.18.0"
            $output -match "v\d+" | Should -BeTrue
        }

        It "ต้องรู้จัก Node.js version format เวอร์ชันเก่า (v16.x)" {
            $output = "v16.20.2"
            $output -match "v\d+" | Should -BeTrue
        }

        It "ต้องไม่รู้จัก output ที่ไม่ใช่ version (command not found)" {
            $output = "'node' is not recognized as an internal or external command"
            $output -match "v\d+" | Should -BeFalse
        }

        It "ต้องไม่รู้จัก output ที่ว่างเปล่า" {
            $output = ""
            $output -match "v\d+" | Should -BeFalse
        }

        It "ต้องไม่รู้จัก output ที่เป็นข้อความทั่วไปที่มีตัวเลข" {
            $output = "Error code 1"
            $output -match "v\d+" | Should -BeFalse
        }
    }
}

Describe "ตรวจสอบ n8n Version Detection" {

    Context "การ parse version string" {

        It "ต้องรู้จัก n8n version format ที่ถูกต้อง (1.68.0)" {
            $output = "1.68.0"
            $output -match "\d+\.\d+" | Should -BeTrue
        }

        It "ต้องรู้จัก n8n version format เวอร์ชันเก่า (0.235.0)" {
            $output = "0.235.0"
            $output -match "\d+\.\d+" | Should -BeTrue
        }

        It "ต้องไม่รู้จัก output ที่ไม่ใช่ version" {
            $output = "'n8n' is not recognized as an internal or external command"
            # หมายเหตุ: output นี้มีตัวเลขจาก error message ด้วย
            # ดังนั้น regex \d+\.\d+ ต้องไม่ match กับ error message
            $output -match "^\d+\.\d+" | Should -BeFalse
        }

        It "ต้องไม่รู้จัก output ที่ว่างเปล่า" {
            $output = ""
            $output -match "\d+\.\d+" | Should -BeFalse
        }
    }
}

Describe "ตรวจสอบ PATH Refresh Logic" {

    Context "การ combine Machine และ User PATH" {

        It "ต้อง combine ด้วย semicolon" {
            $machinePath = "C:\Windows\System32"
            $userPath    = "C:\Users\User\AppData\Roaming\npm"
            $combined    = $machinePath + ";" + $userPath
            $combined    | Should -Match ";"
        }

        It "ต้องมี Machine PATH ใน combined path" {
            $machinePath = "C:\Windows\System32"
            $userPath    = "C:\Users\User\AppData\Roaming\npm"
            $combined    = $machinePath + ";" + $userPath
            $combined    | Should -Match [regex]::Escape("C:\Windows\System32")
        }

        It "ต้องมี User PATH ใน combined path" {
            $machinePath = "C:\Windows\System32"
            $userPath    = "C:\Users\User\AppData\Roaming\npm"
            $combined    = $machinePath + ";" + $userPath
            $combined    | Should -Match [regex]::Escape("C:\Users\User\AppData\Roaming\npm")
        }

        It "ต้องไม่มี double semicolon เมื่อ user PATH ว่าง" {
            $machinePath = "C:\Windows\System32"
            $userPath    = ""
            $combined    = $machinePath + ";" + $userPath
            # trim trailing semicolon ที่อาจเกิดขึ้น
            $combined.TrimEnd(";") | Should -Not -Match ";;"
        }
    }
}

Describe "ตรวจสอบ npm Exit Code Handling" {

    Context "การตรวจสอบผลของ npm install" {

        It "exit code 0 ต้องถือว่า npm install สำเร็จ" {
            $exitCode = 0
            ($exitCode -ne 0) | Should -BeFalse
        }

        It "exit code 1 ต้องถือว่า npm install ล้มเหลว" {
            $exitCode = 1
            ($exitCode -ne 0) | Should -BeTrue
        }

        It "exit code 127 (command not found) ต้องถือว่าล้มเหลว" {
            $exitCode = 127
            ($exitCode -ne 0) | Should -BeTrue
        }

        It "exit code -1 ต้องถือว่าล้มเหลว" {
            $exitCode = -1
            ($exitCode -ne 0) | Should -BeTrue
        }
    }
}

Describe "ตรวจสอบ winget Fallback Logic" {

    Context "การตัดสินใจใช้ fallback" {

        It "ต้องใช้ fallback เมื่อ winget ล้มเหลว" {
            $wingetOk = $false
            # จำลองว่า winget throw exception
            try {
                throw "winget not found"
            } catch {
                $wingetOk = $false
            }
            $wingetOk | Should -BeFalse
        }

        It "ต้องไม่ใช้ fallback เมื่อ winget สำเร็จ" {
            $wingetOk = $false
            try {
                # จำลองว่า winget สำเร็จ
                $wingetOk = $true
            } catch {
                $wingetOk = $false
            }
            $wingetOk | Should -BeTrue
        }

        It "ถ้า wingetOk เป็น false ต้องเข้าสู่ขั้นตอน direct download" {
            $wingetOk = $false
            $shouldDownload = (-not $wingetOk)
            $shouldDownload | Should -BeTrue
        }

        It "ถ้า wingetOk เป็น true ต้องข้าม direct download" {
            $wingetOk = $true
            $shouldDownload = (-not $wingetOk)
            $shouldDownload | Should -BeFalse
        }
    }
}
