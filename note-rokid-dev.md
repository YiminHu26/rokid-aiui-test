Rokid Sprite Enterprise SDK文档
https://x-docs.rokid.com/docs/


Rokid AR眼镜在工业维修领域的应用实践：智能装配指导系统开发全流程
https://forum.rokid.com/post/detail/2507


灵眸AR企业平台
https://ar-center.rokid.com/
公司名：  
用户名:  
密码：


Rokid学院
https://open.rokid.com/academy



---------------------------------------
Rokid Sprite Enterprise SDK概览
https://x-docs.rokid.com/docs/terminal-sdk/getting-started/%E6%8E%A5%E5%85%A5%E6%8C%87%E5%8D%97.html
- P2P 通信说明
https://x-docs.rokid.com/docs/terminal-sdk/getting-started/%E6%8E%A5%E5%85%A5%E6%8C%87%E5%8D%97.html#p2p-%E9%80%9A%E4%BF%A1%E8%AF%B4%E6%98%8E
- 配置ADB环境
https://x-docs.rokid.com/docs/terminal-sdk/resources/%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C%E4%B8%8E%E5%B8%B8%E7%94%A8%E8%B5%84%E6%96%99.html#%E9%85%8D%E7%BD%AE-adb-%E7%8E%AF%E5%A2%83
- 有线投屏scrcpy
https://x-docs.rokid.com/docs/terminal-sdk/resources/%E6%9C%89%E7%BA%BF%E6%8A%95%E5%B1%8F.html
- 快速开始
https://x-docs.rokid.com/docs/terminal-sdk/getting-started/%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B.html




---
## SDK开发上手
- [安装Android Studio](https://developer.android.google.cn/studio?hl=zh-cn)
- 下载Rokid Sprite Enterprise SDK的[demo](https://x-docs.rokid.com/docs/downloads/demo-guide.html)， 包含手机端和眼镜端两个工程
- 在Android Studio中打开这两个工程，系统会自动下载环境依赖
- [配置adb环境](https://x-docs.rokid.com/docs/terminal-sdk/resources/%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C%E4%B8%8E%E5%B8%B8%E7%94%A8%E8%B5%84%E6%96%99.html#%E9%85%8D%E7%BD%AE-adb-%E7%8E%AF%E5%A2%83)
 - 将platforms-tools目录加入系统环境变量PATH (Windows：此电脑-属性-高级系统设置-环境变量-Path-编辑-新建，常见目录路径是
```
# Windows 示例
C:\Users\<你的用户名>\AppData\Local\Android\Sdk\platform-tools
```
 - 命令行中运行以下代码，确认是否有应答
```
adb version


# 正确的回答
# Android Debug Bridge version 1.0.41
# Version 37.0.1-15733141
# Installed as C:\Users\<Username>\AppData\Local\Android\Sdk\platform-tools\adb.exe # Running on Windows 10.0.19045   
```
 - 如果显示Version没有>37，则需要在Setting-SDK Manager-SDK Platforms里安装Android 17.0
 - 查询连接上的设备
```
adb devices
# 现在如果还没连上设备，则应该输出
# List of devices attached 


```
- [配置scrcpy](https://x-docs.rokid.com/docs/terminal-sdk/resources/%E6%9C%89%E7%BA%BF%E6%8A%95%E5%B1%8F.html), 从[repo](https://github.com/Genymobile/scrcpy)中下载zip，解压（我这里把它移到了 C:\Users\<Username>\AppData\Local\下)，配置环境变量（Path添加C:\Users\<Username>\AppData\Local\scrcpy-win64-v4.1)


- 手机配置，通过数据线将手机连接到电脑，手机开启[developer options](https://developer.android.com/studio/debug/dev-options#enable)(设置-关于设备-OS Version连击7次)，开启后进入设置-其他设置-开发者选项(developer options)-开启USB debugging(小米还需要开启USB debugging security settings)


- 将手机投屏到电脑上```连接手机```-```允许文件传输(mtp)```-命令行输入```adb devices```出现设备号-命令行输入```scrcpy <device ID>```-出现投屏


---
## 企业APP-灵眸 [视频](https://custom.rokid.com/prod/rokid_web/323825adf4914c21be8a0d5fe7b8a9e5/pc/cn/74c78de85f9a4008b5500ccceadac8f1.html)
```
灵眸AR企业平台
https://ar-center.rokid.com/
公司名：lingban  
用户名: zisheng.cao01 zisheng.cao  
密码：Rokid@1234
```
目前已有的功能
- AI工作助手：拍照并直接生成报告，主要用于隐患排查
 - 优点：手机端可以修改内容
 - 缺点：报告格式不可修改（？）最终下载下来的报告模板比较简单，只能提供excel的第一行，然后拍摄的图片以及生成的文字会出现在第二行


- AI问答：可以快速检索行业规范，设备手册，标准作业流程SOP等
 - 模型中心-添加第三方大模型-API地址和密钥-选择模型类型“文字”or“视觉”-智能体管理-创建智能体-填写基本信息（提示词，输出格式等）-启用智能体
 - 缺点：没有办法关联到特定数据库

	- 这里是一个用于生成入料检测设备操作指南的智能体提示词案例
```
## 角色定义
你是一名专业的入料检测部门设备使用专家，精通各类入料检测流程中需要使用到的检测设备。你具备识别设备图片或设备名称并转化为专业化操作指南的能力。

## 任务描述
根据用户提供的任意形式的资料（包括但不限于设备照片，设备型号等），生成一份完整、规范的markdown形式标准操作程序文档。

## 输入要求
- 接受任何形式的设备相关资料
- 自动识别该设备型号
- 补充缺失但必要的用于识别设备的要素

## 输出规范
1. 保持专业、清晰的技术文档风格，语言简洁准确。
2. 结构分为三至四部分：
   - 第一部分：快速入门（安装、开机、基础设置）
   - 第二部分：核心操作流程（按使用频率排序，分步骤说明）
   - 第三部分：关键辅助操作（如校准、维护、常见错误处理）
   - 第四部分：适用与不适用场景（如测量对象、材料限制等，如有）
3. 流程性内容使用编号步骤，对比性内容使用表格呈现。
4. 每个步骤需包含：操作动作 + 注意事项/要点（如有）。
5. 在适当位置加入"注意"或"重要提示"等警示块。
6. 整体格式为Markdown。
```

- AI识别：好像就是AI问答的扩展，区别是可以直接设定热词然后开始对智能体输入（文字or视觉），然后能生成报告，并且可以在web端查询识别记录
 - 配置完智能体-识别应用管理-新增识别应用-行业应用管理-新增行业应用-选择模块（比如AI识别，不选择的则不会出现在眼镜的模块列表里）-选择应用（勾选刚刚新建的识别应用）-设置热词（大于2个字，拼音中间空格断开）


- 车辆识别
- 远程协作
- 应用配置


fnm env --use-on-cd | Out-String | Invoke-Expression




