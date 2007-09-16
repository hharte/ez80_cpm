    ; equates for mode byte bit fields

mb_input        equ 00000001b   ; device may do input
mb_output       equ 00000010b   ; device may do output
mb_in_out       equ mb_input+mb_output

mb_soft_baud        equ 00000100b   ; software selectable
                    ; baud rates

mb_serial       equ 00001000b   ; device may use protocol
mb_xon_xoff     equ 00010000b   ; XON/XOFF protocol
                    ; enabled

baud_none       equ 0       ; no baud rate associated
                    ; with this device
baud_50         equ 1       ; 50 baud
baud_75         equ 2       ; 75 baud
baud_110        equ 3       ; 110 baud
baud_134        equ 4       ; 134.5 baud
baud_150        equ 5       ; 150 baud
baud_300        equ 6       ; 300 baud
baud_600        equ 7       ; 600 baud
baud_1200       equ 8       ; 1200 baud
baud_1800       equ 9       ; 1800 baud
baud_2400       equ 10      ; 2400 baud
baud_3600       equ 11      ; 3600 baud
baud_4800       equ 12      ; 4800 baud
baud_7200       equ 13      ; 7200 baud
baud_9600       equ 14      ; 9600 baud
baud_19200      equ 15      ; 19.2k baud


