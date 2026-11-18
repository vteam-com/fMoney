// ignore: fcheck_dead_code
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Browser hook called before the page unloads.
const String _beforeUnloadHandlerName = 'onbeforeunload';

/// Event method that makes the browser ask before leaving.
const String _preventDefaultMethodName = 'preventDefault';

/// Makes the browser ask for confirmation before leaving the page while [hasUnsavedChanges]
/// returns true, since edits cannot be saved from the web version.
void installPageUnloadGuard(bool Function() hasUnsavedChanges) {
  globalContext.setProperty(
    _beforeUnloadHandlerName.toJS,
    ((JSObject event) {
      if (hasUnsavedChanges()) {
        event.callMethod<JSAny?>(_preventDefaultMethodName.toJS);
      }
    }).toJS,
  );
}
