-- Monitor layout — matched by description (serial), NOT port: DP-x renumbers on reconnect.
-- ASUS PA279 (secondary, left),       4K@60,  scale 2
-- Samsung Odyssey G81SF (main, right), 4K@240, scale 1.5
hl.monitor({ output = "desc:ASUSTek COMPUTER INC ASUS PA279 0x00027393",            mode = "3840x2160@60",  position = "0x0",    scale = 2   })
hl.monitor({ output = "desc:Samsung Electric Company Odyssey G81SF HNBY800179", mode = "3840x2160@240", position = "1920x0", scale = 1.5 })
