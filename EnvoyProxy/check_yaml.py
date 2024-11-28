import yaml

# 读取文件内容
with open('envoy.yaml', 'r', encoding='utf-8') as file:
    try:
        yaml_content = yaml.safe_load(file)
        print("YAML 文件格式正确")
    except yaml.YAMLError as exc:
        print(f"YAML 文件格式错误: {exc}")