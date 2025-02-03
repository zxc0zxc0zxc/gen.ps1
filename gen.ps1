# gen.ps1
<#
.SYNOPSIS
    Boilerplate generator for layered Go services, in the style of Laravel's artisan.
.DESCRIPTION
    Writes a source file and the directory it belongs in, following the project's
    layout conventions.

    Run it from anywhere inside a Go module: the module path is read from go.mod
    so that generated imports are fully qualified.

    Commands:
      make:handler     {Name}  - Gin handler in internal/application/handlers/v1.
      make:request     {Name}  - request DTO in internal/domain/http.
      make:repository  {Name}  - entity, repository interface and implementation.
      make:service     {Name}  - service in internal/application/services.
      make:valueobject {Name}  - value object in internal/domain/valueobjects.

    Existing files are left alone unless -Force is given.
.EXAMPLE
    ./gen.ps1 make:handler Ping
.EXAMPLE
    ./gen.ps1 make:repository Example
.EXAMPLE
    ./gen.ps1 make:service Order -Force
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('make:handler', 'make:request', 'make:repository', 'make:service', 'make:valueobject')]
    [string]$Command,

    # PascalCase, and a valid Go identifier: it is used verbatim for type names.
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
    [string]$Name,

    # Overwrite files that already exist.
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Go source is written without a byte order mark. Out-File -Encoding UTF8 would
# add one on Windows PowerShell 5.1 but not on PowerShell 7, and the difference
# is invisible until something downstream chokes on it.
$script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

# Get-ModulePath returns the module path declared in the nearest go.mod, walking
# up from the working directory. Generated imports are qualified with it, because
# a bare "internal/domain/entities" is not a valid Go import path.
function Get-ModulePath {
    $dir = $PWD.Path
    while ($true) {
        $goMod = Join-Path $dir 'go.mod'
        if (Test-Path -LiteralPath $goMod) {
            $match = Select-String -LiteralPath $goMod -Pattern '^\s*module\s+(\S+)' |
                Select-Object -First 1
            if (-not $match) {
                throw "'$goMod' declares no module path."
            }
            return $match.Matches[0].Groups[1].Value
        }

        $parent = Split-Path -Parent $dir
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $dir) {
            throw "No go.mod found in '$($PWD.Path)' or any parent directory."
        }
        $dir = $parent
    }
}

# ConvertTo-SnakeCase turns OrderItem into order_item, so that file names follow
# Go's convention instead of collapsing into one word.
function ConvertTo-SnakeCase {
    param([string]$Value)

    $out = [regex]::Replace($Value, '(.)([A-Z][a-z]+)', '$1_$2')
    $out = [regex]::Replace($out, '([a-z0-9])([A-Z])', '$1_$2')
    return $out.ToLowerInvariant()
}

function Write-Source {
    param(
        [string]$Path,
        [string]$Content
    )

    if ((Test-Path -LiteralPath $Path) -and -not $script:Force) {
        Write-Warning "Skipped $Path (already exists; pass -Force to overwrite)."
        return
    }

    $dir = Split-Path -Parent $Path
    if ($dir) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $full = [System.IO.Path]::GetFullPath((Join-Path $PWD.Path $Path))
    [System.IO.File]::WriteAllText($full, $Content, $script:Utf8NoBom)
    Write-Host "Created $Path"
}

function New-Handler {
    param([string]$Name)

    Write-Source -Path "internal/application/handlers/v1/$(ConvertTo-SnakeCase $Name)_handler.go" -Content @"
package v1

import (
	"github.com/gin-gonic/gin"
)

type ${Name}Handler struct {
}

func New${Name}Handler() *${Name}Handler {
	return &${Name}Handler{}
}

func (h *${Name}Handler) Handle${Name}(c *gin.Context) {
}
"@
}

function New-Request {
    param([string]$Name)

    Write-Source -Path "internal/domain/http/$(ConvertTo-SnakeCase $Name)_request.go" -Content @"
package http

// Binding tags:
//   required - field must be present.
//   min      - minimum value (numbers) or length (strings).
//   max      - maximum value (numbers) or length (strings).
//   email    - must be a valid email address.
//   uuid     - must be a valid UUID.
//   oneof    - must be one of the listed values.

type ${Name}Request struct {
	// ID int ``json:"id" binding:"required,min=1,max=50"``
}
"@
}

function New-Repository {
    param([string]$Name)

    $module = Get-ModulePath
    $slug = ConvertTo-SnakeCase $Name
    # Parameter name, so that it does not shadow the type it points at.
    $arg = $Name.Substring(0, 1).ToLowerInvariant() + $Name.Substring(1)

    Write-Source -Path "internal/domain/entities/${slug}_entity.go" -Content @"
package entities

type ${Name} struct {
	ID int
}
"@

    Write-Source -Path "internal/domain/repositories/${slug}_repository.go" -Content @"
package repositories

import "$module/internal/domain/entities"

type ${Name}Repository interface {
	Get(id int) (*entities.${Name}, error)
	Create($arg *entities.${Name}) error
}
"@

    # The implementation lives in another package that is also called
    # repositories, so the interface package is imported under an alias.
    Write-Source -Path "internal/infrastructure/repositories/${slug}_repository_impl.go" -Content @"
package repositories

import (
	"$module/internal/domain/entities"
	domain "$module/internal/domain/repositories"
)

type ${Name}RepositoryImpl struct {
}

func New${Name}Repository() domain.${Name}Repository {
	return &${Name}RepositoryImpl{}
}

func (r *${Name}RepositoryImpl) Get(id int) (*entities.${Name}, error) {
	// TODO
	return nil, nil
}

func (r *${Name}RepositoryImpl) Create($arg *entities.${Name}) error {
	// TODO
	return nil
}
"@
}

function New-Service {
    param([string]$Name)

    Write-Source -Path "internal/application/services/$(ConvertTo-SnakeCase $Name)_service.go" -Content @"
package services

type ${Name}Service struct {
}

func New${Name}Service() *${Name}Service {
	return &${Name}Service{}
}

func (s *${Name}Service) Handle() string {
	return "Called from ${Name} service"
}
"@
}

function New-ValueObject {
    param([string]$Name)

    Write-Source -Path "internal/domain/valueobjects/$(ConvertTo-SnakeCase $Name).go" -Content @"
package valueobjects

import "errors"

type ${Name} struct {
	value string
}

func New${Name}(value string) (${Name}, error) {
	if len(value) == 0 {
		return ${Name}{}, errors.New("value is empty")
	}

	return ${Name}{value: value}, nil
}

func (v ${Name}) String() string {
	return v.value
}
"@
}

switch ($Command) {
    'make:handler' { New-Handler -Name $Name }
    'make:request' { New-Request -Name $Name }
    'make:repository' { New-Repository -Name $Name }
    'make:service' { New-Service -Name $Name }
    'make:valueobject' { New-ValueObject -Name $Name }
    default {
        Write-Error "Unknown command: $Command"
        exit 1
    }
}
