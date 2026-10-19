module github.com/prometheus/prometheus

go 1.25.8

require (
	github.com/alecthomas/kingpin/v2 v2.4.0
	github.com/cespare/xxhash/v2 v2.3.0
	github.com/facette/natsort v0.0.0-20181210072756-2cd4dd1e2dcb
	github.com/go-zookeeper/zk v1.0.4
	github.com/golang/snappy v1.0.0
	github.com/google/go-cmp v0.7.0
	github.com/grafana/regexp v0.0.0-20250905093917-f7b3be9d1853
	github.com/json-iterator/go v1.1.12
	github.com/klauspost/compress v1.19.1
	github.com/prometheus/client_golang v1.24.1
	github.com/prometheus/common v0.70.1
	github.com/stretchr/testify v1.11.1
	go.uber.org/atomic v1.11.0
	go.uber.org/goleak v1.3.0
	go.yaml.in/yaml/v2 v2.4.4
	golang.org/x/sys v0.47.0
	golang.org/x/text v0.40.0
)

require (
	github.com/alecthomas/units v0.0.0-20240927000941-0f3dac36c52b // indirect
	github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822 // indirect
	github.com/prometheus/client_model v0.6.2 // indirect
	google.golang.org/protobuf v1.36.12-0.20260120151049-f2248ac996af // indirect
)

require gopkg.in/yaml.v3 v3.0.1 // indirect

require (
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/davecgh/go-spew v1.1.2-0.20180830191138-d8f796af33cc // indirect
	github.com/kr/pretty v0.3.1 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.3-0.20250322232337-35a7c28c31ee // indirect
	github.com/pmezard/go-difflib v1.0.1-0.20181226105442-5d4384ee4fb2 // indirect
	github.com/prometheus/procfs v0.21.1 // indirect
	github.com/rogpeppe/go-internal v1.14.1 // indirect
	github.com/xhit/go-str2duration/v2 v2.1.0 // indirect
	gopkg.in/check.v1 v1.0.0-20201130134442-10cb98267c6c // indirect
)

// Exclude linodego v1.0.0 as it is no longer published on github.
exclude github.com/linode/linodego v1.0.0

// Exclude grpc v1.30.0 because of breaking changes. See #7621.
exclude (
	github.com/grpc-ecosystem/grpc-gateway v1.14.7
	google.golang.org/api v0.30.0
)

replace cloud.google.com/go => cloud.google.com/go v0.123.0
