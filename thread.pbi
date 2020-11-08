;*************************************************************************
;- Interface -------------------------------------------------------------
;*************************************************************************
DeclareModule Thread
  
  ;*************************************************************************
  ;- Compiler directive
  ;*************************************************************************
  CompilerIf Not #PB_Compiler_Thread
    ;# Not actually needed, still play it safe... performance doesn't matter
    ;# as much for this specific usage.
    CompilerError "Use Compiler-Option: ThreadSafe!"
  CompilerEndIf
  
  ;*************************************************************************
  ;- Structure
  ;*************************************************************************
  Structure sThread
    ThreadId.i
    Signal.i
    Pause.i
    Cancel.i
    Exit.i
  EndStructure
  
  Structure sThreadListener Extends sThread
    Window.i
  EndStructure
  
  Structure sThreadWorker Extends sThread
    Name$
    Url$
    Param$
    Output$
    ExitCode.i
  EndStructure
  
  ;*************************************************************************
  ;- Enumeration
  ;*************************************************************************
  Enumeration Events #PB_Event_FirstCustomValue ;# Avoid internal conflict
    #Task_Start
    #Task_Process
    #Task_Finish
  EndEnumeration
  
  ;*************************************************************************
  ;- Global
  ;*************************************************************************
  Global.i MaxThreads
  Global.i ThreadRunning
  Global Dim Thread.sThreadWorker(1)
  
  ;*************************************************************************
  ;- Declaration
  ;*************************************************************************
  Declare   ThreadInit()
  Declare   ThreadRelease()
  
EndDeclareModule

;*************************************************************************
;- Implementation --------------------------------------------------------
;*************************************************************************
Module Thread
  
  EnableExplicit
  
  UseModule Core
  
  ;*************************************************************************
  ;- Global
  ;*************************************************************************
  Global.i MaxThreads = *Config\MaxThreads
  If MaxThreads = 0 : MaxThreads = 1 : EndIf
  ReDim Thread.sThreadWorker(MaxThreads)
  
  ;*************************************************************************
  ;- Declaration
  ;*************************************************************************
  Declare.i ThreadStart(*Data.sThread, *Procedure)
  Declare   ThreadStop(*Data.sThread, Wait = 1000)
  Declare.i ThreadFree(*Data.sThread, Stop = #True, Wait = 1000)
  Declare   ThreadPause(*Data.sThread)
  Declare   ThreadResume(*Data.sThread)
  
  Declare   ThreadListener(*Data.sThreadListener)
  Declare   ThreadWorker(*Data.sThreadWorker)
  
  ;*************************************************************************
  ;- Procedure: Thread Control
  ;  Adopted from PB Forum User mk-soft:
  ;  http://forums.purebasic.com/english/viewtopic.php?f=12&t=73231
  ;*************************************************************************
  Procedure.i ThreadStart(*Data.sThread, *Procedure)
    If Not IsThread(*Data\ThreadId)
      *Data\Exit = #False
      *Data\Pause = #False
      *Data\ThreadId = CreateThread(*Procedure, *Data)
    EndIf
    ProcedureReturn *Data\ThreadId
  EndProcedure
  
  Procedure ThreadStop(*Data.sThread, Wait = 1000)
    If IsThread(*Data\ThreadId)
      *Data\Exit = #True
      If *Data\Pause
        *Data\Pause = #False
        SignalSemaphore(*Data\Signal)
      EndIf
      If Wait
        If WaitThread(*Data\ThreadId, Wait) = 0
          KillThread(*Data\ThreadId)
        EndIf
        *Data\ThreadId = 0
        *Data\Pause = #False
        *Data\Exit = #False
        If *Data\Signal
          FreeSemaphore(*Data\Signal)
          *Data\Signal = 0
        EndIf
      EndIf
    EndIf
  EndProcedure
  
  Procedure.i ThreadFree(*Data.sThread, Stop = #True, Wait = 1000)
    If IsThread(*Data\ThreadID)
      If Stop
        ThreadStop(*Data, Wait)
        ProcedureReturn #True
      Else
        ProcedureReturn #False
      EndIf
    Else
      If *Data\Signal
        FreeSemaphore(*Data\Signal)
      EndIf
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure ThreadPause(*Data.sThread)
    If IsThread(*Data\ThreadId)
      If Not *Data\Signal
        *Data\Signal = CreateSemaphore()
      EndIf
      If Not *Data\Pause
        *Data\Pause = #True
      EndIf
    EndIf
  EndProcedure
  
  Procedure ThreadResume(*Data.sThread)
    If IsThread(*Data\ThreadId)
      If *Data\Pause
        *Data\Pause = #False
        SignalSemaphore(*Data\Signal)
      EndIf
    EndIf
  EndProcedure
  
  ;*************************************************************************
  ;- Procedure: Thread Workers
  ;*************************************************************************
  Procedure ThreadListener(*Data.sThreadListener)
    Protected.i x
    With *Data
      
      ;# Thread: Loop
      Repeat
        
        If \Exit
          Debug "[Thread:Listener] Breaking " + Str(\ThreadId)
          Break
        EndIf
        
        If \Pause
          Debug "[Thread:Listener] Paused " + Str(\ThreadId)
          WaitSemaphore(\Signal)
          Debug "[Thread:Listener] Resumed " + Str(\ThreadId)
        EndIf
        
        ;# Tasks
        For x = 1 To MaxThreads
          ;# Check for idle Workers and tasks and pass Task params to Thread params
          If Thread(x)\Pause = #True
            If FirstElement(Task())
              Thread(x)\Name$  = Task()\Name$
              Thread(x)\Url$   = Task()\Url$
              Thread(x)\Param$ = Task()\Param$
              ThreadResume(Thread(x))
              Debug "[Thread:Listener] Task assigned to Worker " + Thread(x)\ThreadId
              DeleteElement(Task())
              Break
            EndIf
          EndIf
        Next x
        Delay(10) ;# Don't hog CPU
        
      Until \Exit
      
      ;# Thread: Cancel or Exit
      If \Exit
        Debug "[Thread:Listener] Finished " + Str(\ThreadId)
      Else
        Debug "[Thread:Listener] Cancelled " + Str(\ThreadId)
      EndIf
      \ThreadId = 0
      
    EndWith
  EndProcedure
  
  Procedure ThreadWorker(*Data.sThreadWorker)
    With *Data
      
      ;# Thread: Loop
      Repeat
        
        ;# Thread Loop: Exit
        If \Exit
          Debug "[Thread:Worker] Breaking " + Str(\ThreadId)
          Break
        EndIf
        
        ;# Thread Loop: Pause
        If \Pause
          ;# Set Thread to idle
          Debug "[Thread:Worker] Paused " + Str(\ThreadId)
          WaitSemaphore(\Signal)
          Debug "[Thread:Worker] Resumed " + Str(\ThreadId)
          ;# If Signal received: continue
          
          ;# Get to work
          If \Param$
            Debug "[Thread:Worker] Task Param: " +\Param$
            PostEvent(#Task_Start, #PB_Ignore, #PB_Ignore, #PB_Ignore, *Data)
            Delay(10)
            
            ;# youtube-dl
            Protected.i Prog
            Debug "youtube-dl" + \Param$
            Prog = RunProgram("youtube-dl", \Param$, "", #PB_Program_Open|#PB_Program_Error|#PB_Program_Read|#PB_Program_Hide)
            If IsProgram(Prog)
              
              While ProgramRunning(Prog)
                
                If AvailableProgramOutput(Prog)
                  
                  ;# Output
                  Protected.s Out$ = ReadProgramString(Prog)
                  If Out$ <> ""
                    \Output$ = Out$ + Chr(10)
                    PostEvent(#Task_Process, #PB_Ignore, #PB_Ignore, #PB_Ignore, *Data)
                    Delay(10) ;# 10ms seems balanced enough
                  EndIf
                  
                EndIf
                
                If \Exit = #True
                  Debug "[Thread:Listener] Breaking while youtube-dl exec: " + Str(\ThreadId)
                  CloseProgram(Prog)
                  Break 2
                EndIf
              Wend
              
              If IsProgram(Prog)
                \ExitCode = ProgramExitCode(Prog)
                CloseProgram(Prog)
                PostEvent(#Task_Finish, #PB_Ignore, #PB_Ignore, #PB_Ignore, *Data)
                Delay(10)
              EndIf
              
            Else
              MessageRequester("Error", "youtube-dl not found, check your PATH variable or put the binaries in same directory as youtube-dl-frontend", #PB_MessageRequester_Error|#PB_MessageRequester_Ok)
            EndIf
            
            ;# Reset Thread Data
            \Name$    = ""
            \Url$     = ""
            \Param$   = ""
            \Output$  = ""
            \ExitCode = 0
            
            ThreadPause(*Data)
          EndIf
          
        EndIf
        
      Until \Exit
      
      If \Exit
        Debug "[Thread:Worker] Finished " + Str(\ThreadId)
      Else
        Debug "[Thread:Worker] Cancelled " + Str(\ThreadId)
      EndIf
      \ThreadId = 0
      
    EndWith
  EndProcedure
  
  ;*************************************************************************
  ;- Procedure: Thread Helpers
  ;*************************************************************************
  Procedure.i ThreadInit()
    Protected.i i
    For i = 0 To MaxThreads
      Protected.i ThreadType, ThreadId
      
      ;# Thread Type
      Select i
        Case 0
          ThreadType = @ThreadListener()
        Default
          ThreadType = @ThreadWorker()
      EndSelect
      
      ;# Create Threads
      ThreadId = ThreadStart(Thread(i), ThreadType)
      If IsThread(ThreadId) = 0
        Debug "[Thread:Init] Thread could not be Initialized"
        ProcedureReturn #True
      Else
        Select ThreadType
          Case @ThreadListener()
            Debug "[Thread:Listener] Spawned " + Str(ThreadId)
          Case @ThreadWorker()
            Debug "[Thread:Worker] Spawned " + Str(ThreadId)
            ThreadPause(Thread(i)) ;# Pause Worker Threads on creation
        EndSelect
      EndIf
      
    Next i
  EndProcedure
  
  Procedure.i ThreadRelease()
    Protected.i i
    For i = 1 To MaxThreads
      ThreadFree(Thread(i))
    Next i
    ThreadFree(Thread(0)) ;# Free listener last
  EndProcedure
  
  DisableExplicit
  
EndModule
; IDE Options = PureBasic 5.72 (Windows - x64)
; Folding = FA-
; EnableXP