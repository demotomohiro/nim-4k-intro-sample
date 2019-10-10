put "vcc.options.always", get("vcc.options.always") & " /fp:fast /arch:IA32"
--passL:user32.lib kernel32.lib winmm.lib
