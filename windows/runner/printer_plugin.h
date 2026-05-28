#ifndef RUNNER_PRINTER_PLUGIN_H_
#define RUNNER_PRINTER_PLUGIN_H_

#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

void RegisterPrinterPlugin(flutter::FlutterEngine* engine);

#endif  // RUNNER_PRINTER_PLUGIN_H_
