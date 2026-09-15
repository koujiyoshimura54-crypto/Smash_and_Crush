$ErrorActionPreference = 'Stop'
$projectAuditRoot = 'C:\Users\kouji\Smash_and_Crush'
$auditEvidenceRoot = Join-Path $projectAuditRoot 'reports\Implementation_Audit_20260915'
$legacyReportRoot = Join-Path $projectAuditRoot 'reports\World1_Stage6_10_20260915'
$utf8Audit = New-Object System.Text.UTF8Encoding($false)
$sourceManifest = @(Get-ChildItem -LiteralPath (Join-Path $auditEvidenceRoot 'sources') -Filter '*.luau' -File | Sort-Object Name | ForEach-Object {
  [pscustomobject]@{InstancePath=$_.BaseName; RelativeFile=('sources/' + $_.Name); Bytes=$_.Length; SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
if ($sourceManifest.Count -ne 123) { throw "Expected 123 source snapshots" }
[System.IO.File]::WriteAllText((Join-Path $auditEvidenceRoot 'source_manifest.json'), (ConvertTo-Json -InputObject $sourceManifest -Depth 5), $utf8Audit)
$filesToValidate = @('AGENTS.md','README.md','docs\GAME_SPEC.md','docs\BALANCE_SPEC.md','docs\UI_SPEC.md','docs\DEV_STATUS.md','docs\CHANGELOG.md','reports\Implementation_Audit_20260915\audit_summary.md')
$brokenLinks = @()
$replacementChars = @()
$linkCount = 0
foreach ($rel in $filesToValidate) {
  $full = Join-Path $projectAuditRoot $rel
  $body = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
  if ($body.Contains([string][char]0xFFFD)) { $replacementChars += $rel }
  $links = [regex]::Matches($body, '\[[^\]]*\]\(([^)]+)\)')
  foreach ($link in $links) {
    $target = $link.Groups[1].Value.Split('#')[0]
    if (!$target -or $target -match '^[a-zA-Z]+://') { continue }
    $resolved = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $full -Parent) $target))
    $linkCount++
    if (!(Test-Path -LiteralPath $resolved)) {
      # validation.json is the output of this script.
      if ($resolved -ne (Join-Path $auditEvidenceRoot 'validation.json')) {
        $brokenLinks += [pscustomobject]@{File=$rel;Target=$target}
      }
    }
  }
}
$relocation = Get-Content -LiteralPath (Join-Path $auditEvidenceRoot 'report_relocation_sha256.json') -Encoding UTF8 -Raw | ConvertFrom-Json
$relocationMismatch = @()
foreach ($r in $relocation) {
  $dest = Join-Path $legacyReportRoot $r.RelativePath
  if (!(Test-Path -LiteralPath $dest) -or (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash -ne $r.SHA256) { $relocationMismatch += $r.RelativePath }
}
$current = @(Import-Csv -LiteralPath (Join-Path $auditEvidenceRoot 'current_balance.csv'))
$csvProblems = @()
$required = @(9000,25000,60000,130000,250000)
for ($i=0; $i -lt 5; $i++) {
  $r = $current | Where-Object { [int]$_.Stage -eq (6+$i) }
  if (!$r -or [double]$r.RequiredStrength -ne $required[$i] -or [int]$r.RecommendedLevel -ne (30+5*$i) -or [double]$r.BossMaxHP -ne (5*$required[$i])) { $csvProblems += "Stage$($i+6) base" }
  $ratios = @(2,2.5,3,4)
  for ($j=1; $j -le 4; $j++) {
    if ([double]$r."Wall$j" -ne ($required[$i]*$ratios[$j-1])) { $csvProblems += "Stage$($i+6) Wall$j" }
  }
}
$statusBody = [System.IO.File]::ReadAllText((Join-Path $projectAuditRoot 'docs\DEV_STATUS.md'), [System.Text.Encoding]::UTF8)
$missingSections = @('Completed','In Progress','Next','Known Issues','Deferred','Do Not Change Without Confirmation') | Where-Object { $statusBody -notmatch ('(?m)^## ' + [regex]::Escape($_) + '\r?$') }
$comparison = Get-Content -LiteralPath (Join-Path $auditEvidenceRoot 'comparison.json') -Encoding UTF8 -Raw | ConvertFrom-Json
$result = [pscustomobject]@{
  Date='2026-09-15'
  DocumentsChecked=$filesToValidate.Count
  LinksChecked=$linkCount
  BrokenLinks=@($brokenLinks)
  ReplacementCharacterFiles=@($replacementChars)
  SourceSnapshotCount=$sourceManifest.Count
  RelocatedFileCount=$relocation.Count
  RelocationHashMismatches=@($relocationMismatch)
  BalanceRows=$current.Count
  BalanceProblems=@($csvProblems)
  MissingStatusSections=@($missingSections)
  StudioScriptCount=$comparison.fingerprints.ScriptCountAfter
  StudioFingerprintDifferences=@($comparison.fingerprints.Differences)
  StudioObjectRecords=$comparison.selectedObjects.RecordsAfter
  StudioObjectDifferences=@($comparison.selectedObjects.Differences)
  PlayRunThisAudit=$false
  ActiveGitignoreCreated=(Test-Path -LiteralPath (Join-Path $projectAuditRoot '.gitignore'))
  ProjectGitDirectoryPresent=(Test-Path -LiteralPath (Join-Path $projectAuditRoot '.git'))
}
[System.IO.File]::WriteAllText((Join-Path $auditEvidenceRoot 'validation.json'), (ConvertTo-Json -InputObject $result -Depth 8), $utf8Audit)
$result | ConvertTo-Json -Depth 8
if ($brokenLinks.Count -or $replacementChars.Count -or $relocationMismatch.Count -or $csvProblems.Count -or @($missingSections).Count) { exit 1 }
