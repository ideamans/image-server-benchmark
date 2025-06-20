module github.com/ideamans/image-server-benchmark/servers/go/echo

go 1.21

require (
	github.com/ideamans/image-server-benchmark/servers/go/common v0.0.0
	github.com/labstack/echo/v4 v4.11.4
)

require (
	github.com/golang-jwt/jwt v3.2.2+incompatible // indirect
	github.com/joho/godotenv v1.5.1 // indirect
	github.com/labstack/gommon v0.4.2 // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/valyala/bytebufferpool v1.0.0 // indirect
	github.com/valyala/fasttemplate v1.2.2 // indirect
	golang.org/x/crypto v0.17.0 // indirect
	golang.org/x/net v0.19.0 // indirect
	golang.org/x/sys v0.15.0 // indirect
	golang.org/x/text v0.14.0 // indirect
	golang.org/x/time v0.5.0 // indirect
)

replace github.com/ideamans/image-server-benchmark/servers/go/common => ../common
