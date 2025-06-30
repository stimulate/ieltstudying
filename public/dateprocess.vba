function main(workbook: ExcelScript.Workbook) {
  const newSheet = workbook.addWorksheet("考勤整理");
  newSheet.getRange("A1:F1").setValues([["日付", "曜日", "作業開始時間", "作業終了時間", "作業", "稼働日フラグ"]]);

  let attendanceData: {
    [key: string]: {
      date: string;
      dayOfWeek: string;
      startTime?: string;
      endTime?: string;
    };
  } = {};

  for (let sheet of workbook.getWorksheets()) {
    if (sheet.getName() === "考勤整理") continue;

    const values = sheet.getUsedRange()?.getValues();
    if (!values) continue;

    let currentType = "";

    for (let i = 0; i < values.length; i++) {
      const subject = values[i][0] as string;
      const sentOn = values[i][1];

      if (subject && subject.includes("【勤怠管理】")) {
        currentType = subject;
        continue;
      }

      if (!sentOn) continue;

      let dateObj: Date;

      // 字符串 → Date对象
      if (sentOn instanceof Date) {
        dateObj = sentOn;
      } else if (typeof sentOn === "string") {
        dateObj = new Date(sentOn);
        if (isNaN(dateObj.getTime())) continue;
      } else {
        continue;
      }

      const y = dateObj.getFullYear();
      const m = String(dateObj.getMonth() + 1).padStart(2, "0");
      const d = String(dateObj.getDate()).padStart(2, "0");
      const hh = String(dateObj.getHours()).padStart(2, "0");
      const mm = String(dateObj.getMinutes()).padStart(2, "0");

      const dateStr = `${y}/${m}/${d}`;
      const timeStr = `${hh}:${mm}`;
      const weekday = getJapaneseDayOfWeek(dateObj);

      if (!attendanceData[dateStr]) {
        attendanceData[dateStr] = {
          date: dateStr,
          dayOfWeek: weekday,
        };
      }

      if (currentType.includes("作業開始")) {
        attendanceData[dateStr].startTime = timeStr;
      } else if (currentType.includes("作業終了")) {
        attendanceData[dateStr].endTime = timeStr;
      }
    }
  }

  const output = Object.values(attendanceData).map(record => {
    const isWorkday = !["土", "日"].includes(record.dayOfWeek);
    return [
      record.date,
      record.dayOfWeek,
      record.startTime ?? "",
      record.endTime ?? "",
      "作業",
      isWorkday ? 1 : ""
    ];
  });

  if (output.length > 0) {
    newSheet.getRangeByIndexes(1, 0, output.length, 6).setValues(output);
    newSheet.getUsedRange()?.getFormat().autofitColumns();
  }

  console.log("考勤データ整理完了");
}

function getJapaneseDayOfWeek(date: Date): string {
  const week = ["日", "月", "火", "水", "木", "金", "土"];
  return week[date.getDay()];
}
