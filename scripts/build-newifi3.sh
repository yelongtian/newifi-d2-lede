#!/bin/bash

# Newifi D2 (新路由3) 快速编译脚本
# 用于快速编译适配 Newifi D2 的 LEDE 固件

set -e

echo "========================================="
echo "Newifi D2 固件快速编译脚本"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否在正确的目录
if [ ! -f "Makefile" ] || [ ! -d "target/linux/ramips" ]; then
    echo -e "${RED}错误: 请在 LEDE 源码根目录下运行此脚本${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 当前目录正确${NC}"
echo ""

# 步骤1: 更新 feeds
echo -e "${BLUE}[1/5] 更新 feeds...${NC}"
./scripts/feeds update -a
./scripts/feeds install -a
echo -e "${GREEN}✓ Feeds 更新完成${NC}"
echo ""

# 步骤2: 配置编译选项
echo -e "${BLUE}[2/5] 配置编译选项...${NC}"
make defconfig
echo "CONFIG_TARGET_ramips=y" >> .config
echo "CONFIG_TARGET_ramips_mt7621=y" >> .config
echo "CONFIG_TARGET_ramips_mt7621_DEVICE_d-team_newifi-d2=y" >> .config
echo "CONFIG_IPV6=y" >> .config
make defconfig
echo -e "${GREEN}✓ 编译配置完成${NC}"
echo ""

# 步骤3: 下载依赖包
echo -e "${BLUE}[3/5] 下载依赖包...${NC}"
make download -j8
# 删除空文件
find dl -size -1024c -exec rm -f {} \;
echo -e "${GREEN}✓ 依赖包下载完成${NC}"
echo ""

# 步骤4: 编译固件
echo -e "${BLUE}[4/5] 编译固件...${NC}"
echo "这可能需要 2-3 小时，请耐心等待..."
echo ""

# 使用多线程编译，失败则降级到单线程
if ! make -j$(nproc) V=s; then
    echo -e "${YELLOW}多线程编译失败，尝试单线程编译...${NC}"
    make -j1 V=s
fi

echo -e "${GREEN}✓ 固件编译完成${NC}"
echo ""

# 步骤5: 验证固件
echo -e "${BLUE}[5/5] 验证固件...${NC}"
if [ -f "scripts/verify-firmware.sh" ]; then
    bash scripts/verify-firmware.sh
else
    echo -e "${YELLOW}验证脚本不存在，跳过验证${NC}"
fi
echo ""

# 显示编译结果
echo "========================================="
echo -e "${GREEN}编译完成！${NC}"
echo "========================================="
echo ""

FIRMWARE_FILE="bin/targets/ramips/mt7621/openwrt-ramips-mt7621-d-team_newifi-d2-squashfs-sysupgrade.bin"

if [ -f "$FIRMWARE_FILE" ]; then
    FIRMWARE_SIZE=$(stat -c%s "$FIRMWARE_FILE")
    FIRMWARE_SIZE_MB=$(echo "scale=2; $FIRMWARE_SIZE / 1024 / 1024" | bc)
    echo -e "${GREEN}固件文件: $FIRMWARE_FILE${NC}"
    echo -e "${GREEN}固件大小: ${FIRMWARE_SIZE_MB} MB${NC}"
    echo ""
    echo "MD5:    $(md5sum "$FIRMWARE_FILE" | cut -d' ' -f1)"
    echo "SHA256: $(sha256sum "$FIRMWARE_FILE" | cut -d' ' -f1)"
    echo ""
    echo "您现在可以将固件刷写到设备。"
    echo "请参阅 NEWIFI3_BUILD_GUIDE.md 了解刷写方法。"
else
    echo -e "${RED}错误: 固件文件未找到${NC}"
    echo "请检查编译日志以了解详情。"
    exit 1
fi
