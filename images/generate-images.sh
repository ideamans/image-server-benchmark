#!/bin/bash
# テスト画像生成スクリプト

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_IMAGE="$SCRIPT_DIR/../hina.jpg"

# ソース画像の存在確認
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found: $SOURCE_IMAGE"
    exit 1
fi

# ImageMagickがインストールされているか確認
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it first."
    exit 1
fi

echo "Generating test images from hina.jpg..."

# 最適な設定（実験で見つけた値）
# 20KB: 400x300, quality 50
# 50KB: resize 50%, quality 20  
# 100KB: quality 30

# 一時ファイル用ディレクトリ
TEMP_DIR="$SCRIPT_DIR/temp"
mkdir -p "$TEMP_DIR"

# 画像生成関数
generate_image_with_target_size() {
    local target_size=$1
    local output_file=$2
    local target_bytes=$((target_size * 1024))
    local min_bytes=$((target_bytes * 95 / 100))  # -5%
    local max_bytes=$((target_bytes * 105 / 100))  # +5%
    
    echo "Generating $output_file (target: ${target_size}KB ±5%)..."
    
    # まず適切なリサイズ比率を見つける
    local resize_percent=100
    local quality=85
    
    # 複数の戦略を試す
    # 戦略1: リサイズと品質の組み合わせ
    for resize in 100 80 60 50 40 30 25 20; do
        for q in 90 80 70 60 50 40 30 20 10; do
            # 画像を生成
            magick "$SOURCE_IMAGE" -resize ${resize}% -quality $q "$TEMP_DIR/test.jpg"
            
            # サイズを確認
            local size=$(stat -f%z "$TEMP_DIR/test.jpg" 2>/dev/null || stat -c%s "$TEMP_DIR/test.jpg" 2>/dev/null)
            
            if [ $size -ge $min_bytes ] && [ $size -le $max_bytes ]; then
                # 目標範囲内
                cp "$TEMP_DIR/test.jpg" "$output_file"
                echo "  Success: resize=${resize}%, quality=$q, size=$((size / 1024))KB"
                return 0
            fi
        done
    done
    
    # 戦略2: より細かい調整（20KB専用）
    if [ $target_size -eq 20 ]; then
        # 小さい画像用に解像度も下げる
        for res in "640x480" "480x360" "320x240"; do
            for q in 85 75 65 55 45 35 25; do
                magick "$SOURCE_IMAGE" -resize $res -quality $q "$TEMP_DIR/test.jpg"
                local size=$(stat -f%z "$TEMP_DIR/test.jpg" 2>/dev/null || stat -c%s "$TEMP_DIR/test.jpg" 2>/dev/null)
                
                if [ $size -ge $min_bytes ] && [ $size -le $max_bytes ]; then
                    cp "$TEMP_DIR/test.jpg" "$output_file"
                    echo "  Success: resolution=$res, quality=$q, size=$((size / 1024))KB"
                    return 0
                fi
            done
        done
    fi
    
    # 最後の手段: -define jpeg:extent を使用
    echo "  Trying with jpeg:extent option..."
    magick "$SOURCE_IMAGE" -resize 50% -define jpeg:extent=${target_size}KB "$output_file"
    local final_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
    local final_kb=$((final_size / 1024))
    local error_percent=$(( (final_kb - target_size) * 100 / target_size ))
    if [ $error_percent -lt 0 ]; then
        error_percent=$((-error_percent))
    fi
    
    if [ $error_percent -le 5 ]; then
        echo "  Success: size=${final_kb}KB (error: ${error_percent}%)"
    else
        echo "  Result: size=${final_kb}KB (error: ${error_percent}% - exceeds 5% threshold)"
    fi
}

# 各サイズの画像を生成
generate_image_with_target_size 20 "$SCRIPT_DIR/20k.jpg"
generate_image_with_target_size 50 "$SCRIPT_DIR/50k.jpg"
generate_image_with_target_size 100 "$SCRIPT_DIR/100k.jpg"

# 一時ディレクトリをクリーンアップ
rm -rf "$TEMP_DIR"

# 生成された画像のサイズを確認
echo -e "\nGenerated image sizes:"
for size in 20k 50k 100k; do
    if [ -f "$SCRIPT_DIR/$size.jpg" ]; then
        actual_size=$(stat -f%z "$SCRIPT_DIR/$size.jpg" 2>/dev/null || stat -c%s "$SCRIPT_DIR/$size.jpg" 2>/dev/null)
        actual_kb=$((actual_size / 1024))
        target_kb=${size%k}
        
        # 誤差計算
        diff=$((actual_kb - target_kb))
        if [ $diff -lt 0 ]; then
            diff=$((-diff))
        fi
        error_percent=$((diff * 100 / target_kb))
        
        echo "$size.jpg: ${actual_kb}KB (target: ${target_kb}KB, error: ${error_percent}%)"
        
        # 誤差が5%を超えている場合は警告
        if [ $error_percent -gt 5 ]; then
            echo "  WARNING: Error exceeds 5% threshold!"
        fi
    else
        echo "$size.jpg: Failed to generate"
    fi
done

echo -e "\nImage generation complete!"