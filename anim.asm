; BY
;-----
; Parvez Zamil
;------------------------------------------


.386
.model flat,stdcall
option casemap:none

;------------------------------------
;All the necessary libraries
;------------------------------------
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
;include \masm32\include\shell32.inc
include \masm32\include\comctl32.inc
include \masm32\include\comdlg32.inc
include \masm32\include\gdi32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
;includelib \masm32\lib\shell32.lib
includelib \masm32\lib\comctl32.lib
includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\gdi32.lib

; -----------------------------------
; INPUT red, green & blue BYTE values
; OUTPUT DWORD COLORREF value in eax
; -----------------------------------
  RGB MACRO red, green, blue
    xor eax, eax
    mov ah, blue    ; blue
    mov al, green   ; green
    rol eax, 8
    mov al, red     ; red
  ENDM

;------------------------------------
;Funtion prototype
;------------------------------------
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

Animate	equ	1

;------------------------------------
;Initialized variables
;------------------------------------

.data
ClassName	BYTE	"MainWinClass",0
AppName		BYTE	"Main Window",0
BMPfName        DB    "flyingbird.bmp",0
tempDC		DWORD	0				;Temp Device Context (only used to create compatibles for drawing)
backDC		DWORD	0				;DC for background image (to be blitted to main screen)
imageDC		DWORD	0				;DC to hold original image (background will be rotated and sized)
ourArea		RECT	<>
CornerFlag     DWORD    0

;------------------------------------
;UnInitialized variables
;------------------------------------
.data?
hInstance		HINSTANCE	?
hDesktop		DWORD		?
CommandLine		LPSTR		?
oldBackBmp		DWORD		?		;To restore displaced bmp object from backDC
oldImgBmp		DWORD		?		;To restore displaced bmp object from imageDC
DesktopX		DWORD		?
DesktopY		DWORD		?
SourceX		       DWORD		?
SourceY		       DWORD		?
LocationX		DWORD		?
LocationY		DWORD		?


.code

; ---------------------------------------------------------------------------
;Here starts the code


start:
; ---------------------------------------------------------------------------
;This sec section is almost same for every windows program.just creats main window & passes the handle to winproc
;----------------------------------------------------------------------------
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	
	invoke GetCommandLine
	mov    CommandLine,eax
	
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	;just filling up the class necessary data
;------------------------------------------------------------
	mov   wc.cbSize,SIZEOF WNDCLASSEX
	mov   wc.style, CS_HREDRAW or CS_VREDRAW
	mov   wc.lpfnWndProc, OFFSET WndProc  ; in this line handle is passed to winproc
	mov   wc.cbClsExtra,NULL
	mov   wc.cbWndExtra,NULL
	push  hInstance
	pop   wc.hInstance
	mov   wc.hbrBackground,COLOR_BTNFACE+1
	mov   wc.lpszMenuName,NULL
	mov   wc.lpszClassName,OFFSET ClassName
	
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov   wc.hIcon,eax
	mov   wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW
	mov   wc.hCursor,eax
	
	invoke RegisterClassEx, addr wc                                     ;this shows the main window
	INVOKE CreateWindowEx,WS_EX_LAYERED,ADDR ClassName,ADDR AppName,\
           WS_POPUP or WS_VISIBLE or WS_SYSMENU,CW_USEDEFAULT,\
           CW_USEDEFAULT,184,169,NULL,NULL,\
           hInst,NULL

	
	invoke ShowWindow, hwnd,SW_SHOWNORMAL
	invoke UpdateWindow, hwnd
	
	.WHILE TRUE
		invoke GetMessage, ADDR msg,NULL,0,0
		.BREAK .IF (!eax)
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
	.ENDW
	
	mov     eax,msg.wParam
	ret
WinMain endp
; ---------------------------------------------------------------------------
;This sec section is almost same for every windows program
;----------------------------------------------------------------------------



; ---------------------------------------------------------------------------
;WndProc is the function that does almost every thing
;----------------------------------------------------------------------------

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

LOCAL	ps:PAINTSTRUCT
		
	.IF uMsg==WM_TIMER                                 ; when timer is recieved it starts to animate
		.if	wParam == Animate
			
			invoke BitBlt,backDC,0,0,184,169,imageDC,SourceX,SourceY,SRCCOPY; **** most important winapi function ***
			
			;We have to adjust the source coordinates for blitting
			;the sprite sheet image to the back buffer DC (then bring it forward during WM_PAINT)
			
	;this is where the bitmap frames gets moved
;----------------------------------------------------------
			mov	eax,SourceX
			add	eax,184
			mov	SourceX,eax
			.if	eax > 735					;Sprite sheet has 5 pictures across so ..(5 * 184)
				mov	eax,1					
				mov	SourceX,eax
				mov	eax,SourceY
				add	eax,169
				mov	SourceY,eax
;				DebugOut  "greater than 408? [%u]",eax
				.if eax > 7422				;Sprite sheet has 45 pictures down, so (44 * 169)
					mov	eax,1				
					mov	SourceY,eax
				.endif
			.endif

        ;this routines makes the bird fly all over the desktop
        ;-----------------------------------------------------------           			
			invoke	MoveWindow,hWnd,LocationX,LocationY,184,169,FALSE
                        mov ecx,DesktopX
                        sub ecx,200
                        mov edx,DesktopY
                        sub edx,250
                        
                       .if LocationX <= 0 && LocationY <= 0 && CornerFlag == 0
                       mov eax,LocationY
                       add eax,20
                       mov LocationY,eax
                       .endif
                       
                         .if LocationX <= 0 && LocationY <= edx && CornerFlag == 0
                         mov eax,LocationY
                         add eax,20
                         mov LocationY,eax
                         .endif
                         
                         .if  LocationX <= 0 && LocationY >= edx && CornerFlag == 0
                         mov eax,LocationX
                         add eax,20
                         mov LocationX,eax
                         .endif
                         
                         .if  LocationX <= ecx && LocationY >= edx && CornerFlag == 0
                         mov eax,LocationX
                         add eax,20
                         mov LocationX,eax
                         .endif
                         
                         .if  LocationX >= ecx && LocationY >= edx && CornerFlag == 0
                         mov eax,1
                         mov CornerFlag,eax
                         mov eax,LocationY
                         sub eax,20
                         mov LocationY,eax
                         .endif
                         
                         .if  LocationX >= ecx && LocationY >= 0 && CornerFlag == 1
                         mov eax,LocationY
                         sub eax,20
                         mov LocationY,eax
                         .endif
                         
                         .if  LocationX >= ecx && LocationY <= 0 && CornerFlag == 1
                         mov eax,LocationX
                         sub eax,20
                         mov LocationX,eax
                         .endif
                         
                         .if  LocationX >= 0 && LocationY <= 0 && CornerFlag == 1
                         mov eax,LocationX
                         sub eax,20
                         mov LocationX,eax                       
                         .endif
                         
                         .if  LocationX <= 0 && LocationY <= 0 && CornerFlag == 1
                         mov eax,0
                         mov CornerFlag,eax
                         .endif 

        ;this routines makes the bird fly all over the desktop
        ;-----------------------------------------------------------                    
                           
                                            
                       
                                          
			invoke InvalidateRect,hWnd,0,FALSE ; when everything is set;this actually send mgs to WM_paint to PAINT ! the bitmap 
		.endif

	;this paints according to passed handle
;---------------------------------------------------	
	.ELSEIF uMsg==WM_PAINT
		invoke BeginPaint,hWnd,ADDR ps
			mov edx,ps.rcPaint.right
			sub edx,ps.rcPaint.left
			mov ecx,ps.rcPaint.bottom
			sub ecx,ps.rcPaint.top

			invoke BitBlt,ps.hdc,ps.rcPaint.left,ps.rcPaint.top,edx,ecx,backDC,ps.rcPaint.left,ps.rcPaint.top,SRCCOPY
		invoke EndPaint,hWnd,ADDR ps
	.ELSEIF uMsg==WM_LBUTTONDOWN
		invoke SendMessage, hWnd, WM_NCLBUTTONDOWN, HTCAPTION, 0 
;when the close(the red cross) is clicked evry created instances gets destroyed
;---------------------------------------------------------------------------------      
	.ELSEIF uMsg==WM_DESTROY
		
		invoke	SelectObject,backDC,oldBackBmp
		invoke	DeleteObject,eax
		invoke	DeleteDC,backDC
		invoke	SelectObject,imageDC,oldImgBmp
		invoke	DeleteObject,eax
		invoke	DeleteDC,imageDC
		invoke	KillTimer,hWnd,Animate
		invoke PostQuitMessage,NULL

;this is where every thing is created
;------------------------------------------------------
	.ELSEIF uMsg==WM_CREATE
		mov	SourceX,1
		mov	SourceY,1
		RGB	0,0,255
		invoke SetLayeredWindowAttributes,hWnd, eax, 0, LWA_COLORKEY
		
		invoke	GetClientRect,hWnd,ADDR ourArea
		RGB	0,0,255
		invoke	FillRect,hWnd,ADDR ourArea,eax

		;We're going to create 2 backbuffer DC's
		;One for drawing on and one for keeping our original image in

		invoke	GetSystemMetrics,SM_CXSCREEN
		mov DesktopX,eax
		invoke	GetSystemMetrics,SM_CYSCREEN
		mov DesktopY,eax

		
		mov	LocationX,0 ;setting start point
					
		mov	LocationY,0;setting start point
                  
		
		invoke	GetDesktopWindow           ; gets the desktop handle
		mov		hDesktop,eax
		invoke	GetDC,hDesktop
		
		mov		tempDC,eax
		
		invoke	CreateCompatibleDC,tempDC
		mov		backDC,eax
		
		invoke	GetClientRect,hWnd,ADDR ourArea
		invoke	CreateCompatibleBitmap,tempDC,ourArea.right,ourArea.bottom
		invoke	SelectObject,backDC,eax
		mov		oldBackBmp,eax
	
		invoke	CreateCompatibleDC,tempDC
		mov		imageDC,eax
		
		;Load the sprite sheet from a bmp file in same directory as program
		;----------------------------------------------------------------------
		invoke	LoadImage,  NULL,addr BMPfName,IMAGE_BITMAP,0,0,LR_LOADFROMFILE		
		
		;incase the bitmap file is not found...program exits with a warning sound(safety procedure)
		.if !eax
			invoke MessageBeep,0FFFFFFFFh;sound directive
			invoke ExitProcess,0
		.endif
		invoke	SelectObject,imageDC,eax
		mov	oldImgBmp,eax


		invoke ReleaseDC,hDesktop,tempDC

		;Copy the image from the "original" to the backbuffer DC
		;First image is at 1,1 of the original sprite sheet bitmap
		; -------------------------------------------------------------------------
		invoke BitBlt,backDC,ourArea.left,ourArea.top,184,169,imageDC,SourceX,SourceY,SRCCOPY

		;We set a timer to change the animation bitmap...
               ;so this looks like a continuous animation 
		; 20 -> 50 (milisec.) times per second. Try 10-12 to fly faster :-)
		invoke SetTimer,hWnd,Animate,50,0
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam		
		ret
	.ENDIF
	
	xor eax,eax
	ret
WndProc endp

end start
