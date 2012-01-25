OUTPUT_FORMAT("coff-go32")

FORCE_COMMON_ALLOCATION

SECTIONS {
  .text 0 : {
    *(.text)
    *(.data)
    *(.bss)
    *(COMMON)
  }
}
