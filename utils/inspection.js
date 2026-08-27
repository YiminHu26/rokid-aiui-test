export function saveRecords(record) {
  const records = wx.getStorageSync('inspectionRecords') || [];

  records.push(record);
  wx.setStorageSync('inspectionRecords', records);
}

export function getHistoryRecords() {
  const records = wx.getStorageSync('inspectionRecords') || [];

  return records.map(record => ({
    model: record.model,
    results: record.results,
    timestamp: record.timestamp
  }));
}