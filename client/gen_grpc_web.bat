..\\FireAlert\\tools\\GrpcClientApp\\protoc.exe -I=..\\FireAlert\\proto ..\\FireAlert\\proto\\chat.proto --js_out=import_style=commonjs:. --grpc-web_out=import_style=typescript,mode=grpcwebtext:.

npx grpc_tools_node_protoc -I=..\\..\\FireAlert\\proto --js_out=import_style=commonjs:. --grpc-web_out=import_style=typescript,mode=grpcwebtext:. ..\\..\\FireAlert\\proto\\chat.proto
