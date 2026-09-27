# ============================================================
# soc_top.io  –  Explicit Pin Assignment for TSMC 180nm
# ============================================================
(globals
    version = 3
    io_order = default
)
(iopin
    (left
        (pin name="clk"            offset=20.0000  layer=3 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="rst_i"          space=15.0000   layer=3 width=0.2800 depth=1.0000 place_status=placed )
    )
    (right
        (pin name="uart_rx"        offset=20.0000  layer=3 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="uart_tx"        space=15.0000   layer=3 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="pwm_out"        space=15.0000   layer=3 width=0.2800 depth=1.0000 place_status=placed )
    )
    (top
        (pin name="gpio_in\[0\]"   offset=30.0000  layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_in\[1\]"   space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_in\[2\]"   space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_in\[3\]"   space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_in\[4\]"   space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_in\[5\]"   space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_in\[6\]"   space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_in\[7\]"   space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
    )
    (bottom
        (pin name="gpio_out\[0\]"  offset=30.0000  layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_out\[1\]"  space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_out\[2\]"  space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_out\[3\]"  space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_out\[4\]"  space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_out\[5\]"  space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_out\[6\]"  space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
        (pin name="gpio_out\[7\]"  space=15.0000   layer=4 width=0.2800 depth=1.0000 place_status=placed )
    )
)
