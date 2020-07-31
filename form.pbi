;*************************************************************************
;- Interface -------------------------------------------------------------
;*************************************************************************
DeclareModule Form
  
  ;*************************************************************************
  ;- Enumeration
  ;*************************************************************************
  ;{
  Enumeration Form 1
    
    #Font
    
    ;# Window: Main
    #Main
    #Men
    #Men_Main
    #Men_File1
    #Men_File2
    #Men_Sub1
    #Men_Sub2
    #Men_Sub3
    #Men_Sub4
    #Men_Help1
    #Men_Help2
    #Men_Help3
    
    #Header_Container
    #Header_Image
    #Header_Button1
    #Header_Button2
    
    #S_Container
    #S_Url1
    #S_Url2
    #S_Url3
    #S_Path1
    #S_Path2
    #S_Path3
    #S_Preset1
    #S_Preset2
    #S_Download
    #S_Console
    
    #A_Container
    #A_Button1
    #A_Button2
    #A_Button3
    #A_Button4
    #A_Name1
    #A_Name2
    #A_Url1
    #A_Url2
    #A_Path1
    #A_Path2
    #A_Path3
    #A_Preset1
    #A_Preset2
    #A_List
    
    ;# Window: Info
    #Info
    #Info_Icon
    #Info_Text1
    #Info_Text2
    #Info_Text3
    #Info_Link1
    #Info_Link2
  EndEnumeration
  
  Enumeration Media 100
    #Img_Logo
    #Ico_Video
    #Ico_Audio
    #Ico_Custom
    #Ico_Video_List
    #Ico_Folder
    #Ico_Exit
    #Ico_Refresh1
    #Ico_Refresh2
    #Ico_Sort1
    #Ico_Sort2
    #Ico_Web
    #Ico_Manual
    #Ico_Info
    #Ico_Download
    #Ico_Add
    #Ico_Edit
    #Ico_Save
    #Ico_Remove
  EndEnumeration
  ;#
  ;}
  
  ;*************************************************************************
  ;- Declaration
  ;*************************************************************************
  Declare WindowHandler()
  
EndDeclareModule

;*************************************************************************
;- Implementation --------------------------------------------------------
;*************************************************************************
Module Form
  
  EnableExplicit
  
  UseModule Core   ;# Globals
  UseModule Thread ;# Event communication
  
  ;*************************************************************************
  ;- Global
  ;*************************************************************************
  Global.i CurrentItem
  Global.i EventQuit
  
  ;*************************************************************************
  ;- Declaration
  ;*************************************************************************
  ;# Windows
  Declare.i MainWindow()
  Declare   MainWindowResize()
  Declare   MainWindowClose()
  
  Declare.i InfoWindow()
  Declare   InfoWindowClose()
  
  ;# Events
  Declare   Event_Quit()
  Declare   Event_Simple()
  Declare   Event_Advanced()
  
  Declare   Event_File1()
  Declare   Event_Subscription1()
  Declare   Event_Subscription2()
  Declare   Event_Subscription3()
  Declare   Event_Subscription4()
  Declare   Event_Help1()
  Declare   Event_Help2()
  Declare   Event_Help3()
  
  Declare   Event_Simple_Path()
  Declare   Event_Simple_Task()
  Declare   Event_Simple_Import()
  
  Declare   Event_Advanced_Add()
  Declare   Event_Advanced_Edit()
  Declare   Event_Advanced_Save()
  Declare   Event_Advanced_Remove()
  Declare   Event_Advanced_Path()
  
  Declare   Event_Link1()
  Declare   Event_Link2()
  
  ;# Helpers
  Declare   Echo(String$)
  Declare   FillPresets(Gadget.i)
  Declare   FillSubs()
  Declare.i SelectItem()
  Declare   UpdateGadgets(State.i)
  Declare   SyncSub(Mode.i)
  Declare.s MakeParam(Preset$, Url$, Path$)
  Declare   Clipboard()
  
  ;*************************************************************************
  ;- Icons
  ;*************************************************************************
  ;{
  CatchImage(#Img_Logo,       ?Logo)
  CatchImage(#Ico_Video,      ?IcoVideo)
  CatchImage(#Ico_Audio,      ?IcoAudio)
  CatchImage(#Ico_Custom,     ?IcoCustom)
  CatchImage(#Ico_Video_List, ?IcoVideoList)
  CatchImage(#Ico_Folder,     ?IcoFolder)
  CatchImage(#Ico_Exit,       ?IcoExit)
  CatchImage(#Ico_Download,   ?IcoDownload)
  CatchImage(#Ico_Add,        ?IcoAdd)
  CatchImage(#Ico_Edit,       ?IcoEdit)
  CatchImage(#Ico_Save,       ?IcoSave)
  CatchImage(#Ico_Remove,     ?IcoRemove)
  CatchImage(#Ico_Refresh1,   ?IcoRefresh1)
  CatchImage(#Ico_Refresh2,   ?IcoRefresh2)
  CatchImage(#Ico_Sort1,      ?IcoSort1)
  CatchImage(#Ico_Sort2,      ?IcoSort2)
  CatchImage(#Ico_Web,        ?IcoWeb)
  CatchImage(#Ico_Manual,     ?IcoManual)
  CatchImage(#Ico_Info,       ?IcoInfo)
  ;#
  ;}
  
  ;*************************************************************************
  ;- Procedure: Handler (Eventloop)
  ;*************************************************************************
  Procedure WindowHandler()
    
    Protected.i Event, EventData
    Protected.s EventText$
    Protected *ThreadData.sThreadWorker = AllocateStructure(sThreadWorker)
    
    ;# Create Main Window
    MainWindow()
    
    ;# Initialize Threads
    Thread::ThreadInit()
    
    ;# Event Loop
    Repeat
      Event     = WaitWindowEvent()
      EventData = EventData()
      Select Event
        Case Thread::#Task_Start
          *ThreadData = EventData
          EventText$ = "Start Download: " + *ThreadData\Name$ + ", url: " + *ThreadData\Url$
          Echo(EventText$)
        Case Thread::#Task_Finish
          *ThreadData = EventData
          EventText$ = "Finished Download: " + *ThreadData\Name$ + ", url: " + *ThreadData\Url$ + " (exitcode: " + *ThreadData\ExitCode + ")"
          Echo(EventText$)
          Echo("Tasks remaining in queue: " + ListSize(Core::Task()))
      EndSelect
    Until EventQuit = #True
    
    ;# Release Threads
    Thread::ThreadRelease()
    
    ;# Close Windows
    If IsWindow(#Info) : InfoWindowClose() : EndIf
    If IsWindow(#Main) : MainWindowClose() : EndIf
    
    ;# Save Settings
    Core::ConfigSave()
    Core::SubSave()
    
  EndProcedure
  
  ;*************************************************************************
  ;- Procedure: Main Window
  ;*************************************************************************
  Procedure.i MainWindow()
    Protected.i Width = 600, Height = 350 ;# Smallest window size possible
    
    If OpenWindow(#Main, Core::*Config\WindowX, Core::*Config\WindowY, Core::*Config\WindowW, Core::*Config\WindowH, Core::*Core\Title$, #PB_Window_SystemMenu|#PB_Window_SizeGadget|#PB_Window_MinimizeGadget|#PB_Window_MaximizeGadget)
      
      ;# General Window Settings
      WindowBounds(#Main, Width, Height, #PB_Ignore, #PB_Ignore)
      LoadFont(#Font, "Consolas", 11)
      
      ;# Menu
      If CreateImageMenu(#Men, WindowID(#Main))
        MenuTitle("File")
        MenuItem(#Men_File1, "Open Settings Folder" + Chr(9) + "F1",       ImageID(#Ico_Folder))
        MenuBar()
        MenuItem(#Men_File2, "Exit"                 + Chr(9) + "ALT + F4", ImageID(#Ico_Exit))
        MenuTitle("Subscriptions")
        MenuItem(#Men_Sub1, "Sync: Selected"        + Chr(9) + "F4",       ImageID(#Ico_Refresh1))
        MenuItem(#Men_Sub2, "Sync: All"             + Chr(9) + "F5",       ImageID(#Ico_Refresh2))
        MenuBar()
        MenuItem(#Men_Sub3, "Sort: Name Asc"        + Chr(9) + "",         ImageID(#Ico_Sort1))
        MenuItem(#Men_Sub4, "Sort: Name Desc"       + Chr(9) + "",         ImageID(#Ico_Sort2))
        MenuTitle("Help")
        MenuItem(#Men_Help1, "View GitHub Page"     + Chr(9) + "F10",      ImageID(#Ico_Web))
        MenuItem(#Men_Help2, "youtube-dl Manual"    + Chr(9) + "F11",      ImageID(#Ico_Manual))
        MenuItem(#Men_Help3, "Info"                 + Chr(9) + "",         ImageID(#Ico_Info))
      EndIf
      
      ;# Container: Header
      If ContainerGadget(#Header_Container, 0, 0, 1280, 70)
        SetGadgetColor(#Header_Container, #PB_Gadget_BackColor, $000000)
        ImageGadget(#Header_Image, 0, 0, 240, 70, ImageID(#Img_Logo))
        ButtonImageGadget(#Header_Button1, 250, 20, 100, 30, ImageID(#Ico_Video))
        ButtonImageGadget(#Header_Button2, 360, 20, 100, 30, ImageID(#Ico_Video_List))
        CloseGadgetList()
      EndIf
      
      ;# Container: Simple
      If ContainerGadget(#S_Container, 0, 80, 600, 248)
        TextGadget(#S_Url1, 10, 0, 580, 15, "URL:")
        StringGadget(#S_Url2, 10, 15, 470, 20, "")
        ButtonGadget(#S_Url3, 490, 15, 100, 20, "TXT")
        
        TextGadget(#S_Path1, 10, 40, 580, 15, "Path:")
        StringGadget(#S_Path2, 10, 55, 470, 20, Core::*Config\DefaultDir$)
        ButtonGadget(#S_Path3, 490, 55, 100, 20, "...")
        TextGadget(#S_Preset1, 10, 80, 580, 15, "Profile:")
        If ComboBoxGadget(#S_Preset2, 10, 95, 580, 20, #PB_ComboBox_Image)
          FillPresets(#S_Preset2)
        EndIf
        ButtonImageGadget(#S_Download, 10, 120, 580, 30, ImageID(#Ico_Download))
        If EditorGadget(#S_Console, 10, 160, 580, 80, #PB_Editor_ReadOnly)
          SetGadgetFont(#S_Console, FontID(#Font))
          SetGadgetColor(#S_Console, #PB_Gadget_FrontColor, #White)
          SetGadgetColor(#S_Console, #PB_Gadget_BackColor, #Black)
        EndIf
        CloseGadgetList()
      EndIf
      
      ;# Container: Advanced
      If ContainerGadget(#A_Container, 0, 80, 600, 248)
        HideGadget(#A_Container, #True)
        ButtonImageGadget(#A_Button1, 10,  5,   60,  30, ImageID(#Ico_Add))
        ButtonImageGadget(#A_Button2, 10,  45,  60,  30, ImageID(#Ico_Edit))
        ButtonImageGadget(#A_Button3, 10,  85,  60,  30, ImageID(#Ico_Save))
        ButtonImageGadget(#A_Button4, 10,  125, 60,  30, ImageID(#Ico_Remove))
        TextGadget(#A_Name1,          80,  0,   510, 15, "Name:")
        StringGadget(#A_Name2,        80,  15,  510, 20, "")
        TextGadget(#A_Url1,           80,  40,  510, 15, "URL:")
        StringGadget(#A_Url2,         80,  55,  510, 20, "")
        TextGadget(#A_Path1,          80,  80,  510, 15, "Path:")
        StringGadget(#A_Path2,        80,  95,  400, 20, "")
        ButtonGadget(#A_Path3,        490, 95,  100, 20, "...")
        TextGadget(#A_Preset1,        80,  120, 510, 15, "Profile:")
        If ComboBoxGadget(#A_Preset2, 80,  135, 510, 20, #PB_ComboBox_Image)
          FillPresets(#A_Preset2)
        EndIf
        If ListIconGadget(#A_List, 10, 160, 580, 80, "", 100, #PB_ListIcon_GridLines|#PB_ListIcon_CheckBoxes|#PB_ListIcon_FullRowSelect|#PB_ListIcon_AlwaysShowSelection|#LVS_NOCOLUMNHEADER)
          FillSubs()
          ;# Win API: Autosize the (invisible) column header
          SendMessage_(GadgetID(#A_List), #LVM_SETCOLUMNWIDTH, 0, #LVSCW_AUTOSIZE_USEHEADER)
        EndIf
        UpdateGadgets(#True)
      EndIf
      
      ;# Tooltips
      GadgetToolTip(#Header_Button1, "Quick Download")
      GadgetToolTip(#Header_Button2, "Managed Playlists")
      GadgetToolTip(#S_Path3, "Browse...")
      GadgetToolTip(#S_Download, "Download")
      
      GadgetToolTip(#A_Button1, "New Subscription")
      GadgetToolTip(#A_Button2, "Edit Subscription")
      GadgetToolTip(#A_Button3, "Save Subscription")
      GadgetToolTip(#A_Button4, "Remove Subscription")
      GadgetToolTip(#A_Path3, "Browse...")
      
      ;# Shortcuts
      AddKeyboardShortcut(#Main, #PB_Shortcut_F1,  #Men_File1)
      AddKeyboardShortcut(#Main, #PB_Shortcut_F4,  #Men_Sub1)
      AddKeyboardShortcut(#Main, #PB_Shortcut_F5,  #Men_Sub2)
      AddKeyboardShortcut(#Main, #PB_Shortcut_F10, #Men_Help1)
      AddKeyboardShortcut(#Main, #PB_Shortcut_F11, #Men_Help2)
      
      
      ;# Bind Events
      BindEvent(#PB_Event_CloseWindow, @Event_Quit(), #Main)
      BindEvent(#PB_Event_SizeWindow, @MainWindowResize(), #Main)
      BindEvent(#PB_Event_MoveWindow, @MainWindowResize(), #Main)
      
      BindMenuEvent(#Men, #Men_File1, @Event_File1())
      BindMenuEvent(#Men, #Men_File2, @Event_Quit())
      BindMenuEvent(#Men, #Men_Sub1, @Event_Subscription1())
      BindMenuEvent(#Men, #Men_Sub2, @Event_Subscription2())
      BindMenuEvent(#Men, #Men_Sub3, @Event_Subscription3())
      BindMenuEvent(#Men, #Men_Sub4, @Event_Subscription4())
      BindMenuEvent(#Men, #Men_Help1, @Event_Help1())
      BindMenuEvent(#Men, #Men_Help2, @Event_Help2())
      BindMenuEvent(#Men, #Men_Help3, @Event_Help3())
      
      BindGadgetEvent(#Header_Button1, @Event_Simple())
      BindGadgetEvent(#Header_Button2, @Event_Advanced())
      
      BindGadgetEvent(#S_Url2, @Clipboard(), #PB_EventType_Focus)
      BindGadgetEvent(#S_Url3, @Event_Simple_Import())
      BindGadgetEvent(#S_Path3, @Event_Simple_Path())
      BindGadgetEvent(#S_Download, @Event_Simple_Task())
      
      BindGadgetEvent(#A_List, @Event_Advanced_Edit(), #PB_EventType_LeftDoubleClick)
      BindGadgetEvent(#A_Button1, @Event_Advanced_Add())
      BindGadgetEvent(#A_Button2, @Event_Advanced_Edit())
      BindGadgetEvent(#A_Button3, @Event_Advanced_Save())
      BindGadgetEvent(#A_Button4, @Event_Advanced_Remove())
      BindGadgetEvent(#A_Path3, @Event_Advanced_Path())
      
      ;# Debug
      Echo("Presets found: " + Str(ListSize(Core::Preset())))
      Echo("Subscriptions found: " + Str(ListSize(Core::Sub())))
      Echo("Worker Threads spawned: " + Str(Core::*Config\MaxThreads-1))
      Echo("Ready")
      
      ;# Resize gadgets after creation
      MainWindowResize()
      
      Debug "[Form:Main] Created"
      ProcedureReturn #True
      
    EndIf
    
  EndProcedure
  
  Procedure MainWindowResize()
    
    Protected.i Width, Height
    
    Width  = WindowWidth(#Main, #PB_Window_InnerCoordinate)
    Height = WindowHeight(#Main, #PB_Window_InnerCoordinate)
    
    ResizeGadget(#Header_Container, 0, 0, Width, 70)
    
    ResizeGadget(#S_Container, 0, 80, Width, Height - MenuHeight() - 80)
    ResizeGadget(#S_Url2, 10, 15, GadgetWidth(#S_Container) - 130, 20)
    ResizeGadget(#S_Url3, GadgetWidth(#S_Container) - 110, 15, 100, 20)
    ResizeGadget(#S_Path2, 10, 55, GadgetWidth(#S_Container) - 130, 20)
    ResizeGadget(#S_Path3, GadgetWidth(#S_Container) - 110, 55, 100, 20)
    ResizeGadget(#S_Preset2, 10, 95, GadgetWidth(#S_Container) - 20, 20)
    ResizeGadget(#S_Download, 10, 120, GadgetWidth(#S_Container) - 20, 30)
    ResizeGadget(#S_Console, 10, 160, GadgetWidth(#S_Container) - 20, GadgetHeight(#S_Container) - 168)
    
    ResizeGadget(#A_Container, 0, 80, Width, Height - MenuHeight() - 80)
    ResizeGadget(#A_Name2, 80, 15, GadgetWidth(#A_Container) - 90, 20)
    ResizeGadget(#A_Url2, 80, 55, GadgetWidth(#A_Container) - 90, 20)
    ResizeGadget(#A_Preset2, 80, 135, GadgetWidth(#A_Container) - 90, 20)
    ResizeGadget(#A_Path2, 80, 95, GadgetWidth(#A_Container) - 200, 20)
    ResizeGadget(#A_Path3, GadgetWidth(#A_Container) - 110, 95, 100, 20)
    ResizeGadget(#A_List, 10, 160, GadgetWidth(#A_Container) - 20, GadgetHeight(#A_Container) - 168)
    
    ;# Win API: Autosize the (invisible) column header
    SendMessage_(GadgetID(#A_List), #LVM_SETCOLUMNWIDTH, 0, #LVSCW_AUTOSIZE_USEHEADER)
    
    ;# Save Window Parameters
    Core::*Config\WindowX    = WindowX(#Main)
    Core::*Config\WindowY    = WindowY(#Main)
    Core::*Config\WindowW    = Width
    Core::*Config\WindowH    = Height
    
  EndProcedure
  
  Procedure MainWindowClose()
    Debug "[Form:Main] Destroyed"
    CloseWindow(#Main)
  EndProcedure
  
  ;*************************************************************************
  ;- Procedure: Info Window
  ;*************************************************************************
  Procedure.i InfoWindow()
    Protected.i Width = 240, Height = 200
    
    If OpenWindow(#Info, #PB_Ignore, #PB_Ignore, Width, Height, "Info", #PB_Window_SystemMenu|#PB_Window_WindowCentered, WindowID(#Main))
      
      ;# General Window Settings
      WindowBounds(#Info, Width, Height, #PB_Ignore, #PB_Ignore)
      
      ;# Gadgets
      ImageGadget(#Info_Icon, 0, 0, 240, 70, ImageID(#Img_Logo))
      
      TextGadget(#Info_Text1, 10, 80, 220, 20, Core::*Core\Title$ + ", version " + Core::*Core\Version$ + ", " + Core::*Core\BuildDate$)
      TextGadget(#Info_Text2, 10, 100, 220, 20, "by transgressor")
      HyperLinkGadget(#Info_Link1, 10, 120, 220, 20, "www.whax.ch", 0)
      SetGadgetColor(#Info_Link1, #PB_Gadget_FrontColor, #Blue)
      
      TextGadget(#Info_Text3, 10, 150, 220, 20, "Uses 'Silk Icon Set' from Mark James:")
      HyperLinkGadget(#Info_Link2, 10, 170, 220, 20, "www.famfamfam.com/lab/icons/silk/", 0)
      SetGadgetColor(#Info_Link2, #PB_Gadget_FrontColor, #Blue)
      
      ;# Bind Events
      BindEvent(#PB_Event_CloseWindow, @InfoWindowClose(), #Info)
      BindGadgetEvent(#Info_Link1, @Event_Link1())
      BindGadgetEvent(#Info_Link2, @Event_Link2())
      
      DisableWindow(#Main, #True)
      
      Debug "[Form:Info] Created"
      ProcedureReturn #True
      
    EndIf
    
  EndProcedure
  
  Procedure InfoWindowClose()
    
    ;# Unbind Events
    UnbindEvent(#PB_Event_CloseWindow, @InfoWindowClose(), #Info)
    
    ;# Free Gadgets
    FreeGadget(#Info_Icon)
    FreeGadget(#Info_Text1)
    FreeGadget(#Info_Text2)
    FreeGadget(#Info_Text3)
    FreeGadget(#Info_Link1)
    FreeGadget(#Info_Link2)
    
    CloseWindow(#Info)
    DisableWindow(#Main, #False)
    SetActiveWindow(#Main)
    
    Debug "[Form:Info] Destroyed"
    
  EndProcedure
  
  ;*************************************************************************
  ;- Procedure - Events
  ;*************************************************************************
  ;# Main
  Procedure Event_Quit()
    EventQuit = #True
  EndProcedure
  
  Procedure Event_Simple()
    HideGadget(#A_Container, #True)
    HideGadget(#S_Container, #False)
  EndProcedure
  
  Procedure Event_Advanced()
    HideGadget(#S_Container, #True)
    HideGadget(#A_Container, #False)
  EndProcedure
  
  ;# Menu
  Procedure Event_File1()
    RunProgram(Core::*Core\DataPath$)
  EndProcedure
  
  Procedure Event_Subscription1()
    SyncSub(0)
  EndProcedure
  
  Procedure Event_Subscription2()
    SyncSub(1)
  EndProcedure
  
  Procedure Event_Subscription3()
    SortStructuredList(Core::Sub(), #PB_Sort_NoCase|#PB_Sort_Ascending, OffsetOf(sSubscription\Name$), TypeOf(sSubscription\Name$))
    FillSubs()
  EndProcedure
  
  Procedure Event_Subscription4()
    SortStructuredList(Core::Sub(), #PB_Sort_NoCase|#PB_Sort_Descending, OffsetOf(sSubscription\Name$), TypeOf(sSubscription\Name$))
    FillSubs()
  EndProcedure
  
  Procedure Event_Help1()
    RunProgram("https://github.com/transgressor/youtube-dl-front-end")
  EndProcedure
  
  Procedure Event_Help2()
    RunProgram("https://github.com/ytdl-org/youtube-dl/blob/master/README.md#readme")
  EndProcedure
  
  Procedure Event_Help3()
    InfoWindow()
  EndProcedure
  
  ;# Simple
  Procedure Event_Simple_Path()
    Protected.s Path$ = PathRequester("Select Folder", GetGadgetText(#S_Path2))
    If Path$
      Core::*Config\DefaultDir$ = Path$
      SetGadgetText(#S_Path2, Path$)
    EndIf
  EndProcedure
  
  Procedure Event_Simple_Task()
    Protected.s Url$   = GetGadgetText(#S_Url2)
    Protected.s Path$  = GetGadgetText(#S_Path2)
    Protected.i Id     = GetGadgetState(#S_Preset2)
    Protected.s Param$
    
    ;# Check Preset and Prepare Task
    If SelectElement(Preset(), Id) And Url$
      Protected *Task.sTask = AllocateStructure(sTask)
      Param$ = MakeParam(Core::Preset()\Param$, Url$, Path$)
      With *Task
        \Url$   = Url$
        \Param$ = Param$
      EndWith
    EndIf
    
    ;# Add Task To List
    AddElement(Core::Task())
    With Core::Task()
      \Name$  = "Untitled (Quick)"
      \Url$   = *Task\Url$
      \Param$ = *Task\Param$
    EndWith
    FreeStructure(*Task)
    
  EndProcedure
  
  Procedure Event_Simple_Import()
    
    Protected.s FilePath$ = OpenFileRequester("Select TXT", Core::*Config\DefaultDir$, "Text file | *.txt", 0)
    Protected.i File = ReadFile(#PB_Any, FilePath$)
    Debug FilePath$
    If File
      While Eof(File) = 0
        
        ;TODO
        Protected.s Path$  = GetGadgetText(#S_Path2)
        Protected.i Id     = GetGadgetState(#S_Preset2)
        Protected.s Param$
        Protected.s Url$   = ReadString(File)
        
        ;# Check Preset and Prepare Task
        If SelectElement(Preset(), Id) And Url$
          Protected *Task.sTask = AllocateStructure(sTask)
          Param$ = MakeParam(Core::Preset()\Param$, Url$, Path$)
          With *Task
            \Url$   = Url$
            \Param$ = Param$
          EndWith
        EndIf
        
        ;# Add Task To List
        Debug *Task\Param$
        AddElement(Core::Task())
        With Core::Task()
          \Name$  = "Untitled (Quick)"
          \Url$   = *Task\Url$
          \Param$ = *Task\Param$
        EndWith
        FreeStructure(*Task)
        
        
        ;TODO
        
      Wend
    EndIf
    
    
  EndProcedure
  
  
  ;# Advanced
  Procedure Event_Advanced_Add()
    CurrentItem = -1
    ResetList(Core::Sub())
    SetGadgetText(#A_Name2, "")
    SetGadgetText(#A_Url2, "")
    SetGadgetText(#A_Path2, "")
    SetGadgetState(#A_Preset2, 0)
    UpdateGadgets(#False)
  EndProcedure
  
  Procedure Event_Advanced_Edit()
    If SelectItem()
      SetGadgetText(#A_Name2, Core::Sub()\Name$)
      SetGadgetText(#A_Url2, Core::Sub()\Url$)
      SetGadgetText(#A_Path2, Core::Sub()\Path$)
      SetGadgetState(#A_Preset2, Core::Sub()\Preset)
      UpdateGadgets(#False)
    EndIf
  EndProcedure
  
  Procedure Event_Advanced_Save()
    Protected.s Name$  = GetGadgetText(#A_Name2)
    Protected.s Url$   = GetGadgetText(#A_Url2)
    Protected.s Path$  = GetGadgetText(#A_Path2)
    Protected.i Preset = GetGadgetState(#A_Preset2)
    
    ;# Check if new or existing
    If Name$ And Url$ And Path$
      If CurrentItem <> -1
        With Core::Sub()
          \Name$  = Name$
          \Url$   = Url$
          \Path$  = Path$
          \Preset = Preset
          Debug "[Advanced] Updated Item: " + \Name$
        EndWith
      Else
        AddElement(Core::Sub())
        With Core::Sub()
          \Name$  = Name$
          \Url$   = Url$
          \Path$  = Path$
          \Preset = Preset
          Debug "[Advanced] Added Item: " + \Name$
        EndWith
      EndIf
      FillSubs()
      UpdateGadgets(#True)
    EndIf
    
  EndProcedure
  
  Procedure Event_Advanced_Remove()
    If SelectItem()
      DeleteElement(Core::Sub())
      ResetList(Core::Sub())
      SetGadgetText(#A_Name2,   "")
      SetGadgetText(#A_Url2,    "")
      SetGadgetText(#A_Path2,   "")
      SetGadgetText(#A_Path3,   "")
      SetGadgetText(#A_Preset2, "")
      CurrentItem = -1
      FillSubs()
    EndIf
  EndProcedure
  
  Procedure Event_Advanced_Path()
    Protected.s Path$ = PathRequester("Select Folder", GetGadgetText(#A_Path2))
    If Path$
      SetGadgetText(#A_Path2, Path$)
    EndIf
  EndProcedure
  
  ;# Info
  Procedure Event_Link1()
    RunProgram("www.whax.ch")
  EndProcedure
  
  Procedure Event_Link2()
    RunProgram("www.famfamfam.com/lab/icons/silk/")
  EndProcedure
  
  ;*************************************************************************
  ;- Procedure - Helpers
  ;*************************************************************************
  Procedure.i Echo(String$)
    If IsGadget(#S_Console)
      AddGadgetItem(#S_Console, -1, String$)
      SendMessage_(GadgetID(#S_Console), #EM_SETSEL, -1, -1) ;# Win API: Autoscroll
    EndIf
  EndProcedure
  
  Procedure FillPresets(Gadget.i)
    ClearGadgetItems(Gadget)
    Protected.i Icon
    ForEach Core::Preset()
      Select Core::Preset()\Type
        Case #Preset_Video
          Icon = #Ico_Video
        Case #Preset_Audio
          Icon = #Ico_Audio
        Case #Preset_Custom
          Icon = #Ico_Custom
        Default
          Icon = #Ico_Video
      EndSelect
      AddGadgetItem(Gadget, -1, Core::Preset()\Name$, ImageID(Icon))
    Next Core::Preset()
    SetGadgetState(Gadget, 0)
  EndProcedure
  
  Procedure FillSubs()
    ClearGadgetItems(#A_List)
    ForEach Core::Sub()
      AddGadgetItem(#A_List, -1, Core::Sub()\Name$)
    Next Core::Sub()
  EndProcedure
  
  Procedure.i SelectItem()
    Protected.i Item = GetGadgetState(#A_List)
    If Item <> -1
      If SelectElement(Core::Sub(), Item)
        If Core::Sub()\Name$
          CurrentItem = ListIndex(Core::Sub())
          ProcedureReturn #True
        EndIf
      EndIf
    Else
      ProcedureReturn #False
    EndIf
  EndProcedure
  
  Procedure UpdateGadgets(State.i)
    DisableGadget(#A_Name2,   State)
    DisableGadget(#A_Url2,    State)
    DisableGadget(#A_Path2,   State)
    DisableGadget(#A_Path3,   State)
    DisableGadget(#A_Preset2, State)
  EndProcedure
  
  Procedure SyncSub(Mode.i)
    
    Protected.i Pos
    Protected.i Max = CountGadgetItems(#A_List)
    Protected NewList Item.s()
    
    Select Mode
      Case 0
        ;# Selected
        For Pos = 0 To Max
          If GetGadgetItemState(#A_List, Pos) & #PB_ListIcon_Checked ;# has to be at least checked to be valid
            AddElement(Item())
            Item() = GetGadgetItemText(#A_List, Pos)
          EndIf
        Next Pos
      Case 1
        ;# All
        ForEach Core::Sub()
          AddElement(Item())
          Item() = Core::Sub()\Name$
        Next Core::Sub()
    EndSelect
    
    ;TODO: Make this neater
    ;# Prepare Tasks
    ForEach Item()
      ForEach Core::Sub()
        ;# Find Subscription
        If Core::Sub()\Name$ = Item()
          
          ;# Find Preset associated with Subscription
          If SelectElement(Core::Preset(), Core::Sub()\Preset)
            Echo("Subscription added to queue: " + Item())
            Protected *Task.sTask = AllocateStructure(sTask)
            With *Task
              \Name$   = Core::Sub()\Name$
              \Url$    = Core::Sub()\Url$
              \Param$  = MakeParam(Core::Preset()\Param$, Core::Sub()\Url$, Core::Sub()\Path$)
            EndWith
            
            ;# Add Task To List
            AddElement(Core::Task())
            With Core::Task()
              \Name$  = *Task\Name$
              \Url$   = *Task\Url$
              \Param$ = *Task\Param$
            EndWith
            
          Else
            MessageRequester("Warning", "The Preset associated the Subscription "+ Core::Sub()\Name$ + " does not exist.", #PB_MessageRequester_Error|#PB_MessageRequester_Ok)
          EndIf
        EndIf
      Next Core::Sub()
    Next Item()
    
  EndProcedure
  
  Procedure.s MakeParam(Preset$, Url$, Path$)
    Protected.s Result$
    If Right(Path$, 1) <> #PS$ : Path$ + #PS$ : EndIf ;# check path \
    Result$ = ReplaceString(Preset$, "%URL%", Url$, #PB_String_NoCase)
    Result$ = ReplaceString(Result$, "%PATH%", Path$, #PB_String_NoCase)
    ProcedureReturn Result$
  EndProcedure
  
  Procedure Clipboard()
    Protected.s Txt$ = GetClipboardText()
    If Left(Txt$, 4) = "http"
      SetGadgetText(#S_Url2, Txt$)
    EndIf
  EndProcedure
  
  ;*************************************************************************
  ;- Include
  ;*************************************************************************
  ;{
  DataSection
    
    Logo:
    IncludeBinary "data" + #PS$ + "logo.bmp"
    
    IcoVideo:
    IncludeBinary "data" + #PS$ + "ico-video.ico"
    
    IcoAudio:
    IncludeBinary "data" + #PS$ + "ico-audio.ico"
    
    IcoCustom:
    IncludeBinary "data" + #PS$ + "ico-custom.ico"
    
    IcoVideoList:
    IncludeBinary "data" + #PS$ + "ico-video-list.ico"
    
    IcoFolder:
    IncludeBinary "data" + #PS$ + "ico-folder.ico"
    
    IcoExit:
    IncludeBinary "data" + #PS$ + "ico-exit.ico"
    
    IcoRefresh1:
    IncludeBinary "data" + #PS$ + "ico-refresh1.ico"
    
    IcoRefresh2:
    IncludeBinary "data" + #PS$ + "ico-refresh2.ico"
    
    IcoSort1:
    IncludeBinary "data" + #PS$ + "ico-sort1.ico"
    
    IcoSort2:
    IncludeBinary "data" + #PS$ + "ico-sort2.ico"
    
    IcoWeb:
    IncludeBinary "data" + #PS$ + "ico-web.ico"
    
    IcoManual:
    IncludeBinary "data" + #PS$ + "ico-manual.ico"
    
    IcoInfo:
    IncludeBinary "data" + #PS$ + "ico-info.ico"
    
    IcoDownload:
    IncludeBinary "data" + #PS$ + "ico-download.ico"
    
    IcoAdd:
    IncludeBinary "data" + #PS$ + "ico-add.ico"
    
    IcoEdit:
    IncludeBinary "data" + #PS$ + "ico-edit.ico"
    
    IcoSave:
    IncludeBinary "data" + #PS$ + "ico-save.ico"
    
    IcoRemove:
    IncludeBinary "data" + #PS$ + "ico-remove.ico"
    
  EndDataSection
  ; 
  ;}
  
  DisableExplicit
  
EndModule

; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 607
; FirstLine = 384
; Folding = nAAwAAw
; Markers = 634
; EnableXP