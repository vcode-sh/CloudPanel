#!/bin/bash

# Verify all GitHub links work correctly for the dragonflydb folder structure

echo "🔗 Verifying GitHub links for dragonflydb folder..."
echo "================================================="

BASE_URL="https://raw.githubusercontent.com/vcode-sh/CloudPanel/main/dragonflydb"

# Test main installer link
echo -n "Testing installer link... "
if curl -s --head "$BASE_URL/install-dragonfly-cloudpanel.sh" | grep -q "200 OK"; then
    echo "✅ OK"
else
    echo "❌ FAILED"
fi

# Test test script link
echo -n "Testing test script link... "
if curl -s --head "$BASE_URL/test-dragonfly.sh" | grep -q "200 OK"; then
    echo "✅ OK"
else
    echo "❌ FAILED"
fi

echo
echo "📋 Updated commands for users:"
echo "============================="
echo
echo "1. One-line install:"
echo "curl -sSL $BASE_URL/install-dragonfly-cloudpanel.sh | sudo bash"
echo
echo "2. Download and run:"
echo "wget $BASE_URL/install-dragonfly-cloudpanel.sh"
echo "chmod +x install-dragonfly-cloudpanel.sh"
echo "sudo ./install-dragonfly-cloudpanel.sh"
echo
echo "3. Test installation:"
echo "wget $BASE_URL/test-dragonfly.sh"
echo "chmod +x test-dragonfly.sh"
echo "./test-dragonfly.sh"
echo
echo "4. Clone repository:"
echo "git clone https://github.com/vcode-sh/CloudPanel.git"
echo "cd CloudPanel/dragonflydb"
echo "make install"
echo