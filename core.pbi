;*************************************************************************
;- Interface -------------------------------------------------------------
;*************************************************************************
DeclareModule Core
  
  ;*************************************************************************
  ;- Structure
  ;*************************************************************************
  ;# Core
  Structure sCore
    Title$
    Version$
    BuildDate$
    DataPath$
    FileConfig$
    FilePreset$
    FileSubscription$
  EndStructure
  
  ;# File: Configuration
  Structure sConfig
    DefaultDir$
    MaxThreads.i
    WindowX.i
    WindowY.i
    WindowW.i
    WindowH.i
  EndStructure
  
  ;# File: Presets
  Structure sPreset
    Name$
    Type.i
    Param$
  EndStructure
  
  ;# File: Subscriptions
  Structure sSubscription
    Name$
    Url$
    Path$
    Site$
    Preset.i
  EndStructure
  
  ;# Thread Task
  Structure sTask
    Name$
    Url$
    Param$
  EndStructure
  
  ;*************************************************************************
  ;- Enumeration
  ;*************************************************************************
  Enumeration PresetTypes
    #Preset_Video
    #Preset_Audio
    #Preset_Custom
  EndEnumeration
  
  ;*************************************************************************
  ;- Global (+Defaults)
  ;*************************************************************************
  Global *Core.sCore     = AllocateStructure(sCore)
  Global *Config.sConfig = AllocateStructure(sConfig)
  Global NewList Preset.sPreset()
  Global NewList Sub.sSubscription()
  Global NewList Task.sTask()
  
  *Core\Title$            = "youtube-dl-front-end"
  *Core\Version$          = "0.4"
  *Core\BuildDate$        = FormatDate("%dd-%mm-%yyyy", Date())
  *Core\DataPath$         = GetUserDirectory(#PB_Directory_ProgramData) + "transgressor\youtube-dl-gui\"
  *Core\FileConfig$       = *Core\DataPath$ + "config.json"
  *Core\FilePreset$       = *Core\DataPath$ + "preset.json"
  *Core\FileSubscription$ = *Core\DataPath$ + "subscription.json"
  

  
  ;*************************************************************************
  ;- Declaration
  ;*************************************************************************
  Declare.i ConfigLoad()
  Declare.i ConfigSave()
  
  Declare.i PresetLoad()
  Declare.i PresetSave()
  
  Declare.i SubLoad()
  Declare.i SubSave()
  
EndDeclareModule

;*************************************************************************
;- Implementation --------------------------------------------------------
;*************************************************************************
Module Core
  
  EnableExplicit
  
  ;*************************************************************************
  ;- Global (+Defaults)
  ;*************************************************************************
  *Config\DefaultDir$ = GetCurrentDirectory()
  *Config\MaxThreads  = 3
  
  ;*************************************************************************
  ;- Declaration
  ;*************************************************************************
  Declare PresetDefault()
  
  ;*************************************************************************
  ;- Procedure: Config
  ;*************************************************************************
  Procedure.i ConfigLoad()
    Protected.i Config = LoadJSON(#PB_Any, *Core\FileConfig$)
    If Config
      ExtractJSONStructure(JSONValue(Config), *Config, sConfig)
      Debug "[Core:Config] JSON loaded"
      Debug "[Core:Config] DefaultDir$: " + *Config\DefaultDir$
      Debug "[Core:Config] MaxThreads: "  + *Config\MaxThreads
      ProcedureReturn #True
    Else
      Debug "[Core:Config] Init"
      CreateDirectory(GetUserDirectory(#PB_Directory_ProgramData) + "transgressor")
      CreateDirectory(GetUserDirectory(#PB_Directory_ProgramData) + "transgressor\youtube-dl-gui\")
      If ConfigSave() ;# Try init if load fails
        ProcedureReturn #True
      EndIf
    EndIf
  EndProcedure
  
  Procedure.i ConfigSave()
    Protected.i Config = CreateJSON(#PB_Any)
    If Config 
      InsertJSONStructure(JSONValue(Config), *Config, sConfig)
      If SaveJSON(Config, *Core\FileConfig$, #PB_JSON_PrettyPrint)
        Debug "[Core:Config] JSON saved"
        ProcedureReturn #True
      EndIf
    EndIf
  EndProcedure
  
  ;*************************************************************************
  ;- Procedure: Preset
  ;*************************************************************************
  Procedure.i PresetLoad()
    Protected.i Preset = LoadJSON(#PB_Any, *Core\FilePreset$)
    If Preset
      ExtractJSONList(JSONValue(Preset), Preset())
      Debug "[Core:Preset] Loaded, list size: " + ListSize(Preset())
      ProcedureReturn #True
    Else
      Debug "[Core:Preset] Init"
      PresetDefault() ;# Try init if load fails
      If PresetSave()
        ProcedureReturn #True
      EndIf
    EndIf
  EndProcedure
  
  Procedure.i PresetSave()
    Protected.i Preset = CreateJSON(#PB_Any)
    If Preset
      InsertJSONList(JSONValue(Preset), Preset())
      If SaveJSON(Preset, *Core\FilePreset$, #PB_JSON_PrettyPrint)
        Debug "[Core:Preset] JSON saved, list size: " + ListSize(Preset())
        ProcedureReturn #True
      EndIf
    EndIf
  EndProcedure
  
  Procedure PresetDefault()
    AddElement(Preset())
    Preset()\Name$  = "ANY (Best Video + Best Audio) with Archive"
    Preset()\Type   = #Preset_Video
    Preset()\Param$ = "%URL%" + " -i -o " +Chr(34)+ "%PATH%" + "%(upload_date)s %(title)s.%(ext)s" +Chr(34)
    Preset()\Param$ + " -f " +Chr(34)+ "bestvideo+bestaudio/best" +Chr(34)+ " --download-archive " +Chr(34)+ "%PATH%" +"archive.txt" +Chr(34)
    
    AddElement(Preset())
    Preset()\Name$  = "ANY (Best Video + Best Audio) without Archive"
    Preset()\Type   = #Preset_Video
    Preset()\Param$ = "%URL%" + " -i -o " +Chr(34)+ "%PATH%" + "%(upload_date)s %(title)s.%(ext)s" +Chr(34)
    Preset()\Param$ + " -f " +Chr(34)+ "bestvideo+bestaudio/best" +Chr(34)
    
    AddElement(Preset())
    Preset()\Name$  = "MP4 with Archive"
    Preset()\Type   = #Preset_Video
    Preset()\Param$ = "%URL%" + " -i -o " +Chr(34)+ "%PATH%" + "%(upload_date)s %(title)s.%(ext)s" +Chr(34)
    Preset()\Param$ + " -f " +Chr(34)+ "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" +Chr(34)+ " --download-archive " +Chr(34)+ "%PATH%" +"archive.txt" +Chr(34)
    
    AddElement(Preset())
    Preset()\Name$  = "MP4 without Archive"
    Preset()\Type   = #Preset_Video
    Preset()\Param$ = "%URL%" + " -i -o " +Chr(34)+ "%PATH%" + "%(upload_date)s %(title)s.%(ext)s" +Chr(34)
    Preset()\Param$ + " -f " +Chr(34)+ "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" +Chr(34)
    
    AddElement(Preset())
    Preset()\Name$  = "MP3 with Archive"
    Preset()\Type   = #Preset_Audio
    Preset()\Param$ = "-x --audio-format mp3 %URL% -o " +Chr(34)+ "%PATH%" + "%(upload_date)s %(title)s.%(ext)s" +Chr(34)
    Preset()\Param$ + " --download-archive " +Chr(34)+ "%PATH%" +"archive.txt" +Chr(34)
    
    AddElement(Preset())
    Preset()\Name$  = "MP3 without Archive"
    Preset()\Type   = #Preset_Audio
    Preset()\Param$ = "-x --audio-format mp3 %URL% -o " +Chr(34)+ "%PATH%" + "%(upload_date)s %(title)s.%(ext)s" +Chr(34)
    
    AddElement(Preset())
    Preset()\Name$  = "Custom Example (--help)"
    Preset()\Type   = #Preset_Custom
    Preset()\Param$ = "--help"
  EndProcedure
  
  ;*************************************************************************
  ;- Private: Procedure
  ;*************************************************************************
  Procedure.i SubLoad()
    Protected.i Sub = LoadJSON(#PB_Any, *Core\FileSubscription$)
    If Sub
      ExtractJSONList(JSONValue(Sub), Sub())
      Debug "[Core:Sub] Loaded, list size: " + ListSize(Sub())
      ;# TEST
      ForEach Sub()
        If Sub()\Site$ = ""
          Sub()\Site$ = LCase(StringField(Sub()\Url$, 2, "."))
        EndIf
      Next Sub()
      ;# END TEST
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure.i SubSave()
    Protected.i Sub = CreateJSON(#PB_Any)
    If Sub
      InsertJSONList(JSONValue(Sub), Sub())
      If SaveJSON(Sub, *Core\FileSubscription$, #PB_JSON_PrettyPrint)
        Debug "[Core:Sub] JSON saved, list size: " + ListSize(Sub())
        ProcedureReturn #True
      EndIf
    EndIf
  EndProcedure
  
  DisableExplicit
  
EndModule
; IDE Options = PureBasic 5.72 (Windows - x64)
; Folding = D5
; EnableXP