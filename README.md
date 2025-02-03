# gen.ps1

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Go](https://img.shields.io/badge/Go-1.21%2B-00ADD8?logo=go&logoColor=white)](https://go.dev/)
[![Gin](https://img.shields.io/badge/Gin-handlers-008ECF?logo=gin&logoColor=white)](https://gin-gonic.com/)
[![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)](#requirements)

Artisan-style boilerplate generator for layered Go services. One PowerShell
script, no install step: it writes the file and the directory it belongs in, so
a new handler or service is one command instead of five minutes of copy-paste.

## Usage

```powershell
./gen.ps1 <command> <Name> [-Force]
```

`Name` is used verbatim for Go identifiers and converted to snake_case for file
names, so pass it in PascalCase: `OrderItem` becomes `order_item_entity.go`.

| Command | Writes | Contains |
|---|---|---|
| `make:handler {Name}` | `internal/application/handlers/v1/{name}_handler.go` | Gin handler struct and constructor |
| `make:request {Name}` | `internal/domain/http/{name}_request.go` | request DTO, with binding-tag cheatsheet |
| `make:service {Name}` | `internal/application/services/{name}_service.go` | service struct and constructor |
| `make:valueobject {Name}` | `internal/domain/valueobjects/{name}.go` | value object with a validating constructor |
| `make:repository {Name}` | `internal/domain/entities/{name}_entity.go`<br>`internal/domain/repositories/{name}_repository.go`<br>`internal/infrastructure/repositories/{name}_repository_impl.go` | entity, repository interface, implementation |

```powershell
./gen.ps1 make:handler Ping
./gen.ps1 make:service Order
./gen.ps1 make:repository Example
```

## Target layout

The generated paths assume a domain-centric layout, with the interface owned by
the domain and its implementation kept in infrastructure:

```
internal/
├── application/
│   ├── handlers/v1/     transport
│   └── services/        use cases
├── domain/
│   ├── entities/        models
│   ├── http/            request DTOs
│   ├── repositories/    repository interfaces
│   └── valueobjects/    validated primitives
└── infrastructure/
    └── repositories/    repository implementations
```

## Requirements

PowerShell 5.1 or newer — Windows PowerShell or [PowerShell 7](https://github.com/PowerShell/PowerShell)
on macOS and Linux. Nothing else; the script uses only built-in cmdlets.

Run it from inside the target Go module. `make:repository` reads the module path
from the nearest `go.mod` so that the generated imports are fully qualified.

Handlers import [gin-gonic/gin](https://github.com/gin-gonic/gin); add it to the
target project yourself:

```sh
go get github.com/gin-gonic/gin
```

## Notes

Existing files are left alone and reported as skipped; pass `-Force` to
overwrite them. Files are written as UTF-8 without a BOM on every host.
