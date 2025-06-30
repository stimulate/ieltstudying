function main(workbook: ExcelScript.Workbook) {
  const sourceSheet = workbook.getActiveWorksheet();
  const newSheet = workbook.addWorksheet("勤務管理");
  newSheet.getRange("A1:F1").setValues([["日付", "曜日", "作業開始時間", "作業終了時間", "作業", "稼働日フラグ"]]);

  const values = sourceSheet.getUsedRange()?.getValues();
  if (!values || values.length <= 1) return;

  const attendanceMap: {
    [date: string]: {
      dayOfWeek: string;
      startTimes: string[];
      endTimes: string[];
    };
  } = {};

  for (let i = 1; i < values.length; i++) {
    const subject = values[i][0]?.toString().trim();
    const sentOnRaw = values[i][1];

    if (!subject || !sentOnRaw) continue;

    // 解析时间
    let sentOn: Date;
    if (sentOnRaw instanceof Date) {
      sentOn = sentOnRaw;
    } else {
      sentOn = new Date(sentOnRaw.toString());
      if (isNaN(sentOn.getTime())) continue;
    }

    const y = sentOn.getFullYear();
    const m = String(sentOn.getMonth() + 1).padStart(2, "0");
    const d = String(sentOn.getDate()).padStart(2, "0");
    const hh = String(sentOn.getHours()).padStart(2, "0");
    const mm = String(sentOn.getMinutes()).padStart(2, "0");
    const dateStr = `${y}/${m}/${d}`;
    const timeStr = `${hh}:${mm}`;
    const dayOfWeek = getJapaneseDayOfWeek(sentOn);

    if (!attendanceMap[dateStr]) {
      attendanceMap[dateStr] = {
        dayOfWeek,
        startTimes: [],
        endTimes: []
      };
    }

    if (subject.includes("作業開始")) {
      attendanceMap[dateStr].startTimes.push(timeStr);
    } else if (subject.includes("作業終了")) {
      attendanceMap[dateStr].endTimes.push(timeStr);
    }
  }

  const output: (string | number)[][] = [];

  for (const date in attendanceMap) {
    const record = attendanceMap[date];
    const startTime = record.startTimes.length > 0 ? record.startTimes.sort()[0] : "";
    const endTime = record.endTimes.length > 0 ? record.endTimes.sort().slice(-1)[0] : "";
    const isWorkday = !["土", "日"].includes(record.dayOfWeek);

    output.push([
      date,
      record.dayOfWeek,
      startTime,
      endTime,
      "作業",
      isWorkday ? 1 : ""
    ]);
  }

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
