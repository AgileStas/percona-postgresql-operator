module github.com/percona/percona-postgresql-operator

go 1.15

require (
	github.com/fatih/color v1.9.0
	github.com/go-openapi/errors v0.19.6
	github.com/go-openapi/runtime v0.19.20
	github.com/go-openapi/strfmt v0.19.5
	github.com/go-openapi/swag v0.19.9
	github.com/go-openapi/validate v0.19.10
	github.com/gorilla/mux v1.7.4
	github.com/iancoleman/orderedmap v0.2.0
	github.com/mattn/go-colorable v0.1.6 // indirect
	github.com/nsqio/go-nsq v1.0.8
	github.com/pkg/errors v0.9.1
	github.com/robfig/cron/v3 v3.0.1
	github.com/sirupsen/logrus v1.7.0
	github.com/spf13/cobra v0.0.5
	github.com/spf13/pflag v1.0.5
	github.com/xdg/stringprep v1.0.0
	go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp v0.13.0
	go.opentelemetry.io/otel v0.13.0
	go.opentelemetry.io/otel/exporters/stdout v0.13.0
	go.opentelemetry.io/otel/exporters/trace/jaeger v0.13.0
	golang.org/x/crypto v0.0.0-20210220033148-5ea612d1eb83
	golang.org/x/sync v0.0.0-20201020160332-67f06af15bc9
	gopkg.in/yaml.v2 v2.4.0
	k8s.io/api v0.21.0
	k8s.io/apimachinery v0.21.0
	k8s.io/client-go v0.21.0
	sigs.k8s.io/controller-runtime v0.6.4
	sigs.k8s.io/yaml v1.2.0
)
