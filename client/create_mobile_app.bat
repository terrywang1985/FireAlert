
rem 安装vue
npm install -g @vue/cli
vue create my-vue-app

rem 运行
cd my-vue-app
npm run serve


rem 安装打包工具
npm install @capacitor/core @capacitor/cli

npx cap init

npm install @capacitor/ios
npm install @capacitor/android


npx cap add ios
npx cap add android

rem 构建
npm run build

rem 将构建后的文件同步到 iOS 和 Android 平台：
npx cap copy

rem 使用 Xcode 或 Android Studio 打开对应的平台项目进行调试和测试
npx cap open ios
npx cap open android
