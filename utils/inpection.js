// Inspection utilities for final quality control procedure

function formatTimestamp(ts) {
    const date = new Date(ts);
    const Y = date.getFullYear();
    const M = String(date.getMonth() + 1).padStart(2, '0');
    const D = String(date.getDate()).padStart(2, '0');
    const h = String(date.getHours()).padStart(2, '0');
    const m = String(date.getMinutes()).padStart(2, '0');
    const s = String(date.getSeconds()).padStart(2, '0');
    return `${Y}-${M}-${D} ${h}:${m}:${s}`;
}

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
        timestamp: record.timestamp,
        timeStr: formatTimestamp(record.timestamp)
    }));
}