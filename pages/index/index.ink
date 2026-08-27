<script def>
{
  "navigationBarTitleText": "Index Page"
}
</script>

<script setup>
import wx from 'wx';
import { saveRecords } from '../../utils/inspection';

// 检测项目定义
const INSPECTION_ITEMS = {
  '1001': [
    { name: '检测项目1-1 模块的外部拼装的完整性和方向', description: '根据图纸确认产品构型，钢支架构型正确' },
    { name: '检测项目1-2 防爆喷口方向、铭牌', description: '根据图纸确认防爆口方向以及铭牌内容。铭牌上要包含生产日期/序列号+公司名称' },
    { name: '检测项目1-3 壳体油漆颜色', description: '确认唛头或图纸上所表明的油漆颜色是否与实物相符' },
    { name: '检测项目1-4 绝缘盆的装配方向、通透、标签、标识', description: '根据图纸确定绝缘盆的位置，标签颜色，通/密盆标识' },
    { name: '检测项目1-5 密度表安装方向、充气压力值和气管标识漆', description: '根据图纸确定密度表位置，朝向，压力值' },
    { name: '检测项目1-6 标牌、铭牌的安装和正确性', description: '根据图纸确认各模块标识，干燥剂标识，铭牌上是否有生产日期/批次+公司名称' },
    { name: '检测项目1-7 开关的分合位置', description: '接地开关在“分/0”绿色状态，隔离开关在“合/ I”状态' }
  ],
  '1002': [
    { name: '检测项目2-1', description: '检查断路器分合闸动作是否正常' },
    { name: '检测项目2-2', description: '检查接地开关接触是否良好' },
    { name: '检测项目2-3', description: '检查二次回路接线是否正确' }
  ]
};

export default {
  data: {
    // 阶段: 'model-select' | 'inspection' | 'done'
    phase: 'model-select',
    focused: false,
    selectedModel: '',
    models: ['1001', '1002'],

    // 检测阶段
    inspectionItems: [],
    currentItemIndex: 0,
    currentItemName: '',
    currentItemDescription: '',

    // 选项聚焦: 0 = '合格', 1 = '待确认'
    optionFocused: 0,

    // 已完成检测结果
    results: [],
    resultScrollTop: 0
  },

  onShow() {
    this.setData({
      phase: 'model-select',
      focused: false,
      selectedModel: '',
      inspectionItems: [],
      currentItemIndex: 0,
      currentItemName: '',
      currentItemDescription: '',
      optionFocused: 0,
      results: [],
      resultScrollTop: 0
    });
  },

  onKeyUp(event) {
    const code = event.code;

    // ========== 型号选择阶段 ==========
    if (this.data.phase === 'model-select') {
      // 未聚焦时，按 Enter 或 GlobalHook 进入聚焦模式
      if (!this.data.focused && (code === 'Enter' || code === 'GlobalHook')) {
        this.setData({
          focused: true,
          selectedModel: this.data.selectedModel || '1001'
        });
        return;
      }

      // // 未聚焦时，拦截 Backspace 防止退出
      // if (!this.data.focused && code === 'Backspace') {
      //   event.preventDefault();
      //   return;
      // }

      if (this.data.focused) {
        const idx = this.data.models.indexOf(this.data.selectedModel);

        if (code === 'ArrowLeft' || code === 'ArrowUp') {
          const prevIdx = idx <= 0 ? this.data.models.length - 1 : idx - 1;
          this.setData({ selectedModel: this.data.models[prevIdx] });
          return;
        }

        if (code === 'ArrowRight' || code === 'ArrowDown') {
          const nextIdx = idx >= this.data.models.length - 1 ? 0 : idx + 1;
          this.setData({ selectedModel: this.data.models[nextIdx] });
          return;
        }

        if (code === 'Enter' || code === 'GlobalHook') {
          // 确认选择，进入检测阶段
          this.startInspection();
          return;
        }

        if (code === 'Escape' || code === 'Backspace') {
          this.setData({ focused: false });
          return;
        }
      }
      return;
    }

    // ========== 检测阶段 ==========
    if (this.data.phase === 'inspection') {
      if (code === 'ArrowLeft' || code === 'ArrowUp' || code === 'ArrowRight' || code === 'ArrowDown') {
        // 切换选项聚焦
        this.setData({
          optionFocused: this.data.optionFocused === 0 ? 1 : 0
        });
        return;
      }

      if (code === 'Enter' || code === 'GlobalHook') {
        // 确认当前选项
        this.confirmOption();
        return;
      }

      if (code === 'Backspace' || code === 'Escape') {
        // 返回型号选择
        event.preventDefault();
        this.setData({
          phase: 'model-select',
          focused: true,
          inspectionItems: [],
          currentItemIndex: 0,
          currentItemName: '',
          currentItemDescription: '',
          optionFocused: 0,
          results: [],
          resultScrollTop: 0
        });
        return;
      }
      return;
    }

    // ========== 完成阶段 ==========
    if (this.data.phase === 'done') {
      if (code === 'ArrowUp' || code === 'ArrowDown') {
        event.preventDefault();
        const scrollStep = 48;
        const nextScrollTop = Math.max(
          0,
          this.data.resultScrollTop + (code === 'ArrowDown' ? scrollStep : -scrollStep)
        );
        this.setData({ resultScrollTop: nextScrollTop });
        return;
      }

      if (code === 'Enter' || code === 'GlobalHook' || code === 'Backspace' || code === 'Escape') {
        if (code === 'Backspace') {
          event.preventDefault();
        }
        this.setData({
          phase: 'model-select',
          focused: false,
          selectedModel: '',
          inspectionItems: [],
          currentItemIndex: 0,
          currentItemName: '',
          currentItemDescription: '',
          optionFocused: 0,
          results: [],
          resultScrollTop: 0
        });
        return;
      }
    }
  },

  startInspection() {
    const items = INSPECTION_ITEMS[this.data.selectedModel] || [];
    const firstItem = items[0] || {};
    this.setData({
      phase: 'inspection',
      inspectionItems: items,
      currentItemIndex: 0,
      currentItemName: firstItem.name || '',
      currentItemDescription: firstItem.description || '',
      optionFocused: 0,
      results: []
    });
  },

  confirmOption() {
    const label = this.data.optionFocused === 0 ? '合格' : '待确认';
    const newResults = [...this.data.results, {
      item: this.data.currentItemName,
      description: this.data.currentItemDescription,
      result: label
    }];

    const nextIndex = this.data.currentItemIndex + 1;

    if (nextIndex >= this.data.inspectionItems.length) {
      // 所有项目完成
      this.setData({
        results: newResults,
        phase: 'done'
      });

      // 保存检测记录到本地
      saveRecords({
        model: this.data.selectedModel,
        results: newResults,
        timestamp: Date.now()
      });
    } else {
      // 显示下一个项目
      const nextItem = this.data.inspectionItems[nextIndex];
      this.setData({
        results: newResults,
        currentItemIndex: nextIndex,
        currentItemName: nextItem.name,
        currentItemDescription: nextItem.description,
        optionFocused: 0
      });
    }
  },

  selectModel(event) {
    const model = event.currentTarget.dataset.model;
    this.setData({ selectedModel: model });
    this.startInspection();
  }
}
</script>

<page>
  <!-- ========== 型号选择阶段 ========== -->
  <view class="container" ink:if="{{ phase === 'model-select' }}">
    <text class="title">选择GIS型号</text>
    <view class="button-group">
      <button
        class="model-btn {{ focused && selectedModel === '1001' ? 'model-btn--focused' : '' }}"
        bindtap="selectModel"
        data-model="1001"
      >1001</button>
      <button
        class="model-btn {{ focused && selectedModel === '1002' ? 'model-btn--focused' : '' }}"
        bindtap="selectModel"
        data-model="1002"
      >1002</button>
    </view>
  </view>

  <!-- ========== 检测阶段 ========== -->
  <view class="container" ink:if="{{ phase === 'inspection' }}">
    <text class="model-label">{{ selectedModel }}</text>
    <text class="inspection-title">{{ currentItemName }}</text>
    <text class="inspection-desc">{{ currentItemDescription }}</text>
    <view class="option-group">
      <button
        class="option-btn {{ optionFocused === 0 ? 'option-btn--focused' : '' }}"
        bindtap="confirmOption"
        data-option="0"
      >合格</button>
      <button
        class="option-btn {{ optionFocused === 1 ? 'option-btn--focused' : '' }}"
        bindtap="confirmOption"
        data-option="1"
      >待确认</button>
    </view>
    <text class="progress-text">{{ currentItemIndex + 1 }} / {{ inspectionItems.length }}</text>
  </view>

  <!-- ========== 完成阶段 ========== -->
  <view class="container" ink:if="{{ phase === 'done' }}">
    <text class="done-title">完成</text>
    <scroll-view class="result-list" scroll-y="true" scroll-top="{{ resultScrollTop }}">
      <view class="result-row" ink:for="{{ results }}" ink:key="item">
        <text class="result-item-name">{{ item.item }}</text>
        <text class="result-item-value">{{ item.result }}</text>
      </view>
    </scroll-view>
    <text class="hint-text">按任意键返回</text>
  </view>
</page>

<style>
.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  padding: 0 16px;
}

.title {
  color: var(--color-primary);
  width: 100%;
  text-align: center;
  font-size: 22px;
  font-weight: 500;
  line-height: 1.15;
  margin-bottom: 32px;
}

.button-group {
  display: flex;
  flex-direction: row;
  gap: 20px;
  margin-bottom: 30px;
}

/* ===== 型号选择按钮 ===== */
.model-btn {
  color: var(--color-primary);
  opacity: 0.72;
  background-color: transparent;
  border: 1px solid rgba(64, 255, 94, 0.48);
  border-radius: 4px;
  box-sizing: border-box;
  padding: 5px;
  width: 100px;
  line-height: 24px;
  text-align: center;
  transition: border-color 0.2s ease, background-color 0.2s ease, opacity 0.2s ease;
}

.model-btn--focused {
  opacity: 1;
  background-color: rgba(64, 255, 94, 0.12);
  border: 1px solid rgba(64, 255, 94, 0.72);
}

/* ===== 检测阶段 ===== */
.model-label {
  color: var(--color-primary);
  opacity: 0.48;
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  margin-bottom: 8px;
}

.inspection-title {
  color: var(--color-primary);
  font-size: 16px;
  font-weight: 500;
  line-height: 1.25;
  margin-bottom: 12px;
  text-align: center;
}

.inspection-desc {
  color: var(--color-primary);
  opacity: 0.6;
  font-size: 12px;
  font-weight: 400;
  line-height: 1.4;
  margin-bottom: 24px;
  text-align: center;
  max-width: 280px;
}

.option-group {
  display: flex;
  flex-direction: row;
  gap: 16px;
  margin-bottom: 20px;
}

/* ===== 检测选项按钮 ===== */
.option-btn {
  color: var(--color-primary);
  opacity: 0.72;
  background-color: transparent;
  border: 1px solid rgba(64, 255, 94, 0.48);
  border-radius: 4px;
  box-sizing: border-box;
  width: 120px;
  padding: 6px 0;
  text-align: center;
  transition: border-color 0.2s ease, background-color 0.2s ease, opacity 0.2s ease;
}

.option-btn--focused {
  opacity: 1;
  background-color: rgba(64, 255, 94, 0.12);
  border: 1px solid rgba(64, 255, 94, 0.72);
}

.progress-text {
  color: var(--color-primary);
  opacity: 0.48;
  font-size: 12px;
  font-weight: 400;
}

/* ===== 完成阶段 ===== */
.done-title {
  color: var(--color-primary);
  font-size: 22px;
  font-weight: 500;
  line-height: 1.15;
  margin-bottom: 24px;
}

.result-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
  max-width: 320px;
  max-height: 180px;
  margin-bottom: 24px;
}

.result-row {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  border: 1px solid var(--border-color-default);
  border-radius: 4px;
  min-width: 0;
}

.result-item-name {
  color: var(--color-primary);
  font-size: 14px;
  font-weight: 400;
  word-break: break-all;
  flex: 1 1 auto;
  min-width: 0;
}

.result-item-value {
  color: var(--color-primary);
  opacity: 0.72;
  font-size: 13px;
  font-weight: 500;
  white-space: nowrap;
  flex: 0 0 auto;
  margin-left: 12px;
}

.hint-text {
  color: var(--color-primary);
  opacity: 0.48;
  font-size: 12px;
  font-weight: 400;
}
</style>