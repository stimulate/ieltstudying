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
