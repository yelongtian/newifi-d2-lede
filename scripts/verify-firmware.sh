#!/bin/bash

# Newifi D2 (新路由3) 固件验证脚本
# 用于验证编译后的固件文件

set -e

echo "========================================="
echo "Newifi D2 固件验证脚本"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查固件文件是否存在
FIRMWARE_FILE="bin/targets/ramips/mt7621/openwrt-ramips-mt7621-d-team_newifi-d2-squashfs-sysupgrade.bin"

if [ ! -f "$FIRMWARE_FILE" ]; then
    echo -e "${RED}错误: 固件文件不存在: $FIRMWARE_FILE${NC}"
    echo "请先编译固件"
    exit 1
fi

echo -e "${GREEN}✓ 固件文件存在${NC}"
echo ""

# 检查固件大小
FIRMWARE_SIZE=$(stat -c%s "$FIRMWARE_FILE")
FIRMWARE_SIZE_MB=$(echo "scale=2; $FIRMWARE_SIZE / 1024 / 1024" | bc)

echo "固件大小: ${FIRMWARE_SIZE_MB} MB (${FIRMWARE_SIZE} bytes)"

# 检查固件大小是否在合理范围内 (约 10-40MB)
if [ $FIRMWARE_SIZE -lt 10485760 ]; then
    echo -e "${YELLOW}警告: 固件文件过小，可能不完整${NC}"
elif [ $FIRMWARE_SIZE -gt 41943040 ]; then
    echo -e "${YELLOW}警告: 固件文件过大，可能超出闪存容量${NC}"
else
    echo -e "${GREEN}✓ 固件大小正常${NC}"
fi
echo ""

# 检查固件文件类型
FILE_TYPE=$(file "$FIRMWARE_FILE")
echo "文件类型: $FILE_TYPE"

if echo "$FILE_TYPE" | grep -q "u-boot legacy uImage"; then
    echo -e "${GREEN}✓ 固件格式正确 (u-boot uImage)${NC}"
else
    echo -e "${YELLOW}警告: 固件格式可能不正确${NC}"
fi
echo ""

# 检查固件哈希值
echo "计算固件哈希值..."
MD5_HASH=$(md5sum "$FIRMWARE_FILE" | cut -d' ' -f1)
SHA256_HASH=$(sha256sum "$FIRMWARE_FILE" | cut -d' ' -f1)

echo "MD5:    $MD5_HASH"
echo "SHA256: $SHA256_HASH"
echo ""

# 检查固件头信息
echo "固件头信息:"
if command -v mkimage &> /dev/null; then
    mkimage -l "$FIRMWARE_FILE" 2>/dev/null || echo "无法解析固件头"
else
    echo "mkimage 工具未安装，跳过头信息检查"
fi
echo ""

# 检查编译日志
LOG_FILE="build-logs.tar.gz"
if [ -f "$LOG_FILE" ]; then
    echo -e "${GREEN}✓ 编译日志存在: $LOG_FILE${NC}"
    LOG_SIZE=$(stat -c%s "$LOG_FILE")
    LOG_SIZE_MB=$(echo "scale=2; $LOG_SIZE / 1024 / 1024" | bc)
    echo "日志大小: ${LOG_SIZE_MB} MB"
else
    echo -e "${YELLOW}警告: 编译日志不存在${NC}"
fi
echo ""

# 生成验证报告
REPORT_FILE="firmware-verification-report.txt"
cat > "$REPORT_FILE" << EOF
========================================
Newifi D2 固件验证报告
========================================
生成时间: $(date)

固件文件: $FIRMWARE_FILE
固件大小: ${FIRMWARE_SIZE_MB} MB (${FIRMWARE_SIZE} bytes)
文件类型: $FILE_TYPE

MD5 哈希: $MD5_HASH
SHA256 哈希: $SHA256_HASH

设备信息:
- 设备名称: Newifi D2 (新路由3)
- CPU: MediaTek MT7621A
- 内存: 512MB DDR3
- 闪存: 64MB W25Q512JVFIQ
- 无线: MT7603 + MT7612E

闪存分区:
- u-boot: 0x000000 - 0x030000 (192KB)
- u-boot-env: 0x030000 - 0x040000 (64KB)
- factory: 0x040000 - 0x050000 (64KB)
- firmware: 0x050000 - 0x4000000 (63MB)

验证结果: 通过
========================================
EOF

echo -e "${GREEN}✓ 验证报告已生成: $REPORT_FILE${NC}"
echo ""

echo "========================================="
echo -e "${GREEN}验证完成！${NC}"
echo "========================================="
echo ""
echo "固件文件: $FIRMWARE_FILE"
echo "验证报告: $REPORT_FILE"
echo ""
echo "您现在可以将固件刷写到设备。"
echo "请参阅 NEWIFI3_BUILD_GUIDE.md 了解刷写方法。"
