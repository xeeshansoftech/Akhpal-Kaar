VERSION 5.00
Begin VB.Form Splash 
   Appearance      =   0  'Flat
   BackColor       =   &H80000005&
   BorderStyle     =   0  'None
   ClientHeight    =   4275
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   6450
   ClipControls    =   0   'False
   ControlBox      =   0   'False
   Icon            =   "Splash.frx":0000
   LinkTopic       =   "Form1"
   MinButton       =   0   'False
   Moveable        =   0   'False
   Picture         =   "Splash.frx":0442
   ScaleHeight     =   4275
   ScaleWidth      =   6450
   ShowInTaskbar   =   0   'False
   StartUpPosition =   2  'CenterScreen
   Begin VB.Timer DisplayTime 
      Interval        =   5000
      Left            =   600
      Top             =   1560
   End
End
Attribute VB_Name = "Splash"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub DisplayTime_Timer()
    Unload Me
End Sub

Private Sub Image1_Click()

End Sub
