set CURRENT_PATH=%cd%
docker run -d -p 8080:8080 -v %CURRENT_PATH%\\envoy.yaml:/etc/envoy/envoy.yaml envoyproxy/envoy:v1.25.0
