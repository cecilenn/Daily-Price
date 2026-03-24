#!/bin/bash
set -e

echo "清理缓存..."
flutter clean
flutter pub get

echo "打包 APK..."
flutter build apk --release --split-per-abi --no-tree-shake-icons

echo "重命名 APK..."
cd build/app/outputs/flutter-apk
for f in *.apk; do
  case "$f" in
    *arm64-v8a*) mv "$f" "cecilenn.dailyprice_v8a.apk" ;;
    *armeabi-v7a*) mv "$f" "cecilenn.dailyprice_v7a.apk" ;;
    *x86_64*) mv "$f" "cecilenn.dailyprice_x64.apk" ;;
    *) mv "$f" "cecilenn.dailyprice.apk" ;;
  esac
done

# SHA1 文件同步改名
for f in *.sha1; do
  case "$f" in
    *arm64-v8a*) mv "$f" "cecilenn.dailyprice_v8a.apk.sha1" ;;
    *armeabi-v7a*) mv "$f" "cecilenn.dailyprice_v7a.apk.sha1" ;;
    *x86_64*) mv "$f" "cecilenn.dailyprice_x64.apk.sha1" ;;
    *) mv "$f" "cecilenn.dailyprice.apk.sha1" ;;
  esac
done


echo "完成！输出文件："
ls -la *.apk