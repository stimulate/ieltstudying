function main(workbook: ExcelScript.Workbook) {
    // 新しいワークシートを作成（出力用）
    let newSheet = workbook.addWorksheet("考勤整理");
    
    // ヘッダーを設定
    newSheet.getRange("A1:F1").setValues([["日付", "曜日", "作業開始時間", "作業終了時間", "作業", "稼働日フラグ"]]);
    
    // データを収集するオブジェクト
    let attendanceData: { [key: string]: { date: string, dayOfWeek: string, startTime?: string, endTime?: string } } = {};
    
    // すべてのワークシートを処理
    workbook.getWorksheets().forEach(sheet => {
        if (sheet.getName() !== "考勤整理") {
            let usedRange = sheet.getUsedRange();
            if (!usedRange) return;
            
            let values = usedRange.getValues() as string[][];
            
            let currentWorkType = "";
            
            for (let i = 0; i < values.length; i++) {
                let cellValue = values[i][0];
                
                if (typeof cellValue === "string" && cellValue.includes("【勤怠管理】")) {
                    currentWorkType = cellValue;
                    continue;
                }
                
                if (currentWorkType && typeof cellValue === "string" && cellValue.match(/\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}/)) {
                    let [dateStr, timeStr] = cellValue.split(" ");
                    let date = new Date(dateStr);
                    
                    if (isNaN(date.getTime())) continue;
                    
                    let dayOfWeek = getJapaneseDayOfWeek(date);
                    
                    if (!attendanceData[dateStr]) {
                        attendanceData[dateStr] = {
                            date: dateStr,
                            dayOfWeek: dayOfWeek
                        };
                    }
                    
                    if (currentWorkType.includes("作業開始")) {
                        attendanceData[dateStr].startTime = timeStr;
                    } else if (currentWorkType.includes("作業終了")) {
                        attendanceData[dateStr].endTime = timeStr;
                    }
                }
            }
        }
    });
    
    // データをワークシートに書き込み
    let outputData = Object.keys(attendanceData).map(dateStr => {
        let record = attendanceData[dateStr];
        let isWeekend = (record.dayOfWeek === "土" || record.dayOfWeek === "日");
        
        return [
            record.date,
            record.dayOfWeek,
            record.startTime || "",
            record.endTime || "",
            "作業",
            isWeekend ? "" : 1
        ];
    });
    
    if (outputData.length > 0) {
        newSheet.getRange("A2:F" + (outputData.length + 1)).setValues(outputData);
    }
    
    // 列幅を自動調整
    newSheet.getUsedRange()?.getFormat().autofitColumns();
    
    console.log("勤怠データの整理が完了しました！");
}

// 曜日を日本語で取得するヘルパー関数
function getJapaneseDayOfWeek(date: Date): string {
    const day = date.getDay();
    switch (day) {
        case 0: return "日";
        case 1: return "月";
        case 2: return "火";
        case 3: return "水";
        case 4: return "木";
        case 5: return "金";
        case 6: return "土";
        default: return "";
    }
}
