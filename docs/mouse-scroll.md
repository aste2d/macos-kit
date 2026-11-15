# 鼠标与触控板

整合包在 Karabiner-Elements 16.3.0 中自动启用新接入的非 Apple 鼠标，并反转垂直滚轮。Apple 鼠标和 Mac 内置触控板沿用 macOS 的滚动方向。想让触控板使用自然滚动，可在系统设置的触控板页面打开「自然滚动」。[Karabiner 设备设置](https://karabiner-elements.pqrs.org/docs/manual/configuration/configure-devices/)

## 第三方触控板例外

整合包按厂商 ID 和产品 ID 识别下列设备。表中的 ID 使用十六进制。

| 触控板 | 厂商 ID | 产品 ID | 设备标识来源 |
|---|---|---|---|
| Logitech Casa Touch / Pop-Up Touch for Business | `046D` | `BB00` / `BB01` | [OpenLogi 设备表](https://openlogi.org/docs/supported-devices) |
| Logitech Rechargeable Trackpad T651 | `046D` | `B00C` | [Logitech 产品规格](https://support.logi.com/hc/en-sg/articles/360023466673-Logitech-Rechargeable-Trackpad-T651-Technical-Specifications)、[Linux HID 设备表](https://github.com/torvalds/linux/blob/master/drivers/hid/hid-ids.h) |
| Logitech Touchpad T650 | `046D` | `4101` | [Linux HID++ 设备表](https://github.com/torvalds/linux/blob/master/drivers/hid/hid-logitech-hidpp.c) |
| Cirque USB GlidePoint | `0488` | `0020` / `0022` | [Cirque 产品支持](https://www.cirque.com/desktop-trackpad-support-faq/)、[设备记录 0020](https://bbs.archlinux.org/viewtopic.php?id=52279)、[设备记录 0022](https://www.spinics.net/lists/xorg/msg55213.html) |
| Perixx PERIPAD-501 II | `1DDD` | `2819` | [Perixx 产品页](https://perixx.com/collections/numpads-touchpads/products/peripad-501)、[设备记录](https://github.com/raspberrypi/firmware/issues/1416) |

## 其他触控板

如果触控板仍然反向滚动，在 **Karabiner-Elements → Devices** 找到相应设备，关闭 **Modify events**。可在 **Karabiner-EventViewer → Devices** 查看设备 ID。对于 T650 等使用共享接收器的型号，请先检查系统显示的是触控板自己的 ID 还是接收器的 ID。关闭共享接收器的 **Modify events** 也会影响通过它连接的鼠标。[Karabiner 设备匹配说明](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/device/)

如果只导入独立规则文件，可在 **Devices** 中为要反转的鼠标打开 **Modify events**。设备自带的垂直反转开关设为关闭，即可由这条规则统一处理。
