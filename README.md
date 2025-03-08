# go-init
一个用于快速初始化 Golang Web 项目的自动化工具。

### 内置包

* github.com/gin-gonic/gin
* github.com/spf13/viper
* github.com/tidwall/gjson
* github.com/coocood/freecache
* github.com/go-resty/resty/v2

### 使用

```bash
# project_name改为你自己的项目名称
curl -s "https://raw.githubusercontent.com/helloxz/go-init/refs/heads/main/init.sh" | bash -s project_name
# 运行
go run main.go start
```

默认端口为`2080`，访问`http://IP:2080`

### 文件说明

* 配置文件：`data/config/config.toml`
* 路由：`router/routers.go`
* 中间件：`middleware`
