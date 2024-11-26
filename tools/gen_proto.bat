go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
set PATH=%PATH%;%GOPATH%\bin
GrpcClientApp\protoc.exe --go_out=. --go-grpc_out=. --proto_path=../proto/ chat.proto