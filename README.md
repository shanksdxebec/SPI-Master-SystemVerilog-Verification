# SPI-Master-SystemVerilog-Verification
This project implements spi master controller working in mode 0 with self checking and with testbench using system verilog
# Key features
* Design (spi_master.sv)
  * 3-State Finite State Machine= 'IDLE', 'TRANSFER', 'DONE'.
  * Configurable clock divider generating a synchronous serial clock (sclk).
  * Full-duplex 8-bit serial data transmission (mosi) and reception (sclk).
  * Race-free SPI Mode 0 timing (samples on rising edge, shifts on falling edge).
* SystemVerilog Testbench (spi_tb.sv)
  * **Interface & Virtual Interface:** Encapsulates DUT-TB signal connectivity.
  * **Transaction & Randomization:** OOP transaction class generating randomized 8-bit payloads.
  * **Driver & BFM:** Drives randomized stimulus and models a single-slave loopback device.
  * **Monitor & Scoreboard:** Passively captures bus transactions via `fork...join_none and performs automated self-checking with  Pass/Fail reporting.
* Tools Used
  * Language:SystemVerilog / Verilog (IEEE 1800)
  * Simulator: Verilator 5.044('--binary --timing --trace')
  * Waveform Viewer: EPWave
