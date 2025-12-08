/// Shared DeviceType enum for compute modules
library;

enum DeviceType {
  cpu,
  gpu,
  accelerator,
  npu,              // Neural Processing Unit
  dsp,              // Digital Signal Processor
  isp,              // Image Signal Processor
  videoProcessor,   // Video encode/decode hardware
}
