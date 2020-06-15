scen_stub = "real"

outcome_stub = "bilance"
plot_load("typ-hist")
ggsave("charts-output/twi-prijmy-typ-hist.png", width = 6, height = 4, dpi = "retina", scale = 1.5)

outcome_stub = "prijmy"
plot_load("typ-bar")
ggsave("charts-output/twi-prijmy-typ-bar.png", width = 6, height = 4, dpi = "retina", scale = 1)

outcome_stub = "bilance"
plot_load("typ-bar")
ggsave("charts-output/twi-bilance-typ-bar.png", width = 6, height = 4, dpi = "retina", scale = 1)

outcome_stub = "bilance"
plot_load("typ-bar")
ggsave("docs/metaimage.png", width = 6, height = 3, dpi = "retina", scale = 1)

outcome_stub = "rezervy"
plot_load("vel-bar-nula")
ggsave("charts-output/twi-rezervy-vel-bar.png", width = 6, height = 4, dpi = "retina", scale = 1.5)

outcome_stub = "dluh"
plot_load("typ-bar-breach")
ggsave("charts-output/twi-dluh-typ.png", width = 6, height = 4, dpi = "retina", scale = 1)

