function main(workbook: ExcelScript.Workbook) {
  // 出力シート作成
  let newSheet = workbook.addWorksheet("考勤整理");
  newSheet.getRange("A1:F1").setValues([["日付", "曜日", "作業開始時間", "作業終了時間", "作業", "稼働日フラグ"]]);

  let attendanceData: {
    [key: string]: {
      date: string;
      dayOfWeek: string;
      startTime?: string;
      endTime?: string;
    };
  } = {};

  // すべてのワークシートを対象
  for (let sheet of workbook.getWorksheets()) {
    if (sheet.getName() === "考勤整理") continue;

    const usedRange = sheet.getUsedRange();
    if (!usedRange) continue;

    const values = usedRange.getValues();
    const rowCount = values.length;

    let currentType = "";

    for (let i = 0; i < rowCount; i++) {
      const subject = values[i][0] as string;
      const sentOn = values[i][1];

      if (subject && subject.toString().includes("【勤怠管理】")) {
        currentType = subject;
        continue;
      }

      if (sentOn instanceof Date) {
        const dateObj = sentOn as Date;

        const year = dateObj.getFullYear();
        const month = (dateObj.getMonth() + 1).toString().padStart(2, "0");
        const date = dateObj.getDate().toString().padStart(2, "0");
        const hours = dateObj.getHours().toString().padStart(2, "0");
        const minutes = dateObj.getMinutes().toString().padStart(2, "0");

        const dateStr = `${year}/${month}/${date}`;
        const timeStr = `${hours}:${minutes}`;
        const dayOfWeek = getJapaneseDayOfWeek(dateObj);

        if (!attendanceData[dateStr]) {
          attendanceData[dateStr] = {
            date: dateStr,
            dayOfWeek: dayOfWeek,
          };
        }

        if (currentType.includes("作業開始")) {
          attendanceData[dateStr].startTime = timeStr;
        } else if (currentType.includes("作業終了")) {
          attendanceData[dateStr].endTime = timeStr;
        }
      }
    }
  }

  // 出力配列へ変換
  let output: (string | number)[][] = [];

  for (let key in attendanceData) {
    const record = attendanceData[key];
    const isWorkday = !(["土", "日"].includes(record.dayOfWeek));
    output.push([
      record.date,
      record.dayOfWeek,
      record.startTime || "",
      record.endTime || "",
      "作業",
      isWorkday ? 1 : ""
    ]);
  }

  // 出力
  if (output.length > 0) {
    newSheet.getRangeByIndexes(1, 0, output.length, 6).setValues(output);
    newSheet.getUsedRange()?.getFormat().autofitColumns();
  }
}

// 曜日を日本語で返す
function getJapaneseDayOfWeek(date: Date): string {
  const week = ["日", "月", "火", "水", "木", "金", "土"];
  return week[date.getDay()];
}
