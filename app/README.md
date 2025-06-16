# Kids info app

A Flutter app for kids information.

## Download assets

### Images

Download images from Google Drive and extract not to minimize GitHub repository size.

```bash
cd assets
wget –no-check-certificate \
'https://docs.google.com/uc?export=download&id=1PdIo1sVLobOiXIe1n0GpE36BSoNgoC0d' \
-O images.tar.gz
mkdir -p images
tar -zxvf images.tar.gz -C images
rm images.tar.gz
```

## Deploy

### Android

```bash
flutter build appbundle
```

### iOS
```bash
flutter build ipa
```