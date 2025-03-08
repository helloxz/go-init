#!/bin/bash

# 获取用户输入的项目名称
PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
  echo "The project name cannot be empty, please re-run the script and enter a valid project name!"
  exit 1
fi

# 创建项目目录
#mkdir -p $PROJECT_NAME
#cd $PROJECT_NAME

# 初始化 Go 模块
go mod init $PROJECT_NAME

# 创建所需的文件夹
mkdir -p api assets middleware model router utils data/config

# 创建 main.go 文件
cat <<EOF > main.go
package main

import (
    "fmt"
    "os"
    "$PROJECT_NAME/router"
    "$PROJECT_NAME/utils"
)

func main() {
    // 获取命令行参数
    args := os.Args
    // 获取切片长度
    args_len := len(args)

    // 如果参数是1，则没有额外参数
    if args_len == 1 {
        fmt.Printf("Please enter the parameters!\n")
        os.Exit(0)
    } else if args_len == 2 {
        // 启动程序
        if args[1] == "start" {
            // 加载配置
            utils.InitConfig()
            // 启动 Gin
            router.Start()
        } else {
            fmt.Printf("Please enter the correct parameters!\n")
            os.Exit(0)
        }
    }
}
EOF

# 创建 router/routers.go 文件
cat <<EOF > router/routers.go
package router

import (
    "$PROJECT_NAME/middleware"
    "$PROJECT_NAME/api"
    "github.com/gin-gonic/gin"
    "github.com/spf13/viper"
)

func Start() {
    // gin 运行模式
    RunMode := viper.GetString("server.mode")
    // 设置运行模式
    gin.SetMode(RunMode)
    // 运行 gin
    r := gin.Default()
    // 全局跨域中间件
    r.Use(middleware.CORSMiddleware())
    r.GET("/", api.Home)

    // 前台首页
    // 获取服务端配置
    port := ":" + viper.GetString("server.port")
    // 运行服务
    r.Run(port)
}
EOF

# 创建 middleware/cors.go 文件
cat <<EOF > middleware/cors.go
package middleware

import (
    "net/http"

    "github.com/gin-gonic/gin"
)

func CORSMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
        c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
        c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Authorization, Accept, X-Requested-With")
        c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(http.StatusNoContent)
            return
        }

        c.Next()
    }
}
EOF

# 创建 api/home.go 文件
cat <<EOF > api/home.go
package api

import (
    "net/http"

    "github.com/gin-gonic/gin"
)

func Home(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "message": "Hello, World!",
    })
}
EOF

# 创建 data/config/config.toml 文件
cat <<EOF > data/config/config.toml
[server]
mode = 'debug'
port = 2080
EOF

# 创建 utils/config.go 文件
cat <<EOF > utils/config.go
package utils

import (
    "fmt"
    "io"
    "math/rand"
    "os"
    "strings"
    "sync"
    "time"

    "github.com/spf13/viper"
)

var (
    once sync.Once
)

// 全局就一个 init 函数，避免其它地方再次声明，以免逻辑容易出错
func InitConfig() {
    once.Do(func() {
        // 创建必要的目录
        CreateDir("data/config")
        CreateDir("data/db")
        CreateDir("data/logs")

        // 默认配置文件
        config_file := "data/config/config.toml"
        // 检查配置文件是否存在，不存在则复制一份
        if _, err := os.Stat(config_file); os.IsNotExist(err) {
            // 创建目录
            os.MkdirAll("data/config", os.ModePerm)
            // 复制配置文件
            err := CopyFile("config.toml", config_file)
            if err != nil {
                fmt.Println("Failed to copy config file:", err)
                os.Exit(1)
            }
        }

        viper.SetConfigFile(config_file) // 指定配置文件路径
        // 指定 ini 类型的文件
        viper.SetConfigType("toml")
        err := viper.ReadInConfig() // 读取配置信息
        if err != nil {             // 读取配置信息失败
            // 写入日志
            fmt.Println("Failed to read config:", err)
            os.Exit(1)
        }
    })
}

// 初始化密钥
func InitToken() {
    // 获取密钥
    token := viper.GetString("auth.token")
    // 如果密钥为空
    if token == "" {
        tokenStr := "sk-" + RandString(29)
        // 设置密钥
        viper.Set("auth.token", tokenStr)
        // 写入配置
        err := viper.WriteConfig()
        if err != nil {
            fmt.Println("Failed to init token:", err)
        }
    }
}

// 生成一个随机字符串
func RandString(length int) string {
    // 定义字符集
    charset := "abcdefghijklmnopqrstuvwxyz0123456789"
    // 将字符集转换为 rune 切片，以便随机选择字符
    charsetRunes := []rune(charset)

    // 创建一个 strings.Builder，用于高效构建字符串
    var sb strings.Builder
    // 设置 strings.Builder 的初始容量，避免频繁扩容
    sb.Grow(length)

    // 使用当前时间作为随机数种子，确保每次运行生成不同的随机字符串
    rand.Seed(time.Now().UnixNano())

    // 循环生成随机字符，并添加到 strings.Builder 中
    for i := 0; i < length; i++ {
        // 从字符集中随机选择一个字符
        randomIndex := rand.Intn(len(charsetRunes))
        randomChar := charsetRunes[randomIndex]
        // 将随机字符添加到 strings.Builder 中
        sb.WriteRune(randomChar)
    }

    // 返回生成的随机字符串
    return sb.String()
}

// CopyFile 复制文件内容
func CopyFile(src, dst string) error {
    sourceFile, err := os.Open(src)
    if err != nil {
        return err
    }
    defer sourceFile.Close()

    destFile, err := os.Create(dst)
    if err != nil {
        return err
    }
    defer destFile.Close()

    _, err = io.Copy(destFile, sourceFile)
    return err
}

// 接收一个路径作为参数，判断路径是否存在，不存在则创建
func CreateDir(path string) error {
    if _, err := os.Stat(path); os.IsNotExist(err) {
        err := os.MkdirAll(path, 0755)
        if err != nil {
            return fmt.Errorf("无法创建目录：%w", err)
        }
    }
    return nil
}
EOF

# 安装依赖包
go get github.com/gin-gonic/gin
go get github.com/spf13/viper
go get -u github.com/tidwall/gjson
go get github.com/coocood/freecache
go get github.com/go-resty/resty/v2

go mod tidy

# 输出完成信息
echo "项目 '$PROJECT_NAME' 已成功创建！"
echo "运行以下命令启动项目："
echo "cd $PROJECT_NAME && go run main.go start"
