import QtQuick 2.0

QtObject {
    property string primary: "{{colors.primary.default.hex}}"
    property string on_primary: "{{colors.on_primary.default.hex}}"
    property string secondary: "{{colors.secondary.default.hex}}"
    property string on_secondary: "{{colors.on_secondary.default.hex}}"
    property string background: "{{colors.surface.default.hex}}"
    property string on_background: "{{colors.on_surface.default.hex}}"
    property string surface: "{{colors.surface_container.default.hex}}"
    property string on_surface: "{{colors.on_surface_variant.default.hex}}"
}