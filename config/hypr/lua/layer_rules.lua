-- Layer rules (from conf/ml4w.conf, conf/decorations/default.conf)

-- SwayNC
hl.layer_rule({ name = "swaync-cc-blur",  match = { namespace = "swaync-control-center"     }, blur = true })
hl.layer_rule({ name = "swaync-nw-blur",  match = { namespace = "swaync-notification-window"}, blur = true })
hl.layer_rule({ name = "swaync-cc-ia",    match = { namespace = "swaync-control-center"     }, ignore_alpha = 0.5 })
hl.layer_rule({ name = "swaync-nw-ia",    match = { namespace = "swaync-notification-window"}, ignore_alpha = 0.5 })

-- Waybar (harmless leftover; bar in use is HyprPanel)
hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true })
