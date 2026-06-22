' Simple Calculator - VB4-style sample program
' Demonstrates: Sub, Function, Dim, If, Select Case, Input/Output

Sub Main
  Dim a
  Dim b
  Dim op
  Dim result

  Print "Simple Calculator"
  Print "=================="

  a = InputBox("Enter first number:")
  a = CInt(a)

  op = InputBox("Enter operation (+, -, *, /):")

  b = InputBox("Enter second number:")
  b = CInt(b)

  Select Case op
    Case "+"
      result = Add(a, b)
    Case "-"
      result = Subtract(a, b)
    Case "*"
      result = Multiply(a, b)
    Case "/"
      If b <> 0 Then
        result = Divide(a, b)
      Else
        Print "Error: Division by zero"
        result = 0
      End If
    Case Else
      Print "Error: Unknown operation"
      result = 0
  End Select

  Print "Result: " & CStr(result)
End Sub

Function Add(x, y)
  Add = x + y
End Function

Function Subtract(x, y)
  Subtract = x - y
End Function

Function Multiply(x, y)
  Multiply = x * y
End Function

Function Divide(x, y)
  Divide = x / y
End Function
