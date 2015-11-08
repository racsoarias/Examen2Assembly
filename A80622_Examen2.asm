;Autor: Oscar Arias Mora A80622 - Examen 2 - 7/NOV/15

%define NULL 0
%define FILE_ATTRIBUTE_NORMAL 128
%define FILE_READ_DATA 1
%define FILE_SHARE_READ 1
%define FILE_WRITE_DATA 2
%define OPEN_ALWAYS 4
%define OPEN_EXISTING 3
%define CREATE_ALWAYS 2 

%define TAMANO_BUFFER 54
%define TAMANO_BUFFER1 1
%define TAMANO_BUFFER2 2
%define TAMANO_BUFFER3 3
%define PIXEL 2 ; Indica la capa que desea eliminar, valores posibles 0-Azul 1-Verde 2-Rojo

extern _printf
extern _CreateFileA@28
extern _ReadFile@20
extern _WriteFile@20
extern _ExitProcess@4
extern _CloseHandle@4

%macro leer 3
    push dword NULL
    push bytesLeidos
    push %1
    push %2
    push %3 
    call _ReadFile@20
%endmacro 
%macro escribir 3
    push dword NULL
    push bytesLeidos
    push %1
    push %2
    push %3 
    call _WriteFile@20
%endmacro 

section .data  
    input: db "D:\Google Drive\UCR\Examen2\48x48.bmp",NULL  ;<-- Cambia según computadora local
    output: db "D:\Google Drive\UCR\Examen2\1_New.bmp",NULL  ;<-- Cambia según computadora local
section .bss
    handleR: resd 1 ; Espacio para almacenar la referencia a la estructura que retorna la función CreateFile con permiso de lectura
    handleW: resd 1 ; Espacio para almacenar la referencia a la estructura que retorna la función CreateFile con permiso de escritura
    buffer: resb TAMANO_BUFFER
    buffer1: resb TAMANO_BUFFER1
    buffer2: resb TAMANO_BUFFER2
    buffer3: resb TAMANO_BUFFER3
    datos: resb 500; Espacio para cargar los tamaños de los datos.
    bytesLeidos: resd 1 ; Cantidad de bytes leídos
    count: resb 4
    ancho: resb 4
    caso: resb 4
section .text
    global _main
    
 _main:
    mov ebp, esp; for correct debugging
    
    push dword NULL                        ;0
    push dword FILE_ATTRIBUTE_NORMAL       ;128
    push dword OPEN_EXISTING               ;3
    push dword NULL                        ;0
    push dword 2                           ;2
    push dword FILE_READ_DATA              ;1
    push input 
    call _CreateFileA@28
    ; En este punto, en el EAX esta el HANDLE que retorna la función.
    mov dword [handleR], eax     

    push dword NULL                         ;0
    push dword FILE_ATTRIBUTE_NORMAL        ;128
    push dword CREATE_ALWAYS                ;2
    push dword NULL                         ;0
    push dword FILE_SHARE_READ              ;1
    push dword FILE_WRITE_DATA              ;2
    push output 
    call _CreateFileA@28
    ; En este punto, en el EAX esta el HANDLE que retorna la función.
    mov dword [handleW], eax
                
    ; Ahora se hace la lectura del archivo, utilizando la función ReadFile.
    leer dword TAMANO_BUFFER, buffer, dword [handleR] 
       
    ; Ahora se hace la escritura del archivo, utilizando la función ReadFile.
    escribir dword TAMANO_BUFFER, buffer,dword [handleW] 
       
    ;Hasta aquí el programa ha leido el header el archivo y ha creado una
    ;copia de esta informacion, son 54 bytes
    
    mov eax, dword [buffer + 18] ;ancho
    mov ebx, dword [buffer + 22] ;alto
    mov dword [ancho], eax
    mul ebx ; total de pixels
    mov ecx, eax
    mov esi, [ancho]
    
    xor edx, edx
    mov eax, dword [ancho]
    mov ebx, 4
    div ebx
    ;en eax tengo el resultado y en edx el residuo 
    mov dword [caso], edx
    
    ciclo:
        push ecx
        leer dword TAMANO_BUFFER3, buffer3, dword [handleR]
        mov byte[buffer3 + PIXEL], 0  ;ponen en cero el byte del elemento RGB seleccionado       
        escribir dword TAMANO_BUFFER3, buffer3, dword [handleW]
        pop ecx   
        dec esi
        cmp esi, 0        
        je detAncho          
    loop ciclo
    
    detAncho:
    ;Aquí se escoge el caso según la cantidad de bytes que hay que agregar al final de cada línea
        cmp dword [caso], 0
        je ancho0
        cmp dword [caso], 1
        je ancho1
        cmp dword [caso], 2
        je ancho2
        cmp dword [caso], 3
        je ancho3
        
    ancho0:
        dec ecx
        mov esi, [ancho]
        cmp ecx, 0
        je fin
    jmp ciclo
    
    ancho1:
        dec ecx
        mov edi, ecx
        mov esi, [ancho]
        leer dword TAMANO_BUFFER1,buffer1,dword [handleR]
        escribir dword TAMANO_BUFFER1, buffer1,dword [handleW]
        mov ecx, edi
        cmp ecx, 0
        je fin
    jmp ciclo
  
    
    ancho2:
        dec ecx
        mov edi, ecx
        mov esi, [ancho]
        leer dword TAMANO_BUFFER2, buffer2, dword [handleR]
        escribir dword TAMANO_BUFFER2, buffer2, dword [handleW]
        mov ecx, edi
        cmp ecx, 0
        je fin
    jmp ciclo
    
    ancho3:
        dec ecx
        mov edi, ecx
        mov esi, [ancho]
        leer dword TAMANO_BUFFER3, buffer3, dword [handleR]
        escribir dword TAMANO_BUFFER3, buffer3, dword [handleW]
        mov ecx, edi
        cmp ecx, 0
        je fin
    jmp ciclo
    
    fin:
    push handleR
    call _CloseHandle@4
    push handleW
    call _CloseHandle@4
    
  ; Sale del programa:
   push dword 0
   call _ExitProcess@4
 ret