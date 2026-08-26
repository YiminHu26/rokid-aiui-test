<script def>
{
  "navigationBarTitleText": "图片预览"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    imageSrc: ''
  },
  onLoad(options) {
    // 从路由参数获取图片路径
    this.setData({
      imageSrc: decodeURIComponent(options.imageSrc || '')
    });
  },
  onKeyUp(event) {
    if (event.code === 'Escape' || event.code === 'Back') {
      wx.navigateBack({ delta: 1 });
    }
  }
}
</script>

<page>
  <view class="container">
    <image
      wx:if="{{ imageSrc }}"
      class="preview-image"
      src="{{ imageSrc }}"
      mode="widthFix"
    />
    <text wx:else class="placeholder">暂无图片</text>
  </view>
</page>

<style>
.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  background-color: var(--color-background);
}

.preview-image {
  width: 100%;
  height: auto;
}

.placeholder {
  color: var(--color-text-secondary);
  font-size: 18px;
}
</style>