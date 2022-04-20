; Windows Application                   (WinApp.asm)

; This program displays a resizable application window and
; several popup message boxes.
; Thanks to Tom Joyce for creating a prototype
; from which this program was derived.

INCLUDE Irvine32.inc
INCLUDE GraphWin.inc

;==================== DATA =======================
.data

AppLoadMsgTitle BYTE "Application Loaded",0
AppLoadMsgText  BYTE "This window displays when the WM_CREATE "
	            BYTE "message is received",0

PopupTitle BYTE "Popup Window",0
;PopupText  BYTE "This window was activated by a "
;	       BYTE "WM_LBUTTONDOWN message",0
PopupText BYTE "This window was activated by a BUTTON down message at x="
PopupTextXPos=$-PopupText
popupx    BYTE 4 DUP(? )
            BYTE 0
PopupTextSize=$-PopupText


GreetTitle BYTE "Main Window Active",0
GreetText  BYTE "This window is shown immediately after "
	       BYTE "CreateWindow and UpdateWindow are called.",0

CloseMsg   BYTE "WM_CLOSE message received",0

ErrorTitle  BYTE "Error",0
WindowName  BYTE "ASM Windows App",0
className   BYTE "ASMWin",0

; Heap Data
hProcHeap HANDLE ?
pBuffer DWORD ?   ; pointer to buffer

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>
hMainWnd  DWORD ?
hInstance DWORD ?

;=================== CODE =========================
.code
WinMain PROC
; Get a handle to the current process.
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	mov MainWin.hInstance, eax

; Load the program's icon and cursor.
	INVOKE LoadIcon, NULL, IDI_APPLICATION
	mov MainWin.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov MainWin.hCursor, eax

; Register the window class.
	INVOKE RegisterClass, ADDR MainWin
	.IF eax == 0
	  call ErrorHandler
	  jmp Exit_Program
	.ENDIF

; Create the application's main window.
; Returns a handle to the main window in EAX.
	INVOKE CreateWindowEx, 0, ADDR className,
	  ADDR WindowName,MAIN_WINDOW_STYLE,
	  CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
	  CW_USEDEFAULT,NULL,NULL,hInstance,NULL
	mov hMainWnd,eax

; If CreateWindowEx failed, display a message & exit.
	.IF eax == 0
	  call ErrorHandler
	  jmp  Exit_Program
	.ENDIF

; Show and draw the window.
	INVOKE ShowWindow, hMainWnd, SW_SHOW
	INVOKE UpdateWindow, hMainWnd

; Display a greeting message.
	INVOKE MessageBox, hMainWnd, ADDR GreetText,
	  ADDR GreetTitle, MB_OK

	INVOKE GetProcessHeap
.IF eax == NULL   ; cannot get handle
 call WriteWindowsMsg 
 ; jmp ... exit
.ELSE
  mov hProcHeap,eax   ; handle is OK
.ENDIF

; Begin the program's message-handling loop.
Message_Loop:
	; Get next message from the queue.
	INVOKE GetMessage, ADDR msg, NULL,NULL,NULL

	; Quit if no more messages.
	.IF eax == 0
	  jmp Exit_Program
	.ENDIF

	; Relay the message to the program's WinProc.
	INVOKE DispatchMessage, ADDR msg
    jmp Message_Loop

Exit_Program:
	  INVOKE ExitProcess,0
WinMain ENDP

;-----------------------------------------------------
WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's message handler, which handles
; application-specific messages. All other messages
; are forwarded to the default Windows message
; handler.
;-----------------------------------------------------
	mov eax, localMsg

	.IF eax == WM_LBUTTONDOWN		; mouse button?
	  pushad

	  ; heap allocation
	  INVOKE HeapAlloc, hProcHeap, HEAP_ZERO_MEMORY, PopupTextSize
	.IF eax == NULL
	  call WriteWindowsMsg
	  ; jmp .... exit
	.ELSE
	  mov pBuffer,eax
	.ENDIF

	mov ecx, PopupTextSize
	mov esi, OFFSET PopupText
	mov edi, pBuffer
	rep movsb

	  mov eax, lParam
	  
	  mov ecx, 4 ; use 4 to get all nums
	  mov ebx, 10
	  
	  loopx: 
	    
	    div bx
		xor dx, 30h
	    ;mov popupx[ecx-1], dl ; fits in 1 byte
		mov esi, pBuffer
		;add esi, PopupTextXPos
		;mov dx, 0
	    ;mov [esi+ecx-1+2], dl
		add esi, ecx
		;add esi, pBuffer
		mov [popupx - PopupText + esi - 1], dl
		mov dx, 0
		loop loopx
	  popad ; save regiters

	    


	  INVOKE MessageBox, hWnd, pbuffer, ;ADDR PopupText,
	    ADDR PopupTitle, MB_OK
	  
	  ; free the heap
		INVOKE HeapFree,
	  hProcHeap,   ; handle to heap
	  0,   ; flags
	  pBuffer
	  jmp WinProcExit
	.ELSEIF eax == WM_CREATE		; create window?
	  INVOKE MessageBox, hWnd, ADDR AppLoadMsgText,
	    ADDR AppLoadMsgTitle, MB_OK
	  jmp WinProcExit
	.ELSEIF eax == WM_CLOSE		; close window?
	  INVOKE MessageBox, hWnd, ADDR CloseMsg,
	    ADDR WindowName, MB_OK
	  INVOKE PostQuitMessage,0
	  jmp WinProcExit
	.ELSE		; other message?
	  INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
	  jmp WinProcExit
	.ENDIF

WinProcExit:
	ret
WinProc ENDP

;---------------------------------------------------
ErrorHandler PROC
; Display the appropriate system error message.
;---------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP

END WinMain