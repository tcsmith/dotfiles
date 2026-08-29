Invoke-Expression (&starship init powershell)

function touch {
    param([string]$file)

    if (Test-Path $file) {
        # Update the timestamp if the file exists
        Set-ItemProperty -Path $file -Name LastWriteTime -Value (Get-Date)
    }
    else {
        # Create a new file if it doesn't exist
        New-Item -Path $file -ItemType File
    }
}

function codex
{
    $releases_path = Join-Path $env:USERPROFILE '.codex\packages\standalone\releases'

    $release = Get-ChildItem -LiteralPath $releases_path -Directory |
        Where-Object Name -Match '^\d+\.\d+\.\d+-x86_64-pc-windows-msvc$' |
        Sort-Object {
            [version]($_.Name -Replace '-.*$', '')
        } -Descending |
        Select-Object -First 1

    if (-not $release)
    {
        throw "No versioned Codex installation found under: $releases_path"
    }

    $codex_exe = Join-Path $release.FullName 'bin\codex.exe'

    if (-not (Test-Path -LiteralPath $codex_exe))
    {
        throw "Codex executable not found: $codex_exe"
    }

    & $codex_exe @args
}