Private Sub cmdNext_Click()

    If Me.cboExercise.ListIndex < _
       Me.cboExercise.ListCount - 1 Then

        Me.cboExercise = _
            Me.cboExercise.ItemData( _
                Me.cboExercise.ListIndex + 1)

        LoadExercise

    Else

        MsgBox "最後の練習です。"

    End If

End Sub

FAAfUOBP0CDqOmkQotgIACswMJ0ZAC9DOlwAAAAAAAAAAAAAAAAAAAAAAAAAYAAxAAAAAADKXMA9EiBQUk9HUkF+MwAASAAJAAQA776BWEQ7y1wdDS4AAAAhDQAAAAABAAAAAAAAAAAAAAAAAAAABmTEAFAAcgBvAGcAcgBhAG0ARABhAHQAYQAAABgAbgAxAAAAAADKXG4rECBDT01QQU5+MQAAVgAJAAQA7769XG8fy1wDBS4AAAA/1QAAAABGAAAAAAAAAAAAAAAAAAAAsXF6AEMAbwBtAHAAYQBuAHkAUwBjAHIAZQBlAG4AcwBhAHYAZQByAAAAGAAAAA==
