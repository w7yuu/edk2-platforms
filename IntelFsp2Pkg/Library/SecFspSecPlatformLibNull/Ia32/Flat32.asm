;; @file
;  This is the code that goes from real-mode to protected mode.
;  It consumes the reset vector, configures the stack.
;
; Copyright (c) 2015 - 2016, Intel Corporation. All rights reserved.<BR>
; This program and the accompanying materials
; are licensed and made available under the terms and conditions of the BSD License
; which accompanies this distribution.  The full text of the license may be found at
; http://opensource.org/licenses/bsd-license.php.
;
; THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
; WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
;;

;
; Define assembler characteristics
;
.586p
.xmm
.model flat, c

EXTRN   TempRamInitApi:NEAR

.code 

RET_ESI  MACRO

  movd    esi, mm7                      ; restore ESP from MM7
  jmp     esi

ENDM

;
; Perform early platform initialization
;
SecPlatformInit    PROC    NEAR    PUBLIC

  RET_ESI

SecPlatformInit    ENDP

;
; Protected mode portion initializes stack, configures cache, and calls C entry point
;

;----------------------------------------------------------------------------
;
; Procedure:    ProtectedModeEntryPoint
;
; Input:        Executing in 32 Bit Protected (flat) mode
;               cs: 0-4GB
;               ds: 0-4GB
;               es: 0-4GB
;               fs: 0-4GB
;               gs: 0-4GB
;               ss: 0-4GB
;
; Output:       This function never returns
;
; Destroys:
;               ecx
;               edi
;               esi
;               esp
;
; Description:
;               Perform any essential early platform initilaisation
;               Setup a stack
;
;----------------------------------------------------------------------------

ProtectedModeEntryPoint PROC NEAR C PUBLIC
  ;
  ; Dummy function. Consume 2 API to make sure they can be linked.
  ;
  mov  eax, TempRamInitApi

  ; Should never return
  jmp  $

ProtectedModeEntryPoint ENDP

;
; ROM-based Global-Descriptor Table for the PEI Phase
;
align 16
PUBLIC  BootGdtTable

;
; GDT[0]: 0x00: Null entry, never used.
;
NULL_SEL        equ     $ - GDT_BASE        ; Selector [0]
GDT_BASE:
BootGdtTable    DD      0
                DD      0
;
; Linear code segment descriptor
;
LINEAR_CODE_SEL equ     $ - GDT_BASE        ; Selector [0x8]
        DW      0FFFFh                      ; limit 0xFFFF
        DW      0                           ; base 0
        DB      0
        DB      09Bh                        ; present, ring 0, data, expand-up, not-writable
        DB      0CFh                        ; page-granular, 32-bit
        DB      0
;
; System data segment descriptor
;
SYS_DATA_SEL    equ     $ - GDT_BASE        ; Selector [0x10]
        DW      0FFFFh                      ; limit 0xFFFF
        DW      0                           ; base 0
        DB      0
        DB      093h                        ; present, ring 0, data, expand-up, not-writable
        DB      0CFh                        ; page-granular, 32-bit
        DB      0

GDT_SIZE        EQU     $ - BootGDTtable    ; Size, in bytes

;
; GDT Descriptor
;
GdtDesc:                                    ; GDT descriptor
        DW      GDT_SIZE - 1                ; GDT limit
        DD      OFFSET BootGdtTable         ; GDT base address

ProtectedModeEntryLinearAddress   LABEL   FWORD
ProtectedModeEntryLinearOffset    LABEL   DWORD
  DD      OFFSET ProtectedModeEntryPoint  ; Offset of our 32 bit code
  DW      LINEAR_CODE_SEL
  
END