Sub ProcessAttendanceData()
    Dim ws As Worksheet
    Dim lastRow As Long, i As Long, outputRow As Long
    Dim dateStr As String, timeStr As String
    Dim workDate As Date, dayOfWeek As String
    Dim startTime As String, endTime As String
    
    ' 新しいワークシートを作成（出力用）
    Set ws = Worksheets.Add(After:=ActiveSheet)
    ws.Name = "考勤整理"
    
    ' ヘッダーを設定
    ws.Cells(1, 1).Value = "日付"
    ws.Cells(1, 2).Value = "曜日"
    ws.Cells(1, 3).Value = "作業開始時間"
    ws.Cells(1, 4).Value = "作業終了時間"
    ws.Cells(1, 5).Value = "作業"
    ws.Cells(1, 6).Value = "稼働日フラグ"
    
    ' 出力行を初期化
    outputRow = 2
    
    ' データ処理
    For i = 1 To Worksheets.Count
        If Worksheets(i).Name <> ws.Name Then ' 出力シートは除外
            lastRow = Worksheets(i).Cells(Rows.Count, 1).End(xlUp).Row
            
            For j = 1 To lastRow
                If InStr(Worksheets(i).Cells(j, 1).Value, "【勤怠管理】") > 0 Then
                    ' 作業タイプを取得
                    Dim workType As String
                    workType = Worksheets(i).Cells(j, 1).Value
                    
                    ' 時間データを処理
                    k = j + 1
                    Do While k <= lastRow And InStr(Worksheets(i).Cells(k, 1).Value, "【勤怠管理】") = 0
                        ' 日付と時間を分割
                        dateStr = Left(Worksheets(i).Cells(k, 1).Value, 10)
                        timeStr = Mid(Worksheets(i).Cells(k, 1).Value, 12, 5)
                        
                        ' 日付に変換
                        workDate = CDate(dateStr)
                        
                        ' 曜日を判定
                        Select Case Weekday(workDate)
                            Case vbSunday: dayOfWeek = "日"
                            Case vbMonday: dayOfWeek = "月"
                            Case vbTuesday: dayOfWeek = "火"
                            Case vbWednesday: dayOfWeek = "水"
                            Case vbThursday: dayOfWeek = "木"
                            Case vbFriday: dayOfWeek = "金"
                            Case vbSaturday: dayOfWeek = "土"
                        End Select
                        
                        ' レコードを検索または追加
                        Dim found As Boolean
                        found = False
                        For m = 2 To outputRow - 1
                            If ws.Cells(m, 1).Value = dateStr Then
                                If workType = "【勤怠管理】作業開始" Then
                                    ws.Cells(m, 3).Value = timeStr
                                ElseIf workType = "【勤怠管理】作業終了" Then
                                    ws.Cells(m, 4).Value = timeStr
                                End If
                                found = True
                                Exit For
                            End If
                        Next m
                        
                        If Not found Then
                            ws.Cells(outputRow, 1).Value = dateStr
                            ws.Cells(outputRow, 2).Value = dayOfWeek
                            
                            If workType = "【勤怠管理】作業開始" Then
                                ws.Cells(outputRow, 3).Value = timeStr
                            ElseIf workType = "【勤怠管理】作業終了" Then
                                ws.Cells(outputRow, 4).Value = timeStr
                            End If
                            
                            ws.Cells(outputRow, 5).Value = "作業"
                            
                            ' 稼働日かどうかを判定
                            If dayOfWeek = "土" Or dayOfWeek = "日" Then
                                ws.Cells(outputRow, 6).Value = ""
                            Else
                                ws.Cells(outputRow, 6).Value = 1
                            End If
                            
                            outputRow = outputRow + 1
                        End If
                        
                        k = k + 1
                    Loop
                    j = k - 1 ' 処理済みの行をスキップ
                End If
            Next j
        End If
    Next i
    
    ' 列幅を自動調整
    ws.Columns.AutoFit
    
    MsgBox "勤怠データの整理が完了しました！", vbInformation
End Sub
