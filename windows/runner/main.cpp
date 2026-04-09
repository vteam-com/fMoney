#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <cstdlib>
#include <string>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

/// Ensures Impeller is enabled by injecting or overriding the engine switch.
void EnsureImpellerEnabledForDesktop() {
  int switch_count = 0;
  wchar_t* switch_count_value = nullptr;
  size_t switch_count_length = 0;
  _wdupenv_s(
      &switch_count_value,
      &switch_count_length,
      L"FLUTTER_ENGINE_SWITCHES");
  if (switch_count_value != nullptr) {
    switch_count = _wtoi(switch_count_value);
    free(switch_count_value);
  }

  for (int switch_index = 1; switch_index <= switch_count; ++switch_index) {
    const std::wstring switch_key =
        L"FLUTTER_ENGINE_SWITCH_" + std::to_wstring(switch_index);
    wchar_t* switch_value = nullptr;
    size_t switch_value_length = 0;
    _wdupenv_s(&switch_value, &switch_value_length, switch_key.c_str());
    if (switch_value == nullptr) {
      continue;
    }

    const std::wstring current_switch_value = switch_value;
    free(switch_value);
    if (current_switch_value.rfind(L"enable-impeller=", 0) == 0) {
      _wputenv_s(switch_key.c_str(), L"enable-impeller=true");
      return;
    }
  }

  const int next_switch_index = switch_count + 1;
  const std::wstring next_switch_key =
      L"FLUTTER_ENGINE_SWITCH_" + std::to_wstring(next_switch_index);
  const std::wstring next_switch_count = std::to_wstring(next_switch_index);

  _wputenv_s(next_switch_key.c_str(), L"enable-impeller=true");
  _wputenv_s(L"FLUTTER_ENGINE_SWITCHES", next_switch_count.c_str());
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  EnsureImpellerEnabledForDesktop();

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"money", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
