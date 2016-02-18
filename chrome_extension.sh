#!/bin/bash

echo About to create a chrome extension
rm -rf pnacl_${BUILD_NUMBER}.zip

mkdir -p pnacl_${BUILD_NUMBER}

cp -rf iguana/manifest.json pnacl_${BUILD_NUMBER}/
cp -f iguana/pnacl/Release/iguana.pexe pnacl_${BUILD_NUMBER}/
cp -rf confs/* pnacl_${BUILD_NUMBER}/
cp -rf iguana/icon128.png pnacl_${BUILD_NUMBER}/
cp -rf *.html pnacl_${BUILD_NUMBER}/
cp -rf LEGAL/** pnacl_${BUILD_NUMBER}/
cp -rf css/** pnacl_${BUILD_NUMBER}/
cp -rf js/** pnacl_${BUILD_NUMBER}/

echo Listing the contents of pnacl_${BUILD_NUMBER}
ls -al pnacl_${BUILD_NUMBER}/

#echo Zipping now
#zip -r pnacl_${BUILD_NUMBER}.zip pnacl_${BUILD_NUMBER}/


# Purpose: Pack a Chromium extension directory into crx format
cp pnacl.pem pnacl_${BUILD_NUMBER}.pem

dir=pnacl_${BUILD_NUMBER}
key=pnacl_${BUILD_NUMBER}.pem

name=$(basename "$dir")
crx="$name.crx"
pub="$name.pub"
sig="$name.sig"
zip="$name.zip"
trap 'rm -f "$pub" "$sig" "$zip"' EXIT

# zip up the crx dir
cwd=$(pwd -P)
(cd "$dir" && zip -qr -9 -X "$cwd/$zip" .)

# signature
openssl sha1 -sha1 -binary -sign "$key" < "$zip" > "$sig"

# public key
openssl rsa -pubout -outform DER < "$key" > "$pub" 2>/dev/null

byte_swap () {
  # Take "abcdefgh" and return it as "ghefcdab"
  echo "${1:6:2}${1:4:2}${1:2:2}${1:0:2}"
}

crmagic_hex="4372 3234" # Cr24
version_hex="0200 0000" # 2
pub_len_hex=$(byte_swap $(printf '%08x\n' $(ls -l "$pub" | awk '{print $5}')))
sig_len_hex=$(byte_swap $(printf '%08x\n' $(ls -l "$sig" | awk '{print $5}')))
(
  echo "$crmagic_hex $version_hex $pub_len_hex $sig_len_hex" | xxd -r -p
  cat "$pub" "$sig" "$zip"
) > "$crx"
echo "Wrote $crx"

