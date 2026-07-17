[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$gbk = [System.Text.Encoding]::GetEncoding(936)
$writer = $null

function Get-DisplayWidth([string]$Value) {
    if ($null -eq $Value) {
        return 0
    }

    # CMD 使用代码页 936；GBK 字节数正好对应英文和中文在终端中的显示列宽。
    return $gbk.GetByteCount($Value)
}

function Format-Cell([string]$Value, [int]$Width) {
    if ($null -eq $Value) {
        $Value = ''
    }

    $padding = $Width - (Get-DisplayWidth $Value)
    if ($padding -lt 0) {
        $padding = 0
    }
    return ' ' + $Value + ''.PadRight($padding) + ' '
}

function Format-Row([object[]]$Values, [int[]]$Widths) {
    $cells = for ($index = 0; $index -lt $Values.Count; $index++) {
        Format-Cell ([string]$Values[$index]) $Widths[$index]
    }
    return '|' + ($cells -join '|') + '|'
}

function Format-Border([int[]]$Widths) {
    $segments = foreach ($width in $Widths) {
        ''.PadRight($width + 2, '-')
    }
    return '+' + ($segments -join '+') + '+'
}

try {
    $itemCount = 0
    if (-not [int]::TryParse($env:REMOTE_ITEM_COUNT, [ref]$itemCount) -or $itemCount -le 0) {
        throw '没有可显示的网盘项目。'
    }

    $headers = @('序号', '名称', '类型', '大小', '修改日期')
    $widths = @($headers | ForEach-Object { Get-DisplayWidth $_ })
    $rows = New-Object System.Collections.ArrayList

    for ($index = 1; $index -le $itemCount; $index++) {
        $row = @(
            [string]$index
            [Environment]::GetEnvironmentVariable("REMOTE_NAME_$index")
            [Environment]::GetEnvironmentVariable("REMOTE_TYPE_$index")
            [Environment]::GetEnvironmentVariable("REMOTE_SIZE_$index")
            [Environment]::GetEnvironmentVariable("REMOTE_MODIFIED_$index")
        )
        [void]$rows.Add($row)

        for ($column = 0; $column -lt $row.Count; $column++) {
            $valueWidth = Get-DisplayWidth ([string]$row[$column])
            if ($valueWidth -gt $widths[$column]) {
                $widths[$column] = $valueWidth
            }
        }
    }

    $writer = New-Object System.IO.StreamWriter([Console]::OpenStandardOutput(), $gbk)
    $writer.AutoFlush = $true
    $border = Format-Border $widths
    $writer.WriteLine($border)
    $writer.WriteLine((Format-Row $headers $widths))
    $writer.WriteLine($border)
    foreach ($row in $rows) {
        $writer.WriteLine((Format-Row $row $widths))
    }
    $writer.WriteLine($border)
}
catch {
    exit 1
}
finally {
    if ($null -ne $writer) {
        $writer.Flush()
        $writer.Dispose()
    }
}
