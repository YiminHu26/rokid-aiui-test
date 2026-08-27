<script def>
{
  "navigationBarTitleText": "Index Page"
}
</script>

<script setup>
import wx from 'wx';
import { saveRecords, getHistoryRecords } from '../../utils/inspection';

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
    // 阶段: 'model-select' | 'inspection' | 'done' | 'history'
    phase: 'model-select',
    focused: false,
    modelFocusIndex: 0,
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
    resultScrollTop: 0,

    // 历史记录
    historyRecords: [],
    selectedHistoryIndex: -1,
    historyResultScrollTop: 0
  },

  onShow() {
    this.setData({
      phase: 'model-select',
      focused: false,
      modelFocusIndex: 0,
      selectedModel: '',
      inspectionItems: [],
      currentItemIndex: 0,
      currentItemName: '',
      currentItemDescription: '',
      optionFocused: 0,
      results: [],
      resultScrollTop: 0,
      historyRecords: [],
      selectedHistoryIndex: -1,
      historyResultScrollTop: 0
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
          modelFocusIndex: this.data.modelFocusIndex,
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
        if (code === 'ArrowLeft' || code === 'ArrowUp') {
          const prevIndex = this.data.modelFocusIndex <= 0 ? 2 : this.data.modelFocusIndex - 1;
          this.setModelFocus(prevIndex);
          return;
        }

        if (code === 'ArrowRight' || code === 'ArrowDown') {
          const nextIndex = this.data.modelFocusIndex >= 2 ? 0 : this.data.modelFocusIndex + 1;
          this.setModelFocus(nextIndex);
          return;
        }

        if (code === 'Enter' || code === 'GlobalHook') {
          if (this.data.modelFocusIndex === 2) {
            this.showHistory();
          } else {
            this.startInspection();
          }
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

    // ========== 历史记录阶段 ==========
    if (this.data.phase === 'history') {
      if (code === 'ArrowUp' || code === 'ArrowDown') {
        event.preventDefault();
        if (this.data.historyRecords.length === 0) {
          return;
        }
        const currentIndex = this.data.selectedHistoryIndex < 0
          ? 0
          : this.data.selectedHistoryIndex;
        const nextIndex = code === 'ArrowDown'
          ? (currentIndex + 1) % this.data.historyRecords.length
          : (currentIndex - 1 + this.data.historyRecords.length) % this.data.historyRecords.length;
        this.selectHistoryRecord({ currentTarget: { dataset: { index: nextIndex } } });
        return;
      }

      if (code === 'Backspace' || code === 'Escape') {
        event.preventDefault();
        this.setData({
          phase: 'model-select',
          selectedHistoryIndex: -1,
          results: []
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
    this.setData({
      focused: true,
      modelFocusIndex: this.data.models.indexOf(model),
      selectedModel: model
    });
    this.startInspection();
  },

  setModelFocus(index) {
    this.setData({
      modelFocusIndex: index,
      selectedModel: index < this.data.models.length
        ? this.data.models[index]
        : this.data.selectedModel
    });
  },

  showHistory() {
    const historyRecords = getHistoryRecords();
    this.setData({
      phase: 'history',
      modelFocusIndex: 2,
      historyRecords,
      selectedHistoryIndex: -1,
      results: [],
      historyResultScrollTop: 0
    });
  },

  selectHistoryRecord(event) {
    const index = Number(event.currentTarget.dataset.index);
    const record = this.data.historyRecords[index];
    if (!record) {
      return;
    }

    this.setData({
      selectedHistoryIndex: index,
      results: record.results || [],
      historyResultScrollTop: 0
    });
  }
}
</script>

<page>
  <!-- ========== 型号选择阶段 ========== -->
  <view class="container" ink:if="{{ phase === 'model-select' }}">
    <text class="title">选择GIS型号</text>
    <view class="button-group">
      <button
        class="model-btn {{ focused && modelFocusIndex === 0 ? 'model-btn--focused' : '' }}"
        bindtap="selectModel"
        data-model="1001"
      >1001</button>
      <button
        class="model-btn {{ focused && modelFocusIndex === 1 ? 'model-btn--focused' : '' }}"
        bindtap="selectModel"
        data-model="1002"
      >1002</button>
    </view>
    <button
      class="model-btn history-btn {{ focused && modelFocusIndex === 2 ? 'model-btn--focused' : '' }}"
      bindtap="showHistory"
    >查询历史纪录</button>
  </view>

  <!-- ========== 历史记录阶段 ========== -->
  <view class="container history-container" ink:if="{{ phase === 'history' }}">
    <text class="history-title">历史纪录</text>
    <scroll-view class="history-list" scroll-y="true">
      <view
        class="history-entry"
        ink:for="{{ historyRecords }}"
        ink:for-index="index"
        ink:key="*this"
      >
        <view
          class="history-row {{ selectedHistoryIndex === index ? 'history-row--selected' : '' }}"
          bindtap="selectHistoryRecord"
          data-index="{{ index }}"
        >
          <text class="history-model">{{ item.model }}</text>
          <text class="history-timestamp">{{ item.timeStr }}</text>
        </view>
        <view
          class="history-inline-results"
          ink:if="{{ selectedHistoryIndex === index }}"
        >
          <text class="history-result-title">检测结果</text>
          <view class="result-row" ink:for="{{ item.results }}" ink:key="item">
            <text class="result-item-name">{{ item.item }}</text>
            <text class="result-item-value">{{ item.result }}</text>
          </view>
        </view>
      </view>
      <text class="empty-history" ink:if="{{ historyRecords.length === 0 }}">暂无历史纪录</text>
    </scroll-view>
    <text class="hint-text">按返回键回到型号选择</text>
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

.history-btn {
  color: var(--color-primary);
  opacity: 0.72;
  background-color: transparent;
  border: 1px solid var(--border-color-default);
  border-radius: 4px;
  padding: 6px 16px;
  line-height: 24px;
  text-align: center;
}

/* ===== 历史记录阶段 ===== */
.history-container {
  justify-content: flex-start;
  padding-top: 28px;
}

.history-title,
.history-result-title {
  color: var(--color-primary);
  font-size: 18px;
  font-weight: 500;
  line-height: 1.2;
  margin-bottom: 16px;
}

.history-list {
  width: 100%;
  max-width: 320px;
  height: 260px;
  margin-bottom: 16px;
}

.history-row {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  border: 1px solid var(--border-color-default);
  border-radius: 4px;
  margin-bottom: 8px;
}

.history-row--selected {
  background-color: rgba(64, 255, 94, 0.12);
  border-color: rgba(64, 255, 94, 0.72);
}

.history-model,
.history-timestamp {
  color: var(--color-primary);
  font-size: 13px;
}

.history-timestamp {
  opacity: 0.72;
  white-space: nowrap;
}

.empty-history {
  color: var(--color-primary);
  opacity: 0.48;
  font-size: 13px;
}

.history-inline-results {
  padding: 8px 12px 4px;
  border-left: 1px solid rgba(64, 255, 94, 0.48);
  border-right: 1px solid rgba(64, 255, 94, 0.48);
  border-bottom: 1px solid rgba(64, 255, 94, 0.48);
  margin: -8px 0 8px;
}

.history-result-title {
  display: block;
  font-size: 14px;
  margin-bottom: 8px;
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
</style>ty: 0.72;
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