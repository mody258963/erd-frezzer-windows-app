#include "printer_plugin.h"

#include <windows.h>
#include <winspool.h>

#include <flutter/encodable_value.h>

#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

namespace {

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return {};
  int size = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, nullptr, 0,
                                 nullptr, nullptr);
  std::string result(size - 1, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, result.data(), size,
                      nullptr, nullptr);
  return result;
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return {};
  int size = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  std::wstring result(size - 1, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, result.data(), size);
  return result;
}

std::string InferConnectionType(const std::wstring& port) {
  std::wstring upper = port;
  for (auto& c : upper) c = towupper(c);
  if (upper.find(L"USB") != std::wstring::npos) return "usb";
  if (upper.find(L"COM") != std::wstring::npos ||
      upper.find(L"BT") != std::wstring::npos ||
      upper.find(L"BLUETOOTH") != std::wstring::npos)
    return "bluetooth";
  return "windows";
}

std::map<std::string, std::string> g_connected;

flutter::EncodableMap DeviceToMap(const std::string& name,
                                  const std::string& id,
                                  const std::string& port,
                                  const std::string& status) {
  flutter::EncodableMap map;
  map[flutter::EncodableValue("printerName")] =
      flutter::EncodableValue(name);
  map[flutter::EncodableValue("printerId")] = flutter::EncodableValue(id);
  map[flutter::EncodableValue("connectionType")] =
      flutter::EncodableValue(InferConnectionType(Utf8ToWide(port)));
  map[flutter::EncodableValue("isConnected")] =
      flutter::EncodableValue(g_connected.count(id) > 0);
  map[flutter::EncodableValue("printerStatus")] =
      flutter::EncodableValue(status);
  map[flutter::EncodableValue("paperWidth")] = flutter::EncodableValue(58);
  map[flutter::EncodableValue("deviceAddress")] =
      flutter::EncodableValue(port);
  return map;
}

flutter::EncodableList DiscoverPrinters() {
  DWORD needed = 0;
  DWORD count = 0;
  EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, nullptr, 2,
               nullptr, 0, &needed, &count);
  if (needed == 0) return {};

  std::vector<BYTE> buffer(needed);
  if (!EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, nullptr, 2,
                    buffer.data(), needed, &needed, &count)) {
    return {};
  }

  auto* info = reinterpret_cast<PRINTER_INFO_2*>(buffer.data());
  flutter::EncodableList list;
  for (DWORD i = 0; i < count; ++i) {
    std::string name = WideToUtf8(info[i].pPrinterName ? info[i].pPrinterName : L"");
    std::string port = WideToUtf8(info[i].pPortName ? info[i].pPortName : L"");
    std::string status = (info[i].Status == 0) ? "ready" : "unknown";
    list.push_back(flutter::EncodableValue(DeviceToMap(name, name, port, status)));
  }
  return list;
}

bool PrintRaw(const std::string& printer_id, const std::vector<uint8_t>& data) {
  std::wstring wname = Utf8ToWide(printer_id);
  HANDLE hPrinter = nullptr;
  if (!OpenPrinter(const_cast<LPWSTR>(wname.c_str()), &hPrinter, nullptr)) {
    return false;
  }

  DOC_INFO_1 doc_info;
  doc_info.pDocName = const_cast<LPWSTR>(L"FrostParts Receipt");
  doc_info.pOutputFile = nullptr;
  doc_info.pDatatype = const_cast<LPWSTR>(L"RAW");

  if (StartDocPrinter(hPrinter, 1, reinterpret_cast<LPBYTE>(&doc_info)) == 0) {
    ClosePrinter(hPrinter);
    return false;
  }
  if (!StartPagePrinter(hPrinter)) {
    EndDocPrinter(hPrinter);
    ClosePrinter(hPrinter);
    return false;
  }

  DWORD written = 0;
  BOOL ok = WritePrinter(hPrinter, const_cast<uint8_t*>(data.data()),
                         static_cast<DWORD>(data.size()), &written);
  EndPagePrinter(hPrinter);
  EndDocPrinter(hPrinter);
  ClosePrinter(hPrinter);
  return ok == TRUE;
}

class PrinterPlugin {
 public:
  static void Register(flutter::BinaryMessenger* messenger) {
    static auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            messenger, "com.frostparts/printer",
            &flutter::StandardMethodCodec::GetInstance());

    channel->SetMethodCallHandler(
        [](const flutter::MethodCall<flutter::EncodableValue>& call,
           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
               result) {
          const auto& method = call.method_name();
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());

          if (method == "discoverPrinters") {
            result->Success(flutter::EncodableValue(DiscoverPrinters()));
            return;
          }

          if (method == "connectPrinter" && args) {
            auto id_it = args->find(flutter::EncodableValue("printerId"));
            if (id_it != args->end()) {
              auto id = std::get<std::string>(id_it->second);
              g_connected[id] = id;
              result->Success(flutter::EncodableValue(true));
              return;
            }
          }

          if (method == "disconnectPrinter" && args) {
            auto id_it = args->find(flutter::EncodableValue("printerId"));
            if (id_it != args->end()) {
              auto id = std::get<std::string>(id_it->second);
              g_connected.erase(id);
              result->Success(flutter::EncodableValue(true));
              return;
            }
          }

          if (method == "isConnected" && args) {
            auto id_it = args->find(flutter::EncodableValue("printerId"));
            if (id_it != args->end()) {
              auto id = std::get<std::string>(id_it->second);
              result->Success(
                  flutter::EncodableValue(g_connected.count(id) > 0));
              return;
            }
          }

          if (method == "getPrinterStatus" && args) {
            result->Success(flutter::EncodableValue("ready"));
            return;
          }

          if (method == "printRaw" && args) {
            auto id_it = args->find(flutter::EncodableValue("printerId"));
            auto bytes_it = args->find(flutter::EncodableValue("bytes"));
            if (id_it != args->end() && bytes_it != args->end()) {
              auto id = std::get<std::string>(id_it->second);
              auto bytes_list =
                  std::get<flutter::EncodableList>(bytes_it->second);
              std::vector<uint8_t> raw;
              raw.reserve(bytes_list.size());
              for (const auto& v : bytes_list) {
                raw.push_back(static_cast<uint8_t>(std::get<int32_t>(v)));
              }
              result->Success(
                  flutter::EncodableValue(PrintRaw(id, raw)));
              return;
            }
          }

          result->NotImplemented();
        });
  }
};

}  // namespace

void RegisterPrinterPlugin(flutter::FlutterEngine* engine) {
  PrinterPlugin::Register(engine->messenger());
}
