# ruby8_forth
Ruby8 virtual machine with Forth

It occured to me during my work on the HyForth (https://github.com/burntcouch/hy_millif) project that I could really use an 8-bit emulator on a faster machine to better get my head around some of the trickier 'native code' implementations of Forth words, in particular the core conditional and loop structures.  I plan on porting HyForth to AVR and some of the RISC-V SoC's in any case, so I am going to need a lot of practice and building Forth up from scratch, so....

Ruby 'gets out of the way' pretty quickly once the VM is set up.  This is a flat 8-bit data/16-bit address machine with no built-in registers or stacks as such, and a minimum of address modes for load and store operations.  Stacks can be defined in software and use the push/pull operations.  Labels, stacks and code can be 'registered' so that a direct or indirect jump to a registered 'code' address will run a block of Ruby code.

As far as Forth goes...an arbitrary # of stacks can be defined, both 8-bit and 16-bit wide, so the TIB, PSP and RTP are easily established and can all use the push/pull instructions for access, as well as a different set of instructions to access them as arrays....
