<script def>
{
  "navigationBarTitleText": "Index Page"
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: {
    focused: false,
    selectedModel: '',
    models: ['1001', '1002']
  },
  

  onShow() {
    // 每次页面显示时重置聚焦状态，确保从其他页面返回后状态一致
    this.setData({
      focused: false,
      selectedModel: ''
    });
  },

  onKeyUp(event) {
    // 未聚焦时，按 Enter 或 GlobalHook 进入聚焦模式
    if (!this.data.focused && (event.code === 'Enter' || event.code === 'GlobalHook')) {
      this.setData({
        focused: true,
        selectedModel: this.data.selectedModel || '1001'
      });
      return;
    }

    // 未聚焦时，拦截 Backspace 防止意外退出页面
    if (!this.data.focused && event.code === 'Backspace') {
      event.preventDefault();
      return;
    }

    if (this.data.focused) {
      const idx = this.data.models.indexOf(this.data.selectedModel);

      if (event.code === 'ArrowLeft' || event.code === 'ArrowUp') {
        const prevIdx = idx <= 0 ? this.data.models.length - 1 : idx - 1;
        this.setData({ selectedModel: this.data.models[prevIdx] });
        return;
      }

      if (event.code === 'ArrowRight' || event.code === 'ArrowDown') {
        const nextIdx = idx >= this.data.models.length - 1 ? 0 : idx + 1;
        this.setData({ selectedModel: this.data.models[nextIdx] });
        return;
      }

      if (event.code === 'Enter') {
        // 确认选择，跳转到图片预览页面
        const imageSrc = this.data.selectedModel === '1001'
          ? '/assets/test-image-1.png'
          : '/assets/test-image-2.png';
        this.setData({ focused: false });
        wx.navigateTo({
          url: '/pages/image-viewer/image-viewer?imageSrc=' + encodeURIComponent(imageSrc)
        });
        return;
      }

      if (event.code === 'Escape' || event.code === 'Backspace') {
        this.setData({ focused: false });
        return;
      }
    }
  },

  selectModel(event) {
    const model = event.currentTarget.dataset.model;
    this.setData({ selectedModel: model });
    const imageSrc = model === '1001'
      ? '/assets/test-image-1.png'
      : '/assets/test-image-2.png';
    wx.navigateTo({
      url: '/pages/image-viewer/image-viewer?imageSrc=' + encodeURIComponent(imageSrc)
    });
  }
}
</script>

<page>
  <view class="container">
    <text class="title">选择GIS型号</text>
    <view class="button-group">
      <button
        class="{{ focused && selectedModel === '1001' ? 'focused' : '' }}"
        bindtap="selectModel"
        data-model="1001"
      >1001</button>
      <button
        class="{{ focused && selectedModel === '1002' ? 'focused' : '' }}"
        bindtap="selectModel"
        data-model="1002"
      >1002</button>
    </view>
  </view>
</page>

<style>
.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
}

.title {
  color: var(--color-primary);
  width: 100%;
  text-align: center;
  font-size: 24px;
  line-height: 24px;
  margin-bottom: 30px;
}

.button-group {
  display: flex;
  flex-direction: row;
  gap: 20px;
  margin-bottom: 30px;
}

button {
  color: var(--color-primary);
  border: 1px solid var(--border-color-default);
  border-radius: 12px;
  box-sizing: border-box;
  padding: 5px;
  width: 100px;
  line-height: 24px;
  text-align: center;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

button.focused {
  border: 2px solid var(--color-primary);
  box-shadow: 0 0 8px 2px rgba(var(--color-primary-rgb, 0, 122, 255), 0.5);
}
</style>