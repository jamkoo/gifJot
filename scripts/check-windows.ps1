[CmdletBinding()]
param(
    [switch]$RequireSwift,
    [switch]$SkipSwiftTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "apps/macos/GifJot.xcodeproj/project.pbxproj"

function Invoke-NativeCheck {
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [scriptblock]$Command
    )

    Write-Host "[check] $Label"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
}

function Enable-MsvcEnvironment {
    if ($null -ne (Get-Command link.exe -ErrorAction SilentlyContinue)) {
        return $true
    }

    $vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path -LiteralPath $vswherePath)) {
        return $false
    }

    $installationPath = & $vswherePath `
        -latest `
        -products * `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($installationPath)) {
        return $false
    }

    $developerShell = Join-Path `
        $installationPath `
        "Common7/Tools/Microsoft.VisualStudio.DevShell.dll"
    if (-not (Test-Path -LiteralPath $developerShell)) {
        return $false
    }

    Import-Module $developerShell
    Enter-VsDevShell `
        -VsInstallPath $installationPath `
        -SkipAutomaticLocation `
        -DevCmdArguments "-arch=x64 -host_arch=x64" | Out-Null

    return $null -ne (Get-Command link.exe -ErrorAction SilentlyContinue)
}

Push-Location $repoRoot
try {
    Invoke-NativeCheck "repository root" {
        git rev-parse --is-inside-work-tree
    }

    Invoke-NativeCheck "whitespace errors" {
        git diff --check HEAD --
    }

    Write-Host "[check] unresolved merge markers"
    $mergeMarkers = git grep -n -I -E "^(<<<<<<< |=======|>>>>>>> )" -- . 2>$null
    $markerExitCode = $LASTEXITCODE
    if ($markerExitCode -eq 0) {
        throw "Unresolved merge markers found:`n$($mergeMarkers -join "`n")"
    }
    if ($markerExitCode -ne 1) {
        throw "Merge-marker scan failed with exit code $markerExitCode."
    }

    Write-Host "[check] public repository boundary"
    $trackedFiles = @(git ls-files)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not enumerate tracked files."
    }

    $privatePathPattern = "(^|/)(\.agents|\.codex)(/|$)|(^|/)(AGENTS|PROJECT_CONTEXT)\.md$"
    $secretFilePattern = "\.(cer|key|mobileprovision|p12|p8|pem|provisionprofile|secret\.xcconfig)$"
    $forbiddenTrackedFiles = @(
        $trackedFiles | Where-Object {
            $_ -match $privatePathPattern -or $_ -match $secretFilePattern
        }
    )
    if ($forbiddenTrackedFiles.Count -gt 0) {
        throw "Private metadata or secret material is tracked:`n$($forbiddenTrackedFiles -join "`n")"
    }

    Write-Host "[check] Xcode source references"
    if (-not (Test-Path -LiteralPath $projectPath)) {
        throw "Missing Xcode project file: $projectPath"
    }

    $projectContents = Get-Content -Raw -LiteralPath $projectPath
    $trackedSwiftFiles = @(
        git ls-files -- ":(glob)apps/macos/GifJot/**/*.swift" ":(glob)apps/macos/GifJotTests/*.swift"
    )
    if ($LASTEXITCODE -ne 0) {
        throw "Could not enumerate tracked Swift files."
    }

    $trackedSwiftNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $missingProjectReferences = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $trackedSwiftFiles) {
        $name = [System.IO.Path]::GetFileName($file)
        [void]$trackedSwiftNames.Add($name)
        if (-not $projectContents.Contains("$name in Sources")) {
            $missingProjectReferences.Add($file)
        }
    }
    if ($missingProjectReferences.Count -gt 0) {
        throw "Tracked Swift files are missing from the Xcode Sources phase:`n$($missingProjectReferences -join "`n")"
    }

    $staleProjectReferences = [System.Collections.Generic.List[string]]::new()
    $pathMatches = [regex]::Matches($projectContents, "path = ([^;]+\.swift);")
    foreach ($match in $pathMatches) {
        $name = $match.Groups[1].Value.Trim('"')
        if (-not $trackedSwiftNames.Contains($name)) {
            $staleProjectReferences.Add($name)
        }
    }
    if ($staleProjectReferences.Count -gt 0) {
        $uniqueStaleReferences = $staleProjectReferences | Sort-Object -Unique
        throw "The Xcode project references missing Swift files:`n$($uniqueStaleReferences -join "`n")"
    }

    $registeredPaths = @(
        @(
            [Environment]::GetEnvironmentVariable("Path", "Machine"),
            [Environment]::GetEnvironmentVariable("Path", "User")
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($registeredPaths.Count -gt 0) {
        $env:Path = "$env:Path;$($registeredPaths -join ';')"
    }

    $swiftCommand = Get-Command swift -ErrorAction SilentlyContinue
    $swiftPath = if ($null -ne $swiftCommand) {
        $swiftCommand.Source
    } else {
        $swiftSearchRoots = @(
            @(
                "$env:ProgramFiles\Swift",
                "$env:LOCALAPPDATA\Programs\Swift",
                "C:\Library\Developer\Toolchains"
            ) | Where-Object { Test-Path -LiteralPath $_ }
        )

        if ($swiftSearchRoots.Count -gt 0) {
            Get-ChildItem `
                -Path $swiftSearchRoots `
                -Filter swift.exe `
                -File `
                -Recurse `
                -ErrorAction SilentlyContinue |
                Select-Object -First 1 -ExpandProperty FullName
        }
    }

    if ([string]::IsNullOrWhiteSpace($swiftPath)) {
        $installCommand = "winget install --id Swift.Toolchain --exact --source winget"
        if ($RequireSwift) {
            throw "Swift is required but was not found. Install it with: $installCommand"
        }

        Write-Warning "Swift was not found; shared Swift tests were skipped. Install it with: $installCommand"
    } else {
        Invoke-NativeCheck "Swift toolchain" {
            & $swiftPath --version
        }

        if (-not $SkipSwiftTests) {
            Write-Host "[check] Microsoft C++ linker"
            if (-not (Enable-MsvcEnvironment)) {
                $buildToolsCommand = "winget install --id Microsoft.VisualStudio.2022.BuildTools --exact"
                throw "Swift tests require Visual Studio Build Tools with the Desktop development with C++ workload. Install it with: $buildToolsCommand"
            }

            Invoke-NativeCheck "cross-platform Swift tests" {
                & $swiftPath test --package-path $repoRoot
            }
        }
    }

    Write-Host "Windows preflight passed. Apple-framework and runtime checks still require macOS."
} finally {
    Pop-Location
}
