# gen.ps1
<#
.SYNOPSIS
    Universal template generator for Go projects, similar to Laravel's artisan.
.DESCRIPTION
    This script generates template files based on commands.
    Supported commands:
      - make:handler {Name}        - Creates {name}_handler.go in internal/application/handlers/v1.
      - make:request {Name}        - Creates {name}_request.go in internal/domain/http.
      - make:repository {Name}     - Creates entity, repository interface, and repository implementation files.
      - make:service {Name}        - Creates {name}_service.go in internal/application/services.
      - make:valueobject {Name}    - Creates {name}.go in internal/domain/valueobjects.
.EXAMPLES
    ./gen.ps1 make:handler Ping
    ./gen.ps1 make:request Order
    ./gen.ps1 make:repository Example
    ./gen.ps1 make:service Example
    ./gen.ps1 make:valueobject Example
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Command,

    [Parameter(Position = 1, Mandatory = $true)]
    [string]$Arg
)

function Generate-Handler {
    param([string]$Name)
    $dir = "internal/application/handlers/v1"
    $lowerName = $Name.ToLower()
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $fileName = "$dir/${lowerName}_handler.go"
    @"
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
"@ | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "File '$fileName' created successfully."
}

function Generate-Request {
    param([string]$Name)
    $dir = "internal/domain/http"
    $lowerName = $Name.ToLower()
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $fileName = "$dir/${lowerName}_request.go"
    @"
package http

// required - field is required.
// min - minimum value (for numbers) or minimum length (for strings).
// max - maximum value (for numbers) or maximum length (for strings).
// email - validates that the string is a proper email.
// uuid - validates that the string is a proper UUID.
// oneof - the value should be one of the specified options.

type ${Name}Request struct {
	// Id int `json:"id" binding:"required,min=1,max=50"`
}
"@ | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "File '$fileName' created successfully."
}

function Generate-Repository {
    param([string]$Name)
    $lowerName = $Name.ToLower()
    $entityDir = "internal/domain/entities"
    $repoDir = "internal/domain/repositories"
    $repoImplDir = "internal/infrastructure/repositories"

    New-Item -ItemType Directory -Force -Path $entityDir, $repoDir, $repoImplDir | Out-Null

    "$entityDir/${lowerName}_entity.go" | Out-File -FilePath `
    "$entityDir/${lowerName}_entity.go" -Encoding UTF8 -InputObject @"
package entities

type ${Name} struct {
	Id int
}
"@
    "$repoDir/${lowerName}_repository.go" | Out-File -FilePath `
    "$repoDir/${lowerName}_repository.go" -Encoding UTF8 -InputObject @"
package repositories

import "internal/domain/entities"

type ${Name}Repository interface {
	Get(id int) (*entities.${Name}, error)
	Create${Name}(${Name} *entities.${Name}) error
}
"@
    "$repoImplDir/${lowerName}_repository_impl.go" | Out-File -FilePath `
    "$repoImplDir/${lowerName}_repository_impl.go" -Encoding UTF8 -InputObject @"
package repositories

type ${Name}RepositoryImpl struct {
}

func New${Name}Repository() ${Name}Repository {
	return &${Name}RepositoryImpl{}
}

func (r *${Name}RepositoryImpl) Get(id int) (*${Name}, error) {
	// TODO
	return nil, nil
}

func (r *${Name}RepositoryImpl) Create(${Name} *${Name}) error {
	// TODO
	return nil
}
"@
    Write-Host "Repository files for '$Name' created successfully."
}

function Generate-Service {
    param([string]$Name)
    $dir = "internal/application/services"
    $lowerName = $Name.ToLower()
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $fileName = "$dir/${lowerName}_service.go"
    @"
package services

type ${Name}Service struct {
}

func New${Name}Service() *${Name}Service {
	return &${Name}Service{}
}

func (service *${Name}Service) Handle() string {
	return "Called from ${Name} service"
}
"@ | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "File '$fileName' created successfully."
}

function Generate-ValueObject {
    param([string]$Name)
    $dir = "internal/domain/valueobjects"
    $lowerName = $Name.ToLower()
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $fileName = "$dir/${lowerName}.go"
    @"
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
"@ | Out-File -FilePath $fileName -Encoding UTF8
    Write-Host "File '$fileName' created successfully."
}

switch ($Command) {
    "make:handler"      { Generate-Handler -Name $Arg }
    "make:request"      { Generate-Request -Name $Arg }
    "make:repository"   { Generate-Repository -Name $Arg }
    "make:service"      { Generate-Service -Name $Arg }
    "make:valueobject"  { Generate-ValueObject -Name $Arg }
    default             { Write-Error "Unknown command: $Command" }
}
